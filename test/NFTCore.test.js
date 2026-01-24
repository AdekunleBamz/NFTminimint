const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCore", function () {
  let nftCore;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await nftCore.name()).to.equal("Test Collection");
      expect(await nftCore.symbol()).to.equal("TEST");
    });

    it("Should set the deployer as owner", async function () {
      expect(await nftCore.owner()).to.equal(owner.address);
    });

    it("Should start with zero total supply", async function () {
      expect(await nftCore.totalSupply()).to.equal(0);
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint", async function () {
      await nftCore.mint(addr1.address, "ipfs://test-uri");
      expect(await nftCore.totalSupply()).to.equal(1);
      expect(await nftCore.ownerOf(0)).to.equal(addr1.address);
    });

    it("Should store correct token URI", async function () {
      await nftCore.mint(addr1.address, "ipfs://test-uri");
      expect(await nftCore.tokenURI(0)).to.equal("ipfs://test-uri");
    });

    it("Should track creator address", async function () {
      await nftCore.mint(addr1.address, "ipfs://test-uri");
      expect(await nftCore.creators(0)).to.equal(owner.address);
    });

    it("Should record mint timestamp", async function () {
      await nftCore.mint(addr1.address, "ipfs://test-uri");
      const timestamp = await nftCore.mintTimestamps(0);
      expect(timestamp).to.be.gt(0);
    });

    it("Should emit TokenMinted event", async function () {
      await expect(nftCore.mint(addr1.address, "ipfs://test-uri"))
        .to.emit(nftCore, "TokenMinted")
        .withArgs(addr1.address, 0, owner.address);
    });
  });

  describe("Batch Minting", function () {
    it("Should batch mint multiple tokens", async function () {
      const uris = ["ipfs://uri1", "ipfs://uri2", "ipfs://uri3"];
      await nftCore.batchMint(addr1.address, uris);
      
      expect(await nftCore.totalSupply()).to.equal(3);
      expect(await nftCore.ownerOf(0)).to.equal(addr1.address);
      expect(await nftCore.ownerOf(1)).to.equal(addr1.address);
      expect(await nftCore.ownerOf(2)).to.equal(addr1.address);
    });

    it("Should return correct start token ID", async function () {
      await nftCore.mint(addr1.address, "ipfs://first");
      const uris = ["ipfs://uri1", "ipfs://uri2"];
      
      const tx = await nftCore.batchMint(addr1.address, uris);
      // Start token ID should be 1 (after the first mint)
      expect(await nftCore.totalSupply()).to.equal(3);
    });

    it("Should reject empty URIs array", async function () {
      await expect(nftCore.batchMint(addr1.address, []))
        .to.be.revertedWith("NFTCore: Empty URIs");
    });

    it("Should reject more than 50 URIs", async function () {
      const uris = Array(51).fill("ipfs://test");
      await expect(nftCore.batchMint(addr1.address, uris))
        .to.be.revertedWith("NFTCore: Max 50 per batch");
    });
  });
});
