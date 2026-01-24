const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTEnumerable Extension", function () {
  let nft;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTEnumerable");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should support ERC721Enumerable interface", async function () {
    const interfaceId = "0x780e9d63"; // ERC721Enumerable
    expect(await nft.supportsInterface(interfaceId)).to.be.true;
  });

  it("should track tokens by index", async function () {
    await nft.mint(owner.address, "uri1");
    await nft.mint(addr1.address, "uri2");
    
    // Total supply should be 2
    expect(await nft.totalSupply()).to.equal(2);
    
    // Token at index 0 should be 0 (ids start at 0)
    expect(await nft.tokenByIndex(0)).to.equal(0);
    expect(await nft.tokenByIndex(1)).to.equal(1);
  });

  it("should track tokens of owner by index", async function () {
    await nft.mint(owner.address, "uri1");
    await nft.mint(owner.address, "uri2");
    await nft.mint(addr1.address, "uri3");
    
    expect(await nft.balanceOf(owner.address)).to.equal(2);
    expect(await nft.tokenOfOwnerByIndex(owner.address, 0)).to.equal(0);
    expect(await nft.tokenOfOwnerByIndex(owner.address, 1)).to.equal(1);
    
    expect(await nft.balanceOf(addr1.address)).to.equal(1);
    expect(await nft.tokenOfOwnerByIndex(addr1.address, 0)).to.equal(2);
  });
});
