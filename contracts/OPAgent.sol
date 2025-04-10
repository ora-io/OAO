// SampleContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IAIOracle.sol';
import './AIOracleCallbackReceiver.sol';
import './Utils.sol';

import './interfaces/IOPAgent.sol';

contract OPAgent is AIOracleCallbackReceiver, IOPAgent {
  using SafeERC20 for IERC20;

  // the system prompt for the opAgent
  string systemPrompt;

  // the model name
  string modelName;

  // the model used by the opAgent
  uint256 public modelId;

  bytes32 registerHash;

  // the default gas limit for the callback
  uint64 public callbackGasLimit;

  error IncorrectCallbackResults(
    uint256 requestId,
    bytes output,
    bytes callbackData
  );

  error OnlyOPAgentAuthenticationError(address agentAddress, address msgSender);

  error OnlyAfterRegisterError(bytes32 registerHash);

  event OPAgentRegisterRequest(
    address agentAddress,
    uint256 modelId,
    string systemPrompt
  );

  event OPAgentRegisterResponse(bytes32 registerHash, string message);

  event OPAgentChatResponse(uint256 requestId, string message);

  /// @notice Initialize the contract, binding it to a specified AIOracle contract
  constructor(
    IAIOracle _aiOracle,
    string memory _modelName,
    string memory _systemPrompt
  ) AIOracleCallbackReceiver(_aiOracle) {
    modelName = _modelName;
    modelId = calcModelIdByName(_modelName);
    systemPrompt = _systemPrompt;
    callbackGasLimit = 500000;
  }

  function calcModelIdByName(
    string memory _modelName
  ) public pure returns (uint256) {
    return uint256(uint160(uint256(keccak256(bytes(_modelName)))));
  }

  function estimateFee() public view returns (uint256) {
    return aiOracle.estimateFee(modelId, callbackGasLimit);
  }

  /// @notice Verify this is a callback by the opAgent
  modifier onlyOPAgentCallback() {
    if (msg.sender != address(this)) {
      revert OnlyOPAgentAuthenticationError(address(this), msg.sender);
    }
    _;
  }

  modifier onlyAfterRegister() {
    if (registerHash == bytes32(0)) {
      revert OnlyAfterRegisterError(registerHash);
    }
    _;
  }

  // the callback function, only the AI Oracle can call this function
  function aiOracleCallback(
    uint256 requestId,
    bytes calldata output,
    bytes calldata callbackData
  ) external override onlyAIOracleCallback {
    if (output.length < 4) {
      revert IncorrectCallbackResults(requestId, output, callbackData);
    }

    bytes4 functionSelector = bytes4(output[:4]);

    bytes memory payload = output[4:]; // Everything after the first 4 bytes is the payload

    if (functionSelector == bytes4(0x00)) {
      // Call the default chatRespond function with the payload
      bytes4 defaultFunc = this.chatRespond.selector; // bytes4(keccak256("chatRespond(uint256,string)"));

      (bool success, ) = address(this).call(
        abi.encodePacked(defaultFunc, payload)
      );
      if (!success) {
        revert('chatRespond call failed');
      }
    } else {
      // Call the corresponding function using the selector directly
      (bool success, ) = address(this).call(
        abi.encodePacked(functionSelector, payload)
      );
      if (!success) {
        revert('Function call failed');
      }
    }
  }

  function _chat(
    string memory messages,
    uint64 gasLimit
  ) private onlyAfterRegister {
    // if gasLimit is not set, use the default gas limit
    if (gasLimit == 0) {
      gasLimit = callbackGasLimit;
    }

    // pack the contract address, modelName, systemPrompt into bytes and send to AIOracle
    bytes memory jsonInput = abi.encodePacked(
      '{"method":"v1/agents/chat",',
      '"data":{',
      '"model":"',
      modelName,
      '",',
      '"registerHash":"',
      Utils.bytes32ToString(registerHash),
      '",',
      '"contractAddress":"',
      Utils.addressToString(address(this)),
      '",',
      '"messages": ',
      messages,
      '}}'
    );

    (, , uint256 fee, , , , address token, ) = IAIOracle(aiOracle).getModel(
      modelId
    );

    if (token != address(0)) {
      IERC20(token).safeTransferFrom(msg.sender, address(this), fee);
      IERC20(token).safeIncreaseAllowance(address(aiOracle), fee);
    }

    uint256 requestId = aiOracle.requestCallback{value: msg.value}(
      modelId,
      jsonInput,
      address(this),
      gasLimit,
      ''
    );
    emit OPAgentChatResponse(requestId, messages);
  }

  /**
   * 
   * @param prompt string of the prompt
   * @param gasLimit // set gasLimit to 0 to use the default gas limit
   */
  function singleChat(
    string calldata prompt,
    uint64 gasLimit
  ) external payable virtual onlyAfterRegister {
    string memory messages = string(abi.encodePacked('[{"role": "user", "content": "', prompt, '"}]'));
    _chat(messages, gasLimit);
  }

  /**
   * 
   * @param messages a json string of messages
   * @param gasLimit // set gasLimit to 0 to use the default gas limit
   */
  function multiRoundChat(
    string calldata messages,
    uint64 gasLimit
  ) external payable virtual onlyAfterRegister {
    _chat(messages, gasLimit);
  }

  function chatRespond(
    uint256 requestId,
    string calldata message
  ) public virtual onlyOPAgentCallback {
    emit OPAgentChatResponse(requestId, message);
  }

  function handleRegister(
    bytes32 _registerHash,
    string calldata message
  ) public onlyOPAgentCallback {
    if (_registerHash != bytes32(0)) {
      registerHash = _registerHash;
    }
    emit OPAgentRegisterResponse(_registerHash, message);
  }

  function opAgentRegister() external payable returns (uint256) {
    // pack the contract address, modelId, systemPrompt into bytes and send to AIOracle
    bytes memory jsonInput = abi.encodePacked(
      '{"method":"v1/agents/register",',
      '"data":{',
      '"contractAddress":"',
      Utils.addressToString(address(this)),
      '",',
      '"model":"',
      modelName,
      '",',
      '"systemPrompt":"',
      systemPrompt,
      '"',
      '}}'
    );

    (, , uint256 fee, , , , address token, ) = IAIOracle(aiOracle).getModel(
      modelId
    );

    if (token != address(0)) {
      IERC20(token).safeTransferFrom(msg.sender, address(this), fee);
      IERC20(token).safeIncreaseAllowance(address(aiOracle), fee);
    }

    uint256 requestId = aiOracle.requestCallback{value: msg.value}(
      modelId,
      jsonInput,
      address(this),
      50000,
      ''
    );

    emit OPAgentRegisterRequest(address(this), modelId, systemPrompt);

    return requestId;
  }

  function aiOracleCallbackError(
    uint256 requestId,
    AIOracleError code,
    bytes calldata message,
    bytes calldata callbackData
  ) external override onlyAIOracleCallback {
    emit AICallbackError(requestId, code, message, callbackData);
  }

  receive() external payable {}
}
