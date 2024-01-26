// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IAIOracle.sol";

/// @notice A base contract for writing a AIOracle app
abstract contract AIOracleCallbackReceiver {

    // Address of the AIOracle contract
    IAIOracle public immutable aiOracle;

    // Invalid callback source error
    error UnauthorizedCallbackSource(IAIOracle expected, IAIOracle found);

    /// @notice Initialize the contract, binding it to a specified AIOracle contract
    constructor(IAIOracle _aiOracle) {
        aiOracle = _aiOracle;
    }

    /// @notice Verify that the call came from the AIOracle contract
    function _verifyMessageSource() internal view {
        IAIOracle foundRelayAddress = IAIOracle(msg.sender);
        if (foundRelayAddress != aiOracle) {
            revert UnauthorizedCallbackSource(aiOracle, foundRelayAddress);
        }
    }

    /// @notice Verify this is a callback by the aiOracle contract 
    modifier onlyAIOracleCallback() {
        _verifyMessageSource();
        _;
    }
}