const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Governance", function () {
  let Governance, governance, owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    Governance = await ethers.getContractFactory("Governance");
    governance = await Governance.deploy(50); // 0.5% fee
  });

  it("should set trading fee if within MAX_FEE", async function () {
    await expect(governance.setTradingFee(75)).to.not.be.reverted;
    expect(await governance.tradingFee()).to.equal(75);
  });

  it("should revert if fee > MAX_FEE", async function () {
    await expect(governance.setTradingFee(101)).to.be.revertedWith("Fee exceeds maximum");
  });
});
