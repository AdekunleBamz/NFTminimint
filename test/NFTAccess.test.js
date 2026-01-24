const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAccess", function () {
  let nftCore;
  let nftAccess;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    // Deploy NFTCore first
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
    
    // Deploy NFTAccess
    const NFTAccess = await ethers.getContractFactory("NFTAccess");
    nftAccess = await NFTAccess.deploy(await nftCore.getAddress());
    await nftAccess.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct NFTCore reference", async function () {
      expect(await nftAccess.nftCore()).to.equal(await nftCore.getAddress());
    });

    it("Should set deployer as admin", async function () {
      expect(await nftAccess.admins(owner.address)).to.equal(true);
    });

    it("Should start with public mint closed", async function () {
      expect(await nftAccess.publicMintOpen()).to.equal(false);
    });

    it("Should start with whitelist disabled", async function () {
      expect(await nftAccess.whitelistEnabled()).to.equal(false);
    });
  });

  describe("Whitelist", function () {
    it("Should add address to whitelist", async function () {
      await nftAccess.addToWhitelist(addr1.address);
      expect(await nftAccess.whitelist(addr1.address)).to.equal(true);
      expect(await nftAccess.whitelistCount()).to.equal(1);
    });

    it("Should remove address from whitelist", async function () {
      await nftAccess.addToWhitelist(addr1.address);
      await nftAccess.removeFromWhitelist(addr1.address);
      expect(await nftAccess.whitelist(addr1.address)).to.equal(false);
      expect(await nftAccess.whitelistCount()).to.equal(0);
    });

    it("Should batch add to whitelist", async function () {
      await nftAccess.batchAddToWhitelist([addr1.address, addr2.address]);
      expect(await nftAccess.whitelistCount()).to.equal(2);
    });
  });
});
