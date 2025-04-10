// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

// this contract is for OpenAI Model
contract OpenAIPrompt is AIOracleCallbackReceiver {
    using SafeERC20 for IERC20;
    event promptsUpdated(
        uint256 requestId,
        string output,
        bytes callbackData
    );

    event promptRequest(
        uint256 requestId,
        address sender, 
        uint256 modelId,
        string prompt
    );

    struct AIOracleRequest {
        address sender;
        uint256 modelId;
        bytes input;
        bytes output;
    }

    uint256 public gpt4oModelId;
    uint256 public dalle2ModelId;
    uint64 public callbackGasLimit;

    address immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // requestId => AIOracleRequest
    mapping(uint256 => AIOracleRequest) public requests;

    /// @notice Initialize the contract, binding it to a specified AIOracle.
    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {
        owner = msg.sender;
        gpt4oModelId = 1418312085442921183558972613383104240625681548639; // OpenAI/GPT-4o
        dalle2ModelId = 1026312455553990538593839730755758166047834159184; // OpenAI/Dall.E-2
        callbackGasLimit = 2500000;
    }

    function setCallbackGasLimit(uint64 gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
    }

    // the callback function, only the AI Oracle can call this function
    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback() {
        emit promptsUpdated(requestId, string(output), callbackData);
    }

    function aiOracleCallbackError(uint256 requestId, AIOracleError code, bytes calldata message, bytes calldata callbackData) external override onlyAIOracleCallback() {
        emit AICallbackError(requestId, code, message, callbackData);
    }

    function estimateFee(uint256 modelId) public view returns (uint256) {
        return aiOracle.estimateFee(modelId, callbackGasLimit);
    }

    // chat completion with aiOracle.requestCallback
    function openAIChatCompletion(string calldata prompt) payable external {
        uint256 modelId = gpt4oModelId;
        bytes memory promptBytes = bytes(prompt);

        bytes memory jsonInput = abi.encodePacked(
            '{"method":"v1/chat/completions",',
            '"simplify":true,',
            '"data":{',
            '"messages":[',
            '{"role":"system","content":"You are a helpful assistant."},',
            '{"role":"user","content":"', promptBytes, '"}',
            ']}}'
        );

        uint256 fee;
        address token;
        ( , , fee, , , , token,) = IAIOracle(aiOracle).getModel(modelId);

        if(token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(token).safeIncreaseAllowance(address(aiOracle), fee);
        }

        uint256 requestId = aiOracle.requestCallback{value: msg.value}(
            modelId, jsonInput, address(this), callbackGasLimit, ""
        );
        emit promptRequest(requestId, msg.sender, modelId, prompt);
    }

    // images generations with aiOracle.requestCallback with DA parameters.
    function openAIImageGeneration(string calldata prompt) payable external {
        uint256 modelId = dalle2ModelId;
        bytes memory promptBytes = bytes(prompt);
        bytes memory jsonInput = abi.encodePacked(
            '{"method":"v1/images/generations",',
            '"simplify":true,',
            '"data":{',
            '"prompt":"', promptBytes, '",'
            '"size":"1024x1024"',
            '}}'
        );

        uint256 fee;
        address token;
        ( , , fee, , , , token,) = IAIOracle(aiOracle).getModel(modelId);

        if(token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(token).safeIncreaseAllowance(address(aiOracle), fee);
        }

        uint256 requestId = aiOracle.requestCallback{value: msg.value}(
            modelId, jsonInput, address(this), callbackGasLimit, "", IAIOracle.DA.Calldata, IAIOracle.DA.IPFS
        );
        emit promptRequest(requestId, msg.sender, modelId, prompt);
    }
}