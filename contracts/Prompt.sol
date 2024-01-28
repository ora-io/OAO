// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

// this contract is for ai.hyperoracle.io websie
contract Prompt is AIOracleCallbackReceiver {
    event promptsUpdated(
        uint256 modelId,
        string input,
        string output
    );

    event promptRequest(
        address sender, 
        uint256 modelId,
        string prompt
    );

    /// @notice Initialize the contract, binding it to a specified AIOracle.
    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {}

    /// @notice Gas limit set on the callback from AIOracle.
    /// @dev Should be set to the maximum amount of gas your callback might reasonably consume.
    uint64 private constant AIORACLE_CALLBACK_GAS_LIMIT = 5000000;

    // uint256: modelID, 0 for Llama, 1 for stable diffusion
    // 1.string => 2.string: 1.string: prompt, 2.string: text (for llama), cid (for sd) 
    mapping(uint256 => mapping(string => string)) public prompts;

    function getAIResult(uint256 modelId, string calldata prompt) external view returns (string memory) {
        return prompts[modelId][prompt];
    }

    // only the AI Oracle can call this function
    function storeAIResult(uint256 modelId, bytes calldata input, bytes calldata output) external onlyAIOracleCallback() {
        prompts[modelId][string(input)] = string(output);
        emit promptsUpdated(modelId, string(input), string(output));
    }

    function calculateAIResult(uint256 modelId, string calldata prompt) external {
        bytes memory input = bytes(prompt);
        aiOracle.requestCallback(
            modelId, input, address(this), this.storeAIResult.selector, AIORACLE_CALLBACK_GAS_LIMIT
        );
        emit promptRequest(msg.sender, modelId, prompt);
    }
}
