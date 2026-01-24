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
});
