# RSK AMM Demo

This project is a simple Automated Market Maker (AMM) DEX built for the Rootstock (RSK) blockchain. It lets you swap ERC20 tokens, provide liquidity, and experiment with trading fees, all via smart contracts.

## Features

- **Liquidity Pools:** Add or remove liquidity for any ERC20 token pair.
- **Token Swaps:** Trade tokens using the constant product (x*y=k) formula.
- **Governance:** Adjust trading fees via an owner-controlled contract.
- **Test Tokens:** Deploy and use your own ERC20 tokens for local testing.

## Getting Started

### 1. Clone the Repo

```bash
git clone https://github.com/yourusername/rsk-amm-demo.git
cd rsk-amm-demo
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Compile Contracts

```bash
npx hardhat compile
```

### 4. Run Tests

```bash
npx hardhat test
```

### 5. Deploy Locally

Start a local Hardhat node:

```bash
npx hardhat node
```

In a new terminal, deploy the contracts:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Usage
- **Add Liquidity:** Call addLiquidity on the LiquidityPool contract.
- **Swap Tokens:** Use the Swap contract to trade between tokens.
- **Adjust Fees:** As the contract owner, call setTradingFee on Governance.

You can interact with the contracts using Hardhat tasks, scripts, or your favorite frontend.

## Learn More
- [Rootstock Docs](https://dev.rootstock.io/)
- [Hardhat Docs](https://hardhat.org/hardhat-runner/docs/getting-started)
