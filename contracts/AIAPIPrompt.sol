// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

// this contract is for OpenAI Model
contract AIAPIPrompt is AIOracleCallbackReceiver {
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

    function calcModelIdByName(string memory modelName) public pure returns (uint256) {
        return uint256(uint160(uint256(keccak256(bytes(modelName)))));
    }

    function estimateFee(string calldata modelName) public view returns (uint256) {
        return aiOracle.estimateFee(calcModelIdByName(modelName), callbackGasLimit);
    }

    function _requestAIOracle(string memory modelName, bytes memory jsonInput) private {
        uint256 modelId = calcModelIdByName(modelName);
        ( , ,uint256 fee, , , ,address token,) = IAIOracle(aiOracle).getModel(modelId);

        if(token != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), fee);
            IERC20(token).safeIncreaseAllowance(address(aiOracle), fee);
        }

        uint256 requestId = aiOracle.requestCallback{value: msg.value}(
            modelId, jsonInput, address(this), callbackGasLimit, ""
        );
        emit promptRequest(requestId, msg.sender, modelId, string(jsonInput));
    }

    function calculateAIResult(string calldata modelName, string calldata prompt) payable external {
        bytes memory jsonInput = abi.encodePacked(
            '{"model":"', modelName, '",',
            '"messages": [{"role": "user", "content": "', bytes(prompt),'"}]}'
        );

        _requestAIOracle(modelName, jsonInput);
    }

    function calculateAIImageResult(string calldata modelName, string calldata prompt) payable external {
        bytes memory jsonInput = abi.encodePacked(
            '{"model":"', modelName, '",',
            '"prompt": "', bytes(prompt),'"}'
        );

        _requestAIOracle(modelName, jsonInput);
    }

    function calculateAIImage2ImageResult(string calldata modelName, string calldata prompt, string calldata init_image_cid) payable external {
        bytes memory jsonInput = abi.encodePacked(
            '{"model":"', modelName, '",',
            '"prompt": "', bytes(prompt),'",',
            '"init_image": "', bytes(init_image_cid),'"}'
        );

        _requestAIOracle(modelName, jsonInput);
    }

    function calculateAIText2VideoResult(string calldata modelName, string calldata prompt) payable external {
        bytes memory jsonInput = abi.encodePacked(
            '{"model":"', modelName, '",',
            '"prompt": "', bytes(prompt),'"}'
        );

        _requestAIOracle(modelName, jsonInput);
    }

    function calculateAIImage2VideoResult(string calldata modelName, string calldata prompt, string calldata image_cid) payable external {
        bytes memory jsonInput = abi.encodePacked(
            '{"model":"', modelName, '",',
            '"prompt": "', bytes(prompt),'",',
            '"image": "', bytes(image_cid),'"}'
        );

        _requestAIOracle(modelName, jsonInput);
    }
}