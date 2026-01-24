const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTSoulbound Extension", function () {
    let nft;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();

        const MockNFTSoulbound = await ethers.getContractFactory("MockNFTSoulbound");
        nft = await MockNFTSoulbound.deploy("Soul", "SOUL");
        await nft.waitForDeployment();
    });

    it("Should block transfers when token is soulbound", async function () {
        await nft.connect(owner).mint(alice.address);
        const tokenId = 0n;
        await nft.setTokenSoulbound(tokenId, true);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.be.revertedWith("Token is soulbound");

        await nft.setTokenSoulbound(tokenId, false);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;

        expect(await nft.ownerOf(tokenId)).to.equal(bob.address);
    });

    it("Should block all transfers when global soulbound enabled", async function () {
        await nft.mint(alice.address);
        await nft.mint(alice.address);
        const tokenId1 = 0n;
        const tokenId2 = 1n;

        await nft.setGlobalSoulbound(true);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId1)
        ).to.be.revertedWith("Token is soulbound");

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId2)
        ).to.be.revertedWith("Token is soulbound");

        await nft.setGlobalSoulbound(false);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId1)
        ).to.not.be.reverted;
    });
});
