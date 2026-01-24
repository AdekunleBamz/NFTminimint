const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Gas Optimization Tests", function () {
  let nftCore;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
  });

  describe("Single Mint Gas", function () {
    it("Should measure gas for single mint", async function () {
      const tx = await nftCore.mint(owner.address, "ipfs://test");
      const receipt = await tx.wait();
      console.log("    Single mint gas used:", receipt.gasUsed.toString());
      expect(receipt.gasUsed).to.be.lt(200000);
    });
  });

  describe("Batch Mint Gas Comparison", function () {
    it("Should be more gas efficient than individual mints", async function () {
      // Measure 5 individual mints
      let totalIndividualGas = 0n;
      for (let i = 0; i < 5; i++) {
        const tx = await nftCore.mint(owner.address, `ipfs://test${i}`);
        const receipt = await tx.wait();
        totalIndividualGas += receipt.gasUsed;
      }

      // Deploy fresh contract for batch test
      const NFTCore2 = await ethers.getContractFactory("NFTCore");
      const nftCore2 = await NFTCore2.deploy("Test2", "T2");
      await nftCore2.waitForDeployment();

      // Measure batch mint of 5
      const uris = Array(5).fill(0).map((_, i) => `ipfs://batch${i}`);
      const batchTx = await nftCore2.batchMint(owner.address, uris);
      const batchReceipt = await batchTx.wait();

      console.log("    5 individual mints gas:", totalIndividualGas.toString());
      console.log("    1 batch mint (5) gas:", batchReceipt.gasUsed.toString());
      console.log("    Gas saved:", (totalIndividualGas - batchReceipt.gasUsed).toString());
      
      expect(batchReceipt.gasUsed).to.be.lt(totalIndividualGas);
    });
  });
});
