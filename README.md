# OAO: Onchain AI Oracle

> OAO (onchain AI oracle), powered by [opML](https://github.com/hyperoracle/opml) (optimistic machine learning) on Ethereum, brings ML model onchain.

## Architecture and Workflow

The specific architecture of OAO is as follows. The user's contract can initiate an AI request by calling OAO, OAO will publish the request to opML node for processing, and then OAO will return the AI result to the user.

![OAO Workflow](images/OAO.png)

In terms of workflow, we need to break down the explanation into two parts.

Usage process:

1. The user contract sends the AI request to OAO on chain, by calling `requestCallback` function on the OAO contract.
2. Each AI request will initiate an opML request.
3. OAO will emit a `requestCallback` event which will be collected by opML node.
4. opML node will run the AI inference, and then upload the result on chain.
    
    Challenge process:
    
    1. The challenge window starts right after step 4 in previous section.
    2. During the challenge period, the opML validators (or anyone) will be able to check the result and challenge it if the submitted result is incorrect.
    3. If the submitted result is successfully challenged by one of the validators, the submitted result will be updated on chain.
    4. After the challenge period, the submitted result on chain is finalized (results can not be mutated).
5. When the result is uploaded or updated on chain, the provided result in opML will be dispatched to the user's smart contract via its specific callback function.

## Deployment

Here are the OAO contracts deployed onchain:

**ETH Sepolia**

| contract | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xe75af5294f4CB4a8423ef8260595a54298c7a2FB |
| SimplePrompt | 0x696c83111a49eBb94267ecf4DDF6E220D5A80129 |

**ETH Mainnet**

| contract | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xb880D47D3894D99157B52A7F869aB3B1E2D4349d |
| SimplePrompt | 0x61423153f111BCFB28dd264aBA8d9b5C452228D2 | 

**Optimism Sepolia**

| contract/EOA | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0x3c8Cd1714AC9c380702D160BE4cee0D291Eb89C0 |
| SimplePrompt | 0xf6919ebb1bFdD282c4edc386bFE3Dea1a1D8AC16 | 

**Optimism Mainnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| SimplePrompt | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 | 

**Manta Mainnet**

| contract/EOA | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 |
| SimplePrompt | 0x523622DfEd0243B0DF80CC9275764B0f432D33E3 | 

**Manta Sepolia Testnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0x3bfD1Cc919bfeC7795b600E764aDa001b58f122a | 

**Arbitrum Sepolia Testnet**

| contract/EOA | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| SimplePrompt | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 | 

**Arbitrum Mainnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Linea Mainnet**

| contract/EOA | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xb880d47d3894d99157b52a7f869ab3b1e2d4349d | 

**Base Mainnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Polygon Mainnet**

| contract/EOA | Sepolia Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Mantle Mainnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Morph Mainnet**

| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Mode Mainnet**
| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**Mode Sepolia**
| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD | 

**BSC Mainnet**
| contract/EOA | Mainnet Address |
|--|--|
| OAO    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |  
| prompt | 0x76330A99fc9b82F1220187E54f462986216A536E |
| SimplePrompt | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD | 

Currently, you can use the onchain ML model by initiating an onchain transaction by interacting with Prompt contract. We have uploaded two models to OAO.

| modelID | model| 
| -- | -- |
| 11      | llama                      |
| 50      | Stable Diffusion (SD)      |
| 7007    | 7007                       |
| 13      | Open LM                    |
| 14      | Open LM Score              |
| 15      | Open LM Chat               |
| 503     | Stable Diffusion V3 (SDv3) |

AI API Models

| model                                        | fee (ORA) (divided by 1e18) |
|---------------------------------------------|-----------------------------|
| meta-llama/Llama-3.3-70B-Instruct            | 0.18                        |
| Qwen/QwQ-32B-Preview                         | 0.24                        |
| Qwen/Qwen2.5-Coder-32B-Instruct              | 0.16                        |
| meta-llama/Llama-3.2-3B-Instruct             | 0.01                        |
| mistralai/Mixtral-8x22B-Instruct-v0.1        | 0.24                        |
| meta-llama/Meta-Llama-3-70B-Instruct         | 0.18                        |
| Qwen/Qwen2-72B-Instruct                      | 0.18                        |
| google/gemma-2-27b-it                        | 0.16                        |
| google/gemma-2-9b-it                         | 0.06                        |
| mistralai/Mistral-7B-Instruct-v0.3           | 0.04                        |
| google/gemma-2b-it                           | 0.02                        |
| mistralai/Mistral-7B-Instruct-v0.2           | 0.04                        |
| mistralai/Mixtral-8x7B-Instruct-v0.1         | 0.12                        |
| mistralai/Mistral-7B-Instruct-v0.1           | 0.04                        |
| meta-llama/Llama-2-13b-chat-hf               | 0.04                        |
| meta-llama/Llama-2-7b-chat-hf                | 0.04                        |
| meta-llama/Llama-3.1-405B-Instruct           | 0.7                         |
| Qwen/Qwen2.5-72B-Instruct                    | 0.24                        |
| meta-llama/Llama-3.2-1B-Instruct             | 0.01                        |
| meta-llama/Meta-Llama-3-8B-Instruct          | 0.04                        |
| black-forest-labs/FLUX.1-dev                 | 0.09                        |
| black-forest-labs/FLUX.1-canny               | 0.09                        |
| black-forest-labs/FLUX.1-redux-dev           | 0.09                        |
| black-forest-labs/FLUX.1-schnell             | 0.01                        |
| deepseek-ai/DeepSeek-V3                      | 0.25                        |
| stabilityai/stable-diffusion-3.5-medium      | 0.13                        |
| stabilityai/stable-diffusion-3-medium        | 0.13                        |
| stabilityai/stable-diffusion-3.5-large       | 0.24                        |
| stabilityai/stable-diffusion-3.5-large-turbo | 0.15                        |
| openai/gpt-4o                                | 0.09                        |
| openai/dall-e-2                              | 0.01                        |
| kling-ai/kling-v1                            | 1.00                        |
| kling-ai/kling-v1-6                          | 1.00                        |

If you need to calculate the modelId of a specific model, please refer to the code below.

```solidity
function calcModelIdByName(string calldata modelName) public pure returns (uint256) {
    return uint256(uint160(uint256(keccak256(bytes(modelName)))));
}
```
or
```javascript
// modelIdString: 'openai/gpt-4o'
function modelIdStringToBigInt(modelIdString) {
  const hashedValue = ethers.keccak256(ethers.toUtf8Bytes(modelIdString));
  const addressValue = `0x${hashedValue.slice(26)}`;
  return BigInt(addressValue);
}
```

## Usage

1. Inherit `AIOracleCallbackReceiver`  in your contract and bind with a specific OAO address:
    ```solidity
    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {}
    ```
2. Write your callback function to handle the AI result from OAO. Note that only OAO can call this function:
    ```solidity
    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback()
    ```
3. When you want to initiate an AI inference request, call OAO as follows:
    ```solidity
    aiOracle.requestCallback(modelId, input, address(this), gas_limit, callbackData);
    ```
