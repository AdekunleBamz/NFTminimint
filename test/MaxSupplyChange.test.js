const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMaxSupplyChange Extension", function () {
    let mock;

    beforeEach(async function () {
        const MockNFTMaxSupplyChange = await ethers.getContractFactory("MockNFTMaxSupplyChange");
        mock = await MockNFTMaxSupplyChange.deploy(100);
        await mock.waitForDeployment();
    });

    it("Should allow reducing max supply", async function () {
        expect(await mock.maxSupply()).to.equal(100);
        await mock.reduceMaxSupply(50);
        expect(await mock.maxSupply()).to.equal(50);
    });

    it("Should not allow increasing max supply", async function () {
        await expect(mock.reduceMaxSupply(101)).to.be.revertedWith("Can only reduce max supply");
    });

    it("Should not allow reducing below total supply", async function () {
        await mock.mint(20);
        await expect(mock.reduceMaxSupply(10)).to.be.revertedWith("New max < total supply");
        await expect(mock.reduceMaxSupply(20)).to.not.be.reverted;
        expect(await mock.maxSupply()).to.equal(20);
    });
});
