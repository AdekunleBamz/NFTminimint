const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTWalletCap Extension", function () {
    let mock;
    let owner, alice;

    beforeEach(async function () {
        [owner, alice] = await ethers.getSigners();
        const MockNFTWalletCap = await ethers.getContractFactory("MockNFTWalletCap");
        mock = await MockNFTWalletCap.deploy();
        await mock.waitForDeployment();
    });

    it("Should allow unlimited when max is zero", async function () {
        await mock.setMaxPerWallet(0);
        await mock.mint(alice.address, 100);
        expect(await mock.balanceOf(alice.address)).to.equal(100);
    });

    it("Should enforce wallet cap", async function () {
        await mock.setMaxPerWallet(3);
        await mock.mint(alice.address, 2);
        await expect(mock.mint(alice.address, 2)).to.be.revertedWith("Wallet cap exceeded");
        await mock.mint(alice.address, 1);
        expect(await mock.balanceOf(alice.address)).to.equal(3);
    });
});
