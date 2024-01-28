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

## Deployment and Usage

Here are the OAO contracts deployed onchain:

- AIOracle: [0xb880D47D3894D99157B52A7F869aB3B1E2D4349d](https://sepolia.etherscan.io/address/0xb880D47D3894D99157B52A7F869aB3B1E2D4349d)
- Prompt (example user contract attached to AIOracle): [0x5d6963003Ad172Fd1D2A2fD18bB3967eA7Aef1a2](https://sepolia.etherscan.io/address/0x5d6963003Ad172Fd1D2A2fD18bB3967eA7Aef1a2)

Currently, you can use the onchain ML model by initiating an onchain transaction by interacting with Prompt contract. We have uploaded two models to OAO: LlaMA 2 (LLM model, modelID: 0) and Stable Diffusion (Image Generation Model, modelID 1).

