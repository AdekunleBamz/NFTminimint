const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTTransferCooldown Extension", function () {
    let nft;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();
        const MockNFTTransferCooldown = await ethers.getContractFactory("MockNFTTransferCooldown");
        nft = await MockNFTTransferCooldown.deploy("Cooldown", "CD");
        await nft.waitForDeployment();
    });

    it("Should enforce cooldown between transfers", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        await nft.setCooldown(3600);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;

        await expect(
            nft.connect(bob).transferFrom(bob.address, alice.address, tokenId)
        ).to.be.revertedWith("Cooldown active");

        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine", []);

        await expect(
            nft.connect(bob).transferFrom(bob.address, alice.address, tokenId)
        ).to.not.be.reverted;
    });

    it("Should allow transfers when cooldown disabled", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        await nft.setCooldown(0);

        await nft.connect(alice).transferFrom(alice.address, bob.address, tokenId);
        await expect(
            nft.connect(bob).transferFrom(bob.address, alice.address, tokenId)
        ).to.not.be.reverted;
    });
});
