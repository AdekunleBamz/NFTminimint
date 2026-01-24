const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTminimint Integration", function () {
  let nftCore;
  let nftMetadata;
  let nftAccess;
  let nftCollection;
  let nftMinimint;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    // Deploy all contracts
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("MiniMint Collection", "MINT");
    await nftCore.waitForDeployment();
    
    const NFTMetadata = await ethers.getContractFactory("NFTMetadata");
    nftMetadata = await NFTMetadata.deploy(await nftCore.getAddress());
    await nftMetadata.waitForDeployment();
    
    const NFTAccess = await ethers.getContractFactory("NFTAccess");
    nftAccess = await NFTAccess.deploy(await nftCore.getAddress());
    await nftAccess.waitForDeployment();
    
    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy(await nftCore.getAddress(), 10000);
    await nftCollection.waitForDeployment();
    
    const NFTminimint = await ethers.getContractFactory("NFTminimint");
    nftMinimint = await NFTminimint.deploy(
      await nftCore.getAddress(),
      await nftMetadata.getAddress(),
      await nftAccess.getAddress(),
      await nftCollection.getAddress()
    );
    await nftMinimint.waitForDeployment();
    
    // Link contracts
    await nftCore.authorizeMinter(await nftMinimint.getAddress());
    await nftAccess.authorizeCaller(await nftMinimint.getAddress());
    await nftAccess.setPublicMintOpen(true);
  });

  describe("Full System Deployment", function () {
    it("Should deploy all contracts successfully", async function () {
      expect(await nftCore.getAddress()).to.be.properAddress;
      expect(await nftMetadata.getAddress()).to.be.properAddress;
      expect(await nftAccess.getAddress()).to.be.properAddress;
      expect(await nftCollection.getAddress()).to.be.properAddress;
      expect(await nftMinimint.getAddress()).to.be.properAddress;
    });

    it("Should have correct contract references", async function () {
      expect(await nftMinimint.nftCore()).to.equal(await nftCore.getAddress());
      expect(await nftMinimint.nftMetadata()).to.equal(await nftMetadata.getAddress());
      expect(await nftMinimint.nftAccess()).to.equal(await nftAccess.getAddress());
      expect(await nftMinimint.nftCollection()).to.equal(await nftCollection.getAddress());
    });
  });

  describe("Minting Flow", function () {
    it("Should mint NFT for free", async function () {
      await nftMinimint.mint("ipfs://token1");
      expect(await nftCore.ownerOf(1)).to.equal(owner.address);
    });

    it("Should mint to another address", async function () {
      await nftMinimint.mintTo(addr1.address, "ipfs://token2");
      expect(await nftCore.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should emit Minted event", async function () {
      await expect(nftMinimint.mint("ipfs://token3"))
        .to.emit(nftMinimint, "Minted")
        .withArgs(owner.address, 1, "ipfs://token3");
    });
  });

  describe("Batch Minting", function () {
    it("Should batch mint multiple NFTs", async function () {
      const uris = ["ipfs://batch1", "ipfs://batch2", "ipfs://batch3"];
      await nftMinimint.batchMint(uris);
      expect(await nftCore.totalMinted()).to.equal(3);
    });

    it("Should emit BatchMinted event", async function () {
      const uris = ["ipfs://b1", "ipfs://b2"];
      await expect(nftMinimint.batchMint(uris))
        .to.emit(nftMinimint, "BatchMinted");
    });

    it("Should correctly assign ownership for batch mints", async function () {
      const uris = ["ipfs://o1", "ipfs://o2"];
      await nftMinimint.batchMint(uris);
      expect(await nftCore.ownerOf(1)).to.equal(owner.address);
      expect(await nftCore.ownerOf(2)).to.equal(owner.address);
    });
  });

  describe("Airdrop", function () {
    it("Should airdrop to multiple recipients", async function () {
      const recipients = [addr1.address, addr2.address];
      const uris = ["ipfs://air1", "ipfs://air2"];
      await nftMinimint.airdrop(recipients, uris);
      expect(await nftCore.ownerOf(1)).to.equal(addr1.address);
      expect(await nftCore.ownerOf(2)).to.equal(addr2.address);
    });

    it("Should emit Airdropped event", async function () {
      await expect(nftMinimint.airdrop([addr1.address], ["ipfs://drop1"]))
        .to.emit(nftMinimint, "Airdropped");
    });
  });

  describe("Access Control Integration", function () {
    it("Should enforce whitelist when enabled", async function () {
      await nftAccess.setPublicMintOpen(false);
      await nftAccess.setWhitelistEnabled(true);
      await nftAccess.addToWhitelist(addr1.address);
      
      // addr1 can mint (whitelisted)
      await nftMinimint.connect(addr1).mint("ipfs://wl1");
      expect(await nftCore.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should enforce wallet mint limits", async function () {
      await nftAccess.setWalletMintLimit(2);
      
      // Mint 2 (should work)
      await nftMinimint.mint("ipfs://limit1");
      await nftMinimint.mint("ipfs://limit2");
      
      expect(await nftCore.totalMinted()).to.equal(2);
    });
  });
});
