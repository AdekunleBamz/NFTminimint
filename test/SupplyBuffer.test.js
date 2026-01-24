const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTSupplyBuffer Extension", function () {
    let mock;

    beforeEach(async function () {
        const MockNFTSupplyBuffer = await ethers.getContractFactory("MockNFTSupplyBuffer");
        mock = await MockNFTSupplyBuffer.deploy(10);
        await mock.waitForDeployment();
    });

    it("Should allow minting up to max minus buffer", async function () {
        await mock.setBuffer(2);
        await mock.mint(8);
        expect(await mock.totalSupply()).to.equal(8);

        await expect(mock.mint(1)).to.be.revertedWith("Supply buffer active");
    });

    it("Should allow minting when buffer is zero", async function () {
        await mock.setBuffer(0);
        await mock.mint(10);
        expect(await mock.totalSupply()).to.equal(10);
    });
});
