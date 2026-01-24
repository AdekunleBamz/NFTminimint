const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMetadata", function () {
  let nftCore;
  let nftMetadata;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    // Deploy NFTCore first
    const NFTCore = await ethers.getContractFactory("NFTCore");
    nftCore = await NFTCore.deploy("Test Collection", "TEST");
    await nftCore.waitForDeployment();
    
    // Deploy NFTMetadata
    const NFTMetadata = await ethers.getContractFactory("NFTMetadata");
    nftMetadata = await NFTMetadata.deploy(await nftCore.getAddress());
    await nftMetadata.waitForDeployment();
    
    // Mint a token for testing
    await nftCore.mint(owner.address, "ipfs://test");
  });

  describe("Deployment", function () {
    it("Should set the correct NFTCore reference", async function () {
      expect(await nftMetadata.nftCore()).to.equal(await nftCore.getAddress());
    });

    it("Should set deployer as owner", async function () {
      expect(await nftMetadata.owner()).to.equal(owner.address);
    });

    it("Should start with metadata not frozen", async function () {
      expect(await nftMetadata.metadataFrozen()).to.equal(false);
    });
  });

  describe("Contract URI", function () {
    it("Should set contract URI", async function () {
      await nftMetadata.setContractURI("ipfs://contract-metadata");
      expect(await nftMetadata.contractURI()).to.equal("ipfs://contract-metadata");
    });

    it("Should emit ContractURIUpdated event", async function () {
      await expect(nftMetadata.setContractURI("ipfs://new-uri"))
        .to.emit(nftMetadata, "ContractURIUpdated")
        .withArgs("ipfs://new-uri");
    });
  });

  describe("Token Attributes", function () {
    it("Should set token attribute", async function () {
      await nftMetadata.setAttribute(1, "color", "blue");
      expect(await nftMetadata.getAttribute(1, "color")).to.equal("blue");
    });

    it("Should emit AttributeSet event", async function () {
      await expect(nftMetadata.setAttribute(1, "rarity", "legendary"))
        .to.emit(nftMetadata, "AttributeSet")
        .withArgs(1, "rarity", "legendary");
    });

    it("Should get all attribute keys for token", async function () {
      await nftMetadata.setAttribute(1, "color", "blue");
      await nftMetadata.setAttribute(1, "size", "large");
      const keys = await nftMetadata.getAttributeKeys(1);
      expect(keys.length).to.equal(2);
    });
  });

  describe("Metadata Freezing", function () {
    it("Should freeze global metadata", async function () {
      await nftMetadata.freezeMetadata();
      expect(await nftMetadata.metadataFrozen()).to.equal(true);
    });

    it("Should emit MetadataFrozen event", async function () {
      await expect(nftMetadata.freezeMetadata())
        .to.emit(nftMetadata, "MetadataFrozen");
    });

    it("Should freeze individual token metadata", async function () {
      await nftMetadata.freezeTokenMetadata(1);
      expect(await nftMetadata.tokenMetadataFrozen(1)).to.equal(true);
    });

    it("Should emit TokenMetadataFrozen event", async function () {
      await expect(nftMetadata.freezeTokenMetadata(1))
        .to.emit(nftMetadata, "TokenMetadataFrozen")
        .withArgs(1);
    });
  });

  describe("Attribute Removal", function () {
    it("Should remove attribute", async function () {
      await nftMetadata.setAttribute(1, "color", "blue");
      await nftMetadata.removeAttribute(1, "color");
      expect(await nftMetadata.getAttribute(1, "color")).to.equal("");
    });

    it("Should emit AttributeRemoved event", async function () {
      await nftMetadata.setAttribute(1, "size", "large");
      await expect(nftMetadata.removeAttribute(1, "size"))
        .to.emit(nftMetadata, "AttributeRemoved")
        .withArgs(1, "size");
    });
  });
});
