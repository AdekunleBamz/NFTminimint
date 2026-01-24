const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMetadataFreeze Extension", function () {
    let mock;

    beforeEach(async function () {
        const MockNFTMetadataFreeze = await ethers.getContractFactory("MockNFTMetadataFreeze");
        mock = await MockNFTMetadataFreeze.deploy();
        await mock.waitForDeployment();
    });

    it("Should allow updating before freeze and block after", async function () {
        await mock.setBaseURI("ipfs://before/");
        expect(await mock.baseURI()).to.equal("ipfs://before/");

        await mock.freeze();
        expect(await mock.isMetadataFrozen()).to.equal(true);

        await expect(mock.setBaseURI("ipfs://after/")).to.be.revertedWith("Metadata frozen");
    });

    it("Should not allow freezing twice", async function () {
        await mock.freeze();
        await expect(mock.freeze()).to.be.revertedWith("Metadata already frozen");
    });
});
