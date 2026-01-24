const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Security Tests", function () {
  let nftCore;
  let nftAccess;
  let owner;
  let attacker;
  let user;

  beforeEach(async function () {
    [owner, attacker, user] = await ethers.getSigners();
    
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
    
    const NFTAccess = await ethers.getContractFactory("NFTAccess");
    nftAccess = await NFTAccess.deploy(await nftCore.getAddress());
    await nftAccess.waitForDeployment();
  });

  describe("Access Control", function () {
    it("Should prevent non-owner from authorizing minter", async function () {
      await expect(
        nftCore.connect(attacker).authorizeMinter(attacker.address)
      ).to.be.reverted;
    });

    it("Should prevent non-owner from revoking minter", async function () {
      await nftCore.authorizeMinter(user.address);
      await expect(
        nftCore.connect(attacker).revokeMinter(user.address)
      ).to.be.reverted;
    });

    it("Should prevent unauthorized minting", async function () {
      await expect(
        nftCore.connect(attacker).mint(attacker.address, "ipfs://hack")
      ).to.be.revertedWith("NFTCore: Not authorized minter");
    });

    it("Should prevent non-admin from modifying whitelist", async function () {
      await expect(
        nftAccess.connect(attacker).addToWhitelist(attacker.address)
      ).to.be.revertedWith("NFTAccess: Not admin");
    });
  });

  describe("Zero Address Protection", function () {
    it("Should reject zero address for mint recipient", async function () {
      await expect(
        nftCore.mint(ethers.ZeroAddress, "ipfs://test")
      ).to.be.revertedWith("NFTCore: Zero address");
    });

    it("Should reject zero address for minter authorization", async function () {
      await expect(
        nftCore.authorizeMinter(ethers.ZeroAddress)
      ).to.be.revertedWith("NFTCore: Zero address");
    });

    it("Should reject zero address for whitelist", async function () {
      await expect(
        nftAccess.addToWhitelist(ethers.ZeroAddress)
      ).to.be.revertedWith("NFTAccess: Zero address");
    });
  });

  describe("Pause Functionality", function () {
    it("Should block operations when paused", async function () {
      await nftAccess.pause();
      const [canMint, reason] = await nftAccess.canMint(user.address);
      expect(canMint).to.equal(false);
      expect(reason).to.equal("Minting paused");
    });

    it("Should allow operations when unpaused", async function () {
      await nftAccess.pause();
      await nftAccess.unpause();
      await nftAccess.setPublicMintOpen(true);
      const [canMint] = await nftAccess.canMint(user.address);
      expect(canMint).to.equal(true);
    });

    it("Should prevent non-admin from pausing", async function () {
      await expect(
        nftAccess.connect(attacker).pause()
      ).to.be.revertedWith("NFTAccess: Not admin");
    });
  });

  describe("Batch Operation Limits", function () {
    it("Should reject batch mint over 50", async function () {
      const uris = Array(51).fill("ipfs://test");
      await expect(
        nftCore.batchMint(user.address, uris)
      ).to.be.revertedWith("NFTCore: Max 50 per batch");
    });

    it("Should reject empty batch mint", async function () {
      await expect(
        nftCore.batchMint(user.address, [])
      ).to.be.revertedWith("NFTCore: Empty URIs");
    });
  });
});
