const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMintCooldown Extension", function () {
    let mock;
    let owner, alice;

    beforeEach(async function () {
        [owner, alice] = await ethers.getSigners();
        const MockNFTMintCooldown = await ethers.getContractFactory("MockNFTMintCooldown");
        mock = await MockNFTMintCooldown.deploy();
        await mock.waitForDeployment();
    });

    it("Should enforce cooldown between mints", async function () {
        await mock.setCooldown(3600);
        await mock.connect(alice).mint();

        await expect(mock.connect(alice).mint()).to.be.revertedWith("Mint cooldown active");

        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine", []);

        await expect(mock.connect(alice).mint()).to.not.be.reverted;
    });

    it("Should allow unlimited minting when cooldown disabled", async function () {
        await mock.setCooldown(0);
        await mock.connect(alice).mint();
        await mock.connect(alice).mint();
        expect(await mock.totalMinted()).to.equal(2);
    });
});
