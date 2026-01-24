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

    it("Should emit AddedToWhitelist event", async function () {
      await expect(nftAccess.addToWhitelist(addr1.address))
        .to.emit(nftAccess, "AddedToWhitelist")
        .withArgs(addr1.address);
    });

    it("Should emit RemovedFromWhitelist event", async function () {
      await nftAccess.addToWhitelist(addr1.address);
      await expect(nftAccess.removeFromWhitelist(addr1.address))
        .to.emit(nftAccess, "RemovedFromWhitelist")
        .withArgs(addr1.address);
    });
  });

  describe("Mint Limits", function () {
    it("Should set wallet mint limit", async function () {
      await nftAccess.setWalletMintLimit(5);
      expect(await nftAccess.walletMintLimit()).to.equal(5);
    });

    it("Should emit WalletMintLimitUpdated event", async function () {
      await expect(nftAccess.setWalletMintLimit(10))
        .to.emit(nftAccess, "WalletMintLimitUpdated")
        .withArgs(10);
    });

    it("Should track mints per wallet", async function () {
      await nftAccess.setWalletMintLimit(5);
      await nftAccess.recordMint(addr1.address, 2);
      expect(await nftAccess.mintedPerWallet(addr1.address)).to.equal(2);
    });
  });

  describe("Public Mint", function () {
    it("Should open public mint", async function () {
      await nftAccess.setPublicMintOpen(true);
      expect(await nftAccess.publicMintOpen()).to.equal(true);
    });

    it("Should close public mint", async function () {
      await nftAccess.setPublicMintOpen(true);
      await nftAccess.setPublicMintOpen(false);
      expect(await nftAccess.publicMintOpen()).to.equal(false);
    });

    it("Should emit PublicMintStatusChanged event", async function () {
      await expect(nftAccess.setPublicMintOpen(true))
        .to.emit(nftAccess, "PublicMintStatusChanged")
        .withArgs(true);
    });
  });

  describe("Admin Management", function () {
    it("Should add admin", async function () {
      await nftAccess.setAdmin(addr1.address, true);
      expect(await nftAccess.admins(addr1.address)).to.equal(true);
    });

    it("Should remove admin", async function () {
      await nftAccess.setAdmin(addr1.address, true);
      await nftAccess.setAdmin(addr1.address, false);
      expect(await nftAccess.admins(addr1.address)).to.equal(false);
    });

    it("Should emit AdminUpdated event", async function () {
      await expect(nftAccess.setAdmin(addr1.address, true))
        .to.emit(nftAccess, "AdminUpdated")
        .withArgs(addr1.address, true);
    });

    it("Should check if address is admin", async function () {
      expect(await nftAccess.isAdmin(owner.address)).to.equal(true);
      expect(await nftAccess.isAdmin(addr1.address)).to.equal(false);
    });
  });

  describe("Pause Functionality", function () {
    it("Should pause the contract", async function () {
      await nftAccess.pause();
      expect(await nftAccess.paused()).to.equal(true);
    });

    it("Should unpause the contract", async function () {
      await nftAccess.pause();
      await nftAccess.unpause();
      expect(await nftAccess.paused()).to.equal(false);
    });

    it("Should block minting when paused", async function () {
      await nftAccess.pause();
      const [canMint, reason] = await nftAccess.canMint(addr1.address);
      expect(canMint).to.equal(false);
      expect(reason).to.equal("Minting paused");
    });
  });

  describe("Caller Authorization", function () {
    it("Should authorize a caller", async function () {
      await nftAccess.authorizeCaller(addr1.address);
      expect(await nftAccess.authorizedCallers(addr1.address)).to.equal(true);
    });

    it("Should revoke caller authorization", async function () {
      await nftAccess.authorizeCaller(addr1.address);
      await nftAccess.revokeCaller(addr1.address);
      expect(await nftAccess.authorizedCallers(addr1.address)).to.equal(false);
    });

    it("Should emit AuthorizedCallerUpdated event", async function () {
      await expect(nftAccess.authorizeCaller(addr1.address))
        .to.emit(nftAccess, "AuthorizedCallerUpdated")
        .withArgs(addr1.address, true);
    });
  });
});
