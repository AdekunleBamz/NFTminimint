const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTBatchMintLimit Extension", function () {
    let mock;

    beforeEach(async function () {
        const MockNFTBatchMintLimit = await ethers.getContractFactory("MockNFTBatchMintLimit");
        mock = await MockNFTBatchMintLimit.deploy();
        await mock.waitForDeployment();
    });

    it("Should allow unlimited when max is zero", async function () {
        await mock.setMaxBatch(0);
        await expect(mock.batchMint(100)).to.not.be.reverted;
        expect(await mock.totalMinted()).to.equal(100);
    });

    it("Should enforce max batch mint limit", async function () {
        await mock.setMaxBatch(5);
        await expect(mock.batchMint(5)).to.not.be.reverted;
        await expect(mock.batchMint(6)).to.be.revertedWith("Batch limit exceeded");
    });
});
