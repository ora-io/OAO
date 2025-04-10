// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IOpml.sol";
import "./interfaces/IAIOracle.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AIOracle is IAIOracle {
    using SafeERC20 for IERC20;
    address constant public server = 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD;
    bytes4 constant public callbackFunctionSelector = 0xb0347814;
    bytes4 constant public errorFunctionSelector = 0x8e6fd006;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
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
        address token;
        bool unverifiable;
    }

    mapping (uint256 => ModelData) models;
    mapping (uint256 => bool) modelExists;

    uint256 public gasPrice;
    uint256[] public modelIDs;
    IOpml public opml;
    address public owner;

    mapping(address => bool) public whitelist;
    address public financialAdmin;

    modifier onlyFinancialAdmin() {
        require(msg.sender == financialAdmin, "Not the financial admin");
        _;
    }

    function setFinancialAdmin(address _admin) external onlyOwner {
        require(financialAdmin != _admin, "The new admin address must be different from the old address.");
        require(_admin != address(0), "Invalid address");
        financialAdmin = _admin;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address not whitelisted");
        _;
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

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
            if (model.token == address(0)) {
                (bool success, ) = (model.receiver).call{value: transferRevenue}("");
                require(success, "claimModelRevenue transfer failed");            
            } else {
                IERC20(model.token).safeTransfer(model.receiver, transferRevenue);
            }
        }
            
        // remove model
        modelExists[modelId] = false;
        // remove from modelIDs
        for (uint i = 0; i < modelIDs.length;) {
            uint256 id = modelIDs[i];
            if (id == modelId) {
                // Replace the element at index with the last element
                modelIDs[i] = modelIDs[modelIDs.length - 1];
                // Remove the last element by reducing the array's length
                modelIDs.pop();
                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    function withdraw(address token) external onlyFinancialAdmin {
        if (token == address(0)) {
            uint256 modelRevenue;
            for (uint i = 0; i < modelIDs.length;) {
                uint256 id = modelIDs[i];
                ModelData memory model = models[id];
                if (model.token == address(0)) {
                    modelRevenue += model.accumulateRevenue;
                }
                unchecked {
                    ++i;
                }
            }
            uint256 ownerRevenue = address(this).balance - modelRevenue;
            (bool success, ) = (msg.sender).call{value: ownerRevenue}("");
            require(success, "withdraw failed");  
        } else {
            uint256 ownerRevenueOfToken = IERC20(token).balanceOf(address(this));
            for (uint i = 0; i < modelIDs.length;) {
                uint256 id = modelIDs[i];
                ModelData memory model = models[id];
                if (model.token == token) {
                    ownerRevenueOfToken -= model.accumulateRevenue;
                }
                unchecked {
                    ++i;
                }
            }
            IERC20(token).safeTransfer(msg.sender, ownerRevenueOfToken);
        }
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

    function getModel(uint256 modelId) external view ifModelExists(modelId) returns (
        bytes32 modelHash,
        bytes32 programHash,
        uint256 fee,
        address receiver,
        uint256 receiverPercentage,
        uint256 accumulateRevenue,
        address token,
        bool unverifiable
    ) {
        return (
            models[modelId].modelHash,
            models[modelId].programHash,
            models[modelId].fee,
            models[modelId].receiver,
            models[modelId].receiverPercentage,
            models[modelId].accumulateRevenue,
            models[modelId].token,
            models[modelId].unverifiable
        );
    }

    function estimateFee(uint256 modelId, uint256 gasLimit) public view ifModelExists(modelId) returns (uint256) {
        ModelData storage model = models[modelId];
        if(model.token == address(0)){
            return model.fee + gasPrice * gasLimit;
        } else {
            return gasPrice * gasLimit;
        }
    }

    function estimateFeeBatch(uint256 modelId, uint256 gasLimit, uint256 batchSize) public view ifModelExists(modelId) returns (uint256) {
        ModelData storage model = models[modelId];
        if (model.token == address(0)) {
            return batchSize * model.fee + gasPrice * gasLimit;
        } else {
            return gasPrice * gasLimit;
        }
    }

    function uploadModel(uint256 modelId, bytes32 modelHash, bytes32 programHash, uint256 fee, address receiver, uint256 receiverPercentage, address token, bool unverifiable) external onlyOwner {
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
        model.token = token;
        model.unverifiable = unverifiable;
        opml.uploadModel(modelHash, programHash);
    }

    function updateModel(uint256 modelId, bytes32 modelHash, bytes32 programHash, uint256 fee, address receiver, uint256 receiverPercentage, address token, bool unverifiable) external onlyOwner ifModelExists(modelId) {
        require(receiverPercentage <= 100, "percentage should be <= 100");
        ModelData storage model = models[modelId];
        model.modelHash = modelHash;
        model.programHash = programHash;
        model.fee = fee;
        model.receiver = receiver;
        model.receiverPercentage = receiverPercentage;
        model.token = token;
        model.unverifiable = unverifiable;
        opml.uploadModel(modelHash, programHash);
    }
    
    function isFinalized(uint256 requestId) external view returns (bool) {
        return opml.isFinalized(requestId);
    }

    // AIOracle should validate all parameters from request
    function _validateParams(
        uint256 batchSize,
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory /* callbackData */,
        DA inputDA,
        DA /* outputDA */
    ) internal ifModelExists(modelId) notBlacklisted(callbackContract) {
        ModelData storage model = models[modelId];
        if(model.token == address(0)){
            require(msg.value >= batchSize * model.fee + gasPrice * gasLimit, "insufficient fee");
        } else {
            require(msg.value >= gasPrice * gasLimit, "insufficient fee");
            IERC20(model.token).safeTransferFrom(msg.sender, address(this), batchSize * model.fee);
        }

        model.accumulateRevenue += batchSize * model.fee * model.receiverPercentage / 100;
        require(input.length > 0, "input not uploaded");
        bool noCallback = callbackContract == address(0);
        require(noCallback == (gasLimit == 0), "Invalid gasLimit");
        require(inputDA != DA.IPFS, "inputDA should not be IPFS");
    }

    function getRequestId(uint256 model, bytes memory input, address callbackContract, uint64 gasLimit, bytes memory callbackData) internal view returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                model,
                input,
                callbackContract,
                gasLimit,
                callbackData,
                msg.sender,
                block.timestamp
            )
        ));
    }

    function requestCallback(
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory callbackData
    ) external payable returns (uint256) {
        // validate params
        _validateParams(1, modelId, input, callbackContract, gasLimit, callbackData, DA.Calldata, DA.Calldata);

        ModelData memory model = models[modelId];

        // get requestId from opml
        uint256 requestId;
        if(model.unverifiable){
            requestId = getRequestId(modelId, input, callbackContract, gasLimit, callbackData);
        } else {
            requestId = opml.initOpmlRequest(model.modelHash, model.programHash, input);
        }
        

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
    
    // Support requestCallback with DA parameters.
    function requestCallback(
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory callbackData,
        DA inputDA,
        DA outputDA
    ) external payable returns (uint256) {
        // validate params
        _validateParams(1, modelId, input, callbackContract, gasLimit, callbackData, inputDA, outputDA);

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
        emit AICallbackRequest(request.account, requestId, modelId, input, callbackContract, gasLimit, callbackData, inputDA, outputDA, 1);

        return requestId;
    }

    // Batch inference, params should adopt specific input format
    function requestBatchInference(
        uint256 batchSize,
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory callbackData,
        DA inputDA,
        DA outputDA
    ) external payable returns (uint256) {
        // validate params
        _validateParams(batchSize, modelId, input, callbackContract, gasLimit, callbackData, inputDA, outputDA);

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
        emit AICallbackRequest(request.account, requestId, modelId, input, callbackContract, gasLimit, callbackData, inputDA, outputDA, batchSize);

        return requestId;
    }

    // any can call this function
    function claimModelRevenue(uint256 modelId) external ifModelExists(modelId) {
        ModelData storage model = models[modelId];
        require(model.accumulateRevenue > 0, "accumulate revenue is 0");
        uint256 transferRevenue = model.accumulateRevenue;
        model.accumulateRevenue = 0;

        if (model.token == address(0)) {
            (bool success, ) = (model.receiver).call{value: transferRevenue}("");
            require(success, "claimModelRevenue transfer failed");
        } else {
            IERC20(model.token).safeTransfer(model.receiver, transferRevenue);
        }
    }

    function getOutputHash(uint256 requestId) external view returns (bytes32) {
        return opml.getOutputHash(requestId);
    }

    // call this function if the opml result is challenged and updated!
    // anyone can call it!
    function updateResult(uint256 requestId, bytes calldata output) external {
        require(output.length > 0, "can not upload a zero-length output");
        // read request of requestId
        AICallbackRequestData storage request = requests[requestId];

        // get Latest output of request
        bytes32 outputHash = opml.getOutputHash(requestId);
        require(outputHash == keccak256(output), "output should match opml result");

        // invoke callback
        if(request.callbackContract != address(0)) {
            bytes memory payload = abi.encodeWithSelector(callbackFunctionSelector, request.requestId, output, request.callbackData);
            (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
            if (!success) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
        }

        emit AICallbackResult(request.account, requestId, msg.sender, output);
    }

    // payload includes (function selector, input, output)
    function invokeCallback(uint256 requestId, bytes calldata output) external onlyWhitelisted {
        // read request of requestId
        AICallbackRequestData memory request = requests[requestId];
        
        // others can challenge if the result is incorrect!
        ModelData memory model = models[request.modelId];
        if(!model.unverifiable) {
            opml.uploadResult(requestId, output);   
        }

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

    // invoke aiOracleCallbackError of client contract
    function feedbackError(uint256 requestId, AIOracleError code, bytes calldata message) external onlyWhitelisted {
        // read request of requestId
        AICallbackRequestData memory request = requests[requestId];

        // invoke callback
        require(request.callbackContract != address(0), "no callback contract");
        bytes memory payload = abi.encodeWithSelector(errorFunctionSelector, request.requestId, code, message, request.callbackData);
        (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
        require(success, "failed to call selector");
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function confirm(uint256 requestId, bytes32 outputHash) external {
        opml.confirm(requestId, outputHash);
        emit Confirm(msg.sender, requestId, outputHash);
    }
}