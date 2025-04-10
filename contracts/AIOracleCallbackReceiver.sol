// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAIOracle.sol";

/// @notice A base contract for writing a AIOracle app
abstract contract AIOracleCallbackReceiver {

    // Address of the AIOracle contract
    IAIOracle public immutable aiOracle;

    // Invalid callback source error
    error UnauthorizedCallbackSource(IAIOracle expected, IAIOracle found);

    enum AIOracleError {
        InvalidInput, // the input data can't be parsed due to wrong format
        InvalidBatchSize // batchSize can't cover actual batch inference number
    }

    event AICallbackError(uint256 indexed requestId, AIOracleError indexed code, bytes message, bytes callbackData);

    /// @notice Initialize the contract, binding it to a specified AIOracle contract
    constructor(IAIOracle _aiOracle) {
        aiOracle = _aiOracle;
    }

    /// @notice Verify this is a callback by the aiOracle contract 
    modifier onlyAIOracleCallback() {
        IAIOracle foundRelayAddress = IAIOracle(msg.sender);
        if (foundRelayAddress != aiOracle) {
            revert UnauthorizedCallbackSource(aiOracle, foundRelayAddress);
        }
        _;
    }

    /**
     * @dev the callback function in OAO, should add the modifier onlyAIOracleCallback!
     * @param requestId Id for the request in OAO (unique per request)
     * @param output AI model's output
     * @param callbackData user-defined data (The same as when the user call aiOracle.requestCallback)
     */
    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external virtual;

    function isFinalized(uint256 requestId) external view returns (bool) {
        return aiOracle.isFinalized(requestId);
    }

    /**
     * @dev add this error handle interface to avoid messing up with “missing callback” verification
     * @param requestId Id for the request in OAO (unique per request)
     * @param code Error code for the request
     * @param message Error message. Since we have err code, message can be void in most of case to save gas, stay as a placeholder
     * @param callbackData user-defined data (The same as when the user call aiOracle.requestCallback)
     */
    function aiOracleCallbackError(uint256 requestId, AIOracleError code, bytes calldata message, bytes calldata callbackData) external virtual {
        emit AICallbackError(requestId, code, message, callbackData);
    }
}