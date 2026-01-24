const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTBlacklist Extension", function () {
    let nft;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();
        const MockNFTBlacklist = await ethers.getContractFactory("MockNFTBlacklist");
        nft = await MockNFTBlacklist.deploy("Black", "BLK");
        await nft.waitForDeployment();
    });

    it("Should block minting to blacklisted addresses", async function () {
        await nft.setBlacklisted(alice.address, true);
        await expect(nft.mint(alice.address)).to.be.revertedWith("Address blacklisted");

        await nft.setBlacklisted(alice.address, false);
        await expect(nft.mint(alice.address)).to.not.be.reverted;
    });

    it("Should block transfers to blacklisted addresses", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        await nft.setBlacklisted(bob.address, true);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.be.revertedWith("Address blacklisted");

        await nft.setBlacklisted(bob.address, false);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;
    });
});
