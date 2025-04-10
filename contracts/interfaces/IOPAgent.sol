// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOPAgent {
  function singleChat(
    string calldata prompt,
    uint64 gaslimit
  ) external payable;

  function multiRoundChat(
    string calldata messages,
    uint64 gaslimit
  ) external payable;

  function opAgentRegister() external payable returns (uint256);
}