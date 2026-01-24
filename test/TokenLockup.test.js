const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTTokenLockup Extension", function () {
    let nft;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();
        const MockNFTTokenLockup = await ethers.getContractFactory("MockNFTTokenLockup");
        nft = await MockNFTTokenLockup.deploy("Lockup", "LOCK");
        await nft.waitForDeployment();
    });

    it("Should block transfers while locked", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        const now = (await ethers.provider.getBlock("latest")).timestamp;
        await nft.lockToken(tokenId, now + 3600);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.be.revertedWith("Token locked");

        await ethers.provider.send("evm_increaseTime", [3600]);
        await ethers.provider.send("evm_mine", []);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;
    });

    it("Should allow unlock before transfer", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        const now = (await ethers.provider.getBlock("latest")).timestamp;
        await nft.lockToken(tokenId, now + 3600);

        await nft.unlockToken(tokenId);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;
    });
});
