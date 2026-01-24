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
});
