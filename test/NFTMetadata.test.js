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
});
