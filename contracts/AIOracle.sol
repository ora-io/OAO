// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IOpml.sol";
import "./IAIOracle.sol";

contract AIOracle is IAIOracle {

    uint256 public fee;
    address public server;

    IOpml immutable opml;

    struct AICallbackRequestData{
        address account;
        uint256 requestId;
        uint256 modelId;
        bytes input;
        address callbackContract;
        bytes4 functionSelector;
        uint64 gasLimit;
    }

    mapping(uint256 => AICallbackRequestData) public requests;

    constructor(uint256 _fee, IOpml _opml) {
        fee = _fee;
        server = msg.sender;
        opml = _opml;
    }


    modifier onlyServer() {
        require(msg.sender == server, "Only server can call this function");
        _;
    }

    function setFee(uint256 _fee) external onlyServer {
        fee = _fee;
    }

    function uploadModel(bytes32 modelHash, bytes32 programHash, string calldata description) external onlyServer returns (uint256 modelId) {
        return opml.uploadModel(modelHash, programHash, description);
    }

    function requestCallback(
        uint256 modelId,
        bytes calldata input,
        address callbackContract,
        bytes4 functionSelector,
        uint64 gasLimit
    ) external payable {
        require(msg.value >= fee, "insuefficient fee");
        uint256 requestId = opml.initOpmlRequest(modelId, input);
        // store the request so that anyone can update the result according to the opml
        AICallbackRequestData storage request = requests[requestId];
        request.account = msg.sender;
        request.requestId = requestId;
        request.modelId = modelId;
        request.input = input;
        request.callbackContract = callbackContract;
        request.functionSelector = functionSelector;
        request.gasLimit = gasLimit;
        // Emit event
        emit AICallbackRequest(msg.sender, requestId, modelId, input, callbackContract, functionSelector, gasLimit);
    }


    // call this function if the opml result is challenged and updated!
    // anyone can call it!
    function updateResult(uint256 requestId) external {
        AICallbackRequestData storage request = requests[requestId];
        bytes memory output = opml.getOutput(requestId);
        require(output.length != 0, "the output of this request is not uploaded yet.");
        // invoke callback
        bytes memory payload = abi.encodeWithSelector(request.functionSelector, request.modelId, request.input, output);
        (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
        require(success, "failed to call selector!");
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
        emit AICallbackResult(requestId, output);
    }

    // payload includes (function selector, input, output)
    function invokeCallback(uint256 requestId, bytes calldata output) external onlyServer {
        AICallbackRequestData storage request = requests[requestId];
        // others can challenge if the result is incorrect!
        opml.uploadResult(requestId, output);
        // invoke callback
        bytes memory payload = abi.encodeWithSelector(request.functionSelector, request.modelId, request.input, output);
        (bool success, bytes memory data) = request.callbackContract.call{gas: request.gasLimit}(payload);
        require(success, "failed to call selector!");
        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
        emit AICallbackResult(requestId, output);
    }
}
