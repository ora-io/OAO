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

| contract/EOA | Sepolia Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x8A4e9c637C186BBca27f1409F697B5Fb18f22334 |
| prompt       | 0xe75af5294f4CB4a8423ef8260595a54298c7a2FB |
| SimplePrompt | 0x696c83111a49eBb94267ecf4DDF6E220D5A80129 |
| opml         | 0x099b103cf40Fc56AaA82050a6276358416F5bD78 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**ETH MainNET**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x6d431EB9563984E5733B95521F7a672ADD8175a4 |
| prompt       | 0xb880D47D3894D99157B52A7F869aB3B1E2D4349d |
| SimplePrompt | 0x61423153f111BCFB28dd264aBA8d9b5C452228D2 |
| opml         | 0x2eCd8B8A77008A7F03944bf9cb778cFA0352FE82 |
| owner        | 0xE0b623C4Eb6600131bbfDcbFd3128d6573170e00 |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**OP Sepolia**

| contract/EOA | Sepolia Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0x3c8Cd1714AC9c380702D160BE4cee0D291Eb89C0 |
| SimplePrompt | 0xf6919ebb1bFdD282c4edc386bFE3Dea1a1D8AC16 |
| opml         | 0x76330A99fc9b82F1220187E54f462986216A536E |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**OP Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| SimplePrompt | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 |
| opml         | 0xf6919ebb1bFdD282c4edc386bFE3Dea1a1D8AC16 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Manta Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 |
| SimplePrompt | 0x523622DfEd0243B0DF80CC9275764B0f432D33E3 |
| opml         | 0xf6919ebb1bFdD282c4edc386bFE3Dea1a1D8AC16 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Manta Sepolia Testnet**

| contract/EOA | Testnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0x3bfD1Cc919bfeC7795b600E764aDa001b58f122a |
| opml         | 0x3c8Cd1714AC9c380702D160BE4cee0D291Eb89C0 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Arbitrum Sepolia Testnet**

| contract/EOA | Testnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| SimplePrompt | 0xBC24514E541d5CBAAC1DD155187A171a593e5CF6 |
| opml         | 0xf6919ebb1bFdD282c4edc386bFE3Dea1a1D8AC16 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Arbitrum Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| opml         | 0x16eC291baeDCB0fC1184D9D89Dd5f362E2bf8061 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Linea Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xb880d47d3894d99157b52a7f869ab3b1e2d4349d |
| opml         | 0x10C1D2196BAf494802D7360E81E5e9e16afA9481 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Base Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293c8d0f9ce7609217de22698e2dcbcfb2bd3d9d |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| opml         | 0x16eC291baeDCB0fC1184D9D89Dd5f362E2bf8061 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Polygon Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x5d94dffaf1a4892cd2427209177b57585333ca5f |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| opml         | 0x16eC291baeDCB0fC1184D9D89Dd5f362E2bf8061 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

**Mantle Mainnet**

| contract/EOA | Mainnet Address                            |
| ------------ | ------------------------------------------ |
| OAO proxy    | 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0 |
| OAO logic    | 0x293C8D0f9CE7609217De22698e2DCBCFb2Bd3d9D |
| prompt       | 0xC20DeDbE8642b77EfDb4372915947c87b7a526bD |
| SimplePrompt | 0xC3287BDEF03b925A7C7f54791EDADCD88e632CcD |
| opml         | 0x16eC291baeDCB0fC1184D9D89Dd5f362E2bf8061 |
| owner        | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |
| server       | 0xf5aeB5A4B35be7Af7dBfDb765F99bCF479c917BD |

Currently, you can use the onchain ML model by initiating an onchain transaction by interacting with Prompt contract. We have uploaded two models to OAO.

| modelID | model                 | fee (sepolia) | fee (mainnet) | fee (polygon) | fee (mantle) | 
| ------- | --------------------- | ------------- | ------------- | ------------- | ------------- |
| 50      | Stable Diffusion (SD) | 0.01eth       | 0.0003eth      | 3 MATIC      | 3 MNT      |
| 11      | llama                 | 0.01eth       | 0.0003eth      | 3 MATIC      | 3 MNT      |
| 7007    | 7007                  | 0.01eth       | 0.0003eth      | 3 MATIC      | 3 MNT      |
| 13      | Open LM               | 0.01eth       | 0.0003eth      | not support      | not support      |
| 14      | Open LM Score         | 0.01eth       | not support    | not support      | not support      |
| 15      | Open LM Chat          | 0.01eth       | not support    | not support      | not support      |

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
