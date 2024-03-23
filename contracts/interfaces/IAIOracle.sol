// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAIOracle {
    /// @notice Event emitted upon receiving a callback request through requestCallback.
    event AICallbackRequest(
        address indexed account,
        uint256 indexed requestId,
        uint256 modelId,
        bytes input,
        address callbackContract,
        uint64 gasLimit,
        bytes callbackData
    );

    /// @notice Event emitted when the result is uploaded or update.
    event AICallbackResult(
        address indexed account,
        uint256 indexed requestId,
        address invoker,
        bytes output
    );

    /**
     * initiate a request in OAO
     * @param modelId ID for AI model
     * @param input input for AI model
     * @param callbackContract address of callback contract
     * @param gasLimit gas limitation of calling the callback function
     * @param callbackData optional, user-defined data, will send back to the callback function
     * @return requestID
     */
    function requestCallback(
        uint256 modelId,
        bytes memory input,
        address callbackContract,
        uint64 gasLimit,
        bytes memory callbackData
    ) external payable returns (uint256);

    function estimateFee(uint256 modelId, uint256 gasLimit) external view returns (uint256);

    function isFinalized(uint256 requestId) external view returns (bool);
}