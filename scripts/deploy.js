// scripts/deploy.js
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  // 1. Deploy Governance (0.3% fee)
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(30); // 30 basis points (0.3%)
  console.log(`Governance deployed to: ${governance.address}`);

  // 2. Deploy LiquidityPool with burn address for testing
  const burnAddress = "0x000000000000000000000000000000000000dEaD";
  const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
  const liquidityPool = await LiquidityPool.deploy(
    governance.address,
    burnAddress
  );
  console.log(`LiquidityPool deployed to: ${liquidityPool.address}`);

  // 3. Deploy Swap helper
  const Swap = await ethers.getContractFactory("Swap");
  const swap = await Swap.deploy(governance.address, liquidityPool.address);
  console.log(`Swap deployed to: ${swap.address}`);

  // 4. Save addresses to a config file (for frontend/scripts)
  const config = {
    governance: governance.address,
    liquidityPool: liquidityPool.address,
    swap: swap.address,
    burnAddress: burnAddress
  };

  fs.writeFileSync("deployments/latest.json", JSON.stringify(config, null, 2));
  console.log("Configuration saved to deployments/latest.json");
}

// Helper for Foundry compatibility
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = main;