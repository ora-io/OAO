// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAIOracle {
    /// @notice Event emitted upon receiving a callback request through requestCallback.
    event AICallbackRequest(
        address account,
        uint256 requestId,
        uint256 modelId,
        bytes input,
        address callbackContract,
        bytes4 functionSelector,
        uint64 gasLimit
    );

    /// @notice Event emitted when the result is uploaded or update.
    event AICallbackResult(
        uint256 requestId,
        bytes output
    );

    function requestCallback(
        uint256 modelId,
        bytes calldata input,
        address callbackContract,
        bytes4 functionSelector,
        uint64 gasLimit
    ) external payable;
}