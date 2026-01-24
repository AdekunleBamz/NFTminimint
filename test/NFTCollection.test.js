const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCollection", function () {
  let nftCore;
  let nftCollection;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    // Deploy NFTCore first
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
    
    // Deploy NFTCollection with max supply of 1000
    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy(await nftCore.getAddress(), 1000);
    await nftCollection.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct NFTCore reference", async function () {
      expect(await nftCollection.nftCore()).to.equal(await nftCore.getAddress());
    });

    it("Should set the correct max supply", async function () {
      expect(await nftCollection.maxSupply()).to.equal(1000);
    });

    it("Should set deployer as owner", async function () {
      expect(await nftCollection.owner()).to.equal(owner.address);
    });
  });

  describe("Max Supply", function () {
    it("Should update max supply", async function () {
      await nftCollection.setMaxSupply(2000);
      expect(await nftCollection.maxSupply()).to.equal(2000);
    });

    it("Should emit MaxSupplyUpdated event", async function () {
      await expect(nftCollection.setMaxSupply(5000))
        .to.emit(nftCollection, "MaxSupplyUpdated")
        .withArgs(5000);
    });
  });

  describe("Royalties", function () {
    it("Should set default royalty", async function () {
      await nftCollection.setDefaultRoyalty(owner.address, 500); // 5%
      const [receiver, amount] = await nftCollection.royaltyInfo(1, 10000);
      expect(receiver).to.equal(owner.address);
      expect(amount).to.equal(500);
    });

    it("Should emit DefaultRoyaltySet event", async function () {
      await expect(nftCollection.setDefaultRoyalty(owner.address, 500))
        .to.emit(nftCollection, "DefaultRoyaltySet")
        .withArgs(owner.address, 500);
    });

    it("Should set token-specific royalty", async function () {
      await nftCore.mint(owner.address, "ipfs://test");
      await nftCollection.setTokenRoyalty(1, addr1.address, 1000); // 10%
      const [receiver, amount] = await nftCollection.royaltyInfo(1, 10000);
      expect(receiver).to.equal(addr1.address);
      expect(amount).to.equal(1000);
    });

    it("Should emit TokenRoyaltySet event", async function () {
      await nftCore.mint(owner.address, "ipfs://test");
      await expect(nftCollection.setTokenRoyalty(1, addr1.address, 750))
        .to.emit(nftCollection, "TokenRoyaltySet")
        .withArgs(1, addr1.address, 750);
    });

    it("Should get royalty info helper", async function () {
      await nftCollection.setDefaultRoyalty(owner.address, 250);
      const info = await nftCollection.getRoyaltyInfo(1, 10000);
      expect(info.receiver).to.equal(owner.address);
      expect(info.amount).to.equal(250);
    });
  });
});
