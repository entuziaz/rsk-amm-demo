# Roostock AMM Demo

[![Built for Rootstock](https://img.shields.io/badge/Network-Rootstock-orange)](https://rootstock.io)
[![Solidity 0.8.28](https://img.shields.io/badge/Solidity-0.8.28-blue)](https://docs.soliditylang.org)



This project is a simple Automated Market Maker (AMM) DEX built for the Rootstock blockchain. It lets you swap ERC20 tokens, provide liquidity, and experiment with trading fees, all via smart contracts.


## 📦 Contracts

| Contract | Purpose |
|----------|---------|
| `Governance.sol` | Manages protocol fees (owner-controlled) |
| `LiquidityPool.sol` | Core AMM logic with auto-LP token minting |
| `LPToken.sol` | ERC20 receipts for liquidity providers |
| `Swap.sol` | User-friendly swapping interface |
| `TestToken.sol` | Mock ERC20 tokens for testing |


### Prerequisites
- Node.js v18+
- Hardhat 
- Foundry 
- Git

##  🚀 Quickstart
### **1. Clone & Install**

```bash
git clone https://github.com/entuziaz/rsk-amm-demo.git
cd rsk-amm-demo

# Install Foundry (if not installed)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Install Node dependencies
npm install
```

### **2. Configure Environment**

Create `.env`:
```
# .env
PRIVATE_KEY="0xYourTestnetKey"
RSK_TESTNET_RPC="https://public-node.testnet.rsk.co" 
```

### 2. Run Tests(Foundry)
```bash
forge test -vvv
```


### 3. Compile Contracts

```bash
npx hardhat compile
```

### 4. Run Tests

```bash
npx hardhat test
```

### 5. Deploy to Testnet

In a new terminal, deploy the contracts:

```bash
npx hardhat run scripts/deploy.js --network rsk_testnet
```

Verify deployed contracts:

```bash
npx hardhat verify --network rsk_testnet 0xYourContractAddress
```

The deployed contracts will be available on the [Rootstock Testnet Explorer](https://explorer.testnet.rootstock.io/).


## **📚 Learn More**
- [Rootstock Documentation](https://developers.rsk.co/)  
- [Hardhat Tutorial](https://hardhat.org/tutorial/)  


### **For Non-Technical Users**
> "This system lets you create token swap pools like Uniswap. Developers can deploy it, while end-users trade tokens via the Swap contract."

