const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRoyalty Extension", function () {
  let nft;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTRoyalty");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should support ERC2981 interface", async function () {
    const interfaceId = "0x2a55205a"; // ERC2981
    expect(await nft.supportsInterface(interfaceId)).to.be.true;
  });

  it("should set default royalty", async function () {
    const feeNumerator = 500; // 5%
    await nft.setDefaultRoyalty(addr1.address, feeNumerator);

    const [receiver, royaltyAmount] = await nft.royaltyInfo(1, 10000);
    expect(receiver).to.equal(addr1.address);
    expect(royaltyAmount).to.equal(500);
  });

  it("should set token specific royalty", async function () {
    await nft.mint(owner.address); // Mint token 1
    
    // Default 5%
    await nft.setDefaultRoyalty(addr1.address, 500);
    
    // Token 1 custom 10%
    await nft.setTokenRoyalty(1, addr2.address, 1000);
    
    // Check token 1
    const [receiver1, amount1] = await nft.royaltyInfo(1, 10000);
    expect(receiver1).to.equal(addr2.address);
    expect(amount1).to.equal(1000);
    
    // Check hypothetical token 2 (uses default)
    const [receiver2, amount2] = await nft.royaltyInfo(2, 10000);
    expect(receiver2).to.equal(addr1.address);
    expect(amount2).to.equal(500);
  });
  
  it("should update default royalty", async function () {
      await nft.setDefaultRoyalty(addr1.address, 500);
      let [receiver, amount] = await nft.royaltyInfo(1, 10000);
      expect(amount).to.equal(500);
      
      await nft.setDefaultRoyalty(addr1.address, 1000); // 10%
      [receiver, amount] = await nft.royaltyInfo(1, 10000);
      expect(amount).to.equal(1000);
  });
});
