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
});
