const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("Swap Invariant", function () {
  let Token, tokenA, tokenB;
  let Governance, governance;
  let LiquidityPool, liquidityPool;
  let Swap, swap;
  let owner, user;

  
  beforeEach(async function () {
    // console.log("Ethers Utils:", ethers.utils);

    [owner, user] = await ethers.getSigners();

    const initialSupply = ethers.utils.parseEther("1000000");

    // Deploy two ERC20 tokens
    Token = await ethers.getContractFactory("TestToken");
    tokenA = await Token.deploy("Token A", "TKA", initialSupply);
    tokenB = await Token.deploy("Token B", "TKB", initialSupply);

    // Deploy Governance contract
    Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(50); // 0.5%

    // Deploy Liquidity Pool
    LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    liquidityPool = await LiquidityPool.deploy();

    // Deploy Swap contract
    Swap = await ethers.getContractFactory("Swap");
    swap = await Swap.deploy(governance.address, liquidityPool.address);

    // Approve and add liquidity
    const liquidityAmount = ethers.utils.parseEther("1000");
    await tokenA.approve(liquidityPool.address, liquidityAmount);
    await tokenB.approve(liquidityPool.address, liquidityAmount);

    await liquidityPool.addLiquidity(
      tokenA.address,
      tokenB.address,
      liquidityAmount,
      liquidityAmount,
      0,
      0
    );

    // Send tokens to user
    await tokenA.transfer(user.address, ethers.utils.parseEther("100"));
  });

  it("should not decrease reserveA * reserveB after a swap", async function () {
    const amountIn = ethers.utils.parseEther("10");

    // User approves tokenA to Swap
    await tokenA.connect(user).approve(swap.address, amountIn);

    // Get reserves before swap
    const [reserveA1, reserveB1] = await liquidityPool.getReserves(tokenA.address, tokenB.address);
    const kBefore = reserveA1.mul(reserveB1);

    // Perform the swap
    await swap.connect(user).swap(tokenA.address, tokenB.address, amountIn);

    // Get reserves after swap
    const [reserveA2, reserveB2] = await liquidityPool.getReserves(tokenA.address, tokenB.address);
    const kAfter = reserveA2.mul(reserveB2);

    // Invariant: kAfter >= kBefore
    expect(kAfter.gte(kBefore)).to.be.true;
  });
});