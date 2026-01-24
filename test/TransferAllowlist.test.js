const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTTransferAllowlist Extension", function () {
    let nft;
    let owner, alice, bob;

    beforeEach(async function () {
        [owner, alice, bob] = await ethers.getSigners();
        const MockNFTTransferAllowlist = await ethers.getContractFactory("MockNFTTransferAllowlist");
        nft = await MockNFTTransferAllowlist.deploy("Allow", "ALLOW");
        await nft.waitForDeployment();
    });

    it("Should allow transfers when allowlist disabled", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        await nft.setAllowlistEnabled(false);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;
    });

    it("Should restrict transfers to allowlisted recipients", async function () {
        await nft.mint(alice.address);
        const tokenId = 0n;

        await nft.setAllowlistEnabled(true);
        await nft.setRecipientAllowed(bob.address, false);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.be.revertedWith("Recipient not allowed");

        await nft.setRecipientAllowed(bob.address, true);
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, tokenId)
        ).to.not.be.reverted;
    });
});
