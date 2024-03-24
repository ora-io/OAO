// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IOpml.sol";
import "./interfaces/IAIOracle.sol";

contract AIOracle is IAIOracle {

    address constant public server = 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD;
    bytes4 constant public callbackFunctionSelector = 0xb0347814;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyServer() {
        require(msg.sender == server, "Only server");
        _;
    }

    // avoid calling special callback contracts
    mapping(address => bool) public blacklist;

    struct AICallbackRequestData{
        address account;
        uint256 requestId;
        uint256 modelId;
        bytes input;
        address callbackContract;
        uint64 gasLimit;
        bytes callbackData;
    }

    mapping(uint256 => AICallbackRequestData) public requests;
    mapping(uint256 => bytes) public outputOfRequest;

    struct ModelData {
        bytes32 modelHash;
        bytes32 programHash;
        uint256 fee;
        address receiver;
        uint256 receiverPercentage;
        uint256 accumulateRevenue;
    }

    mapping (uint256 => ModelData) models;
    mapping (uint256 => bool) modelExists;

    uint256 public gasPrice;
    uint256[] public modelIDs;
    IOpml public opml;
    address public owner;

    function transferOwnership(address newOwner) public {
        if(owner == address(0)) {
            require(msg.sender == server, "only server can init owner");
        } else {
            require(msg.sender == owner, "Not the owner");
        }
        owner = newOwner;
    }

    function addToBlacklist(address _address) external onlyOwner {
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        blacklist[_address] = false;
    }

    modifier notBlacklisted(address callbackContract) {
        require(!blacklist[callbackContract], "In blacklist");
        _;
    }

    modifier ifModelExists(uint256 modelId) {
        require(modelExists[modelId], "model does not exist");
        _;
    }

    // set the gasPrice = 0 initially
    function resetGasPrice() external onlyOwner {
        gasPrice = 0;
    }

    // reset modelIDs initially
    function resetModelIDs() external onlyOwner {
        delete modelIDs;
    }

    function numberOfModels() external view returns (uint256) {
        return modelIDs.length;
    }

    // remove the model from OAO, so OAO would not serve the model 
    function removeModel(uint256 modelId) external onlyOwner ifModelExists(modelId) {
        // claim the corresponding revenue first
        ModelData storage model = models[modelId];
        if (model.accumulateRevenue > 0) {
            uint256 transferRevenue = model.accumulateRevenue;
            model.accumulateRevenue = 0;
            (bool success, ) = (model.receiver).call{value: transferRevenue}("");
            require(success, "claimModelRevenue transfer failed");            
        }
        // remove model
        modelExists[modelId] = false;
        // remove from modelIDs
        for (uint i = 0; i < modelIDs.length; i++) {
            uint256 id = modelIDs[i];
            if (id == modelId) {
                // Replace the element at index with the last element
                modelIDs[i] = modelIDs[modelIDs.length - 1];
                // Remove the last element by reducing the array's length
                modelIDs.pop();
                break;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 modelRevenue;
        for (uint i = 0; i < modelIDs.length; i++) {
            uint256 id = modelIDs[i];
            ModelData memory model = models[id];
            modelRevenue += model.accumulateRevenue;
        }
        uint256 ownerRevenue = address(this).balance - modelRevenue;
        (bool success, ) = (msg.sender).call{value: ownerRevenue}("");
        require(success, "withdraw failed");
    }

    function setOpml(address newOpml) external onlyOwner {
        opml = IOpml(newOpml);
    }

    function setModelFee(uint256 modelId, uint256 _fee) external onlyOwner ifModelExists(modelId) {
        ModelData storage model = models[modelId];
        model.fee = _fee;
    }

    function setModelReceiver(uint256 modelId, address receiver) external onlyOwner ifModelExists(modelId) {
        ModelData storage model = models[modelId];
        model.receiver = receiver;
    }

    function setModelReceiverPercentage(uint256 modelId, uint256 receiverPercentage) external onlyOwner ifModelExists(modelId) {
        require(receiverPercentage <= 100, "percentage should be <= 100");
        ModelData storage model = models[modelId];
        model.receiverPercentage = receiverPercentage;
    }

    function getModel(uint256 modelId) external view ifModelExists(modelId) returns (ModelData memory) {
        ModelData memory model = models[modelId];
        return model;
    }

    function estimateFee(uint256 modelId, uint256 gasLimit) public view ifModelExists(modelId) returns (uint256) {
        ModelData storage model = models[modelId];
        return model.fee + gasPrice * gasLimit;
    }

    function uploadModel(uint256 modelId, bytes32 modelHash, bytes32 programHash, uint256 fee, address receiver, uint256 receiverPercentage) external onlyOwner {
        require(!modelExists[modelId], "model already exists");
        require(receiverPercentage <= 100, "percentage should be <= 100");
        modelExists[modelId] = true;
        modelIDs.push(modelId);
        ModelData storage model = models[modelId];
        model.modelHash = modelHash;
        model.programHash = programHash;
        model.fee = fee;
        model.receiver = receiver;
        model.receiverPercentage = receiverPercentage;
        opml.uploadModel(modelHash, programHash);
    }

    function updateModel(uint256 modelId, bytes32 modelHash, bytes32 programHash, uint256 fee, address receiver, uint256 receiverPercentage) external onlyOwner ifModelExists(modelId) {
        require(receiverPercentage <= 100, "percentage should be <= 100");
        ModelData storage model = models[modelId];
        model.modelHash = modelHash;
        model.programHash = programHash;
        model.fee = fee;
        model.receiver = receiver;
        model.receiverPercentage = receiverPercentage;
        opml.uploadModel(modelHash, programHash);
    }
    
    function isFinalized(uint256 requestId) external view returns (bool) {
        return opml.isFinalized(requestId);
    }

    // view function
    function _validateParams(
        uint256 modelId,
        bytes memory input, 
        address callbackContract, 
        uint64 gasLimit
    ) internal ifModelExists(modelId) notBlacklisted(callbackContract) {
        ModelData storage model = models[modelId];
        require(msg.value >= model.fee + gasPrice * gasLimit, "insufficient fee");
        model.accumulateRevenue += model.fee * model.receiverPercentage / 100;
        require(input.length > 0, "input not uploaded");
        bool noCallback = callbackContract == address(0);
        require(noCallback == (gasLimit == 0), "Invalid gasLimit");
    }

    function requestCallback(
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory callbackData
    ) external payable returns (uint256) {
        // validate params
        _validateParams(modelId, input, callbackContract, gasLimit);

        ModelData memory model = models[modelId];

        // init opml request
        uint256 requestId = opml.initOpmlRequest(model.modelHash, model.programHash, input);

        // store the request so that anyone can update the result according to the opml
        AICallbackRequestData storage request = requests[requestId];
        request.account = msg.sender;
        request.requestId = requestId;
        request.modelId = modelId;
        request.input = input;
        request.callbackContract = callbackContract;
        request.gasLimit = gasLimit;
        request.callbackData = callbackData;

        // Emit event
        emit AICallbackRequest(request.account, requestId, modelId, input, callbackContract, gasLimit, callbackData);

        return requestId;
    }

    // any can call this function
    function claimModelRevenue(uint256 modelId) external ifModelExists(modelId) {
        ModelData storage model = models[modelId];
        require(model.accumulateRevenue > 0, "accumulate revenue is 0");
        uint256 transferRevenue = model.accumulateRevenue;
        model.accumulateRevenue = 0;
        (bool success, ) = (model.receiver).call{value: transferRevenue}("");
        require(success, "claimModelRevenue transfer failed");
    }

    function getOutput(uint256 requestId) external view returns (bytes memory output) {
        return opml.getOutput(requestId);
    }

    // call this function if the opml result is challenged and updated!
    // anyone can call it!
    function updateResult(uint256 requestId) external {
        // read request of requestId
        AICallbackRequestData storage request = requests[requestId];

        // get Latest output of request
        bytes memory output = opml.getOutput(requestId);
        require(output.length > 0, "output not uploaded");

        // invoke callback
        if(request.callbackContract != address(0)) {
            bytes memory payload = abi.encodeWithSelector(callbackFunctionSelector, request.requestId, output, request.callbackData);
            (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
            require(success, "failed to call selector");
            if (!success) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
        }

        emit AICallbackResult(request.account, requestId, msg.sender, output);
    }

    // payload includes (function selector, input, output)
    function invokeCallback(uint256 requestId, bytes calldata output) external onlyServer {
        // read request of requestId
        AICallbackRequestData storage request = requests[requestId];
        
        // others can challenge if the result is incorrect!
        opml.uploadResult(requestId, output);

        // invoke callback
        if(request.callbackContract != address(0)) {
            bytes memory payload = abi.encodeWithSelector(callbackFunctionSelector, request.requestId, output, request.callbackData);
            (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
            require(success, "failed to call selector");
            if (!success) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
        }

        emit AICallbackResult(request.account, requestId, msg.sender, output);

        gasPrice = tx.gasprice;
    }
}
