const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTFreeMint Extension", function () {
  let nft;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTFreeMint");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should prevent free mint when disabled", async function () {
    await nft.setFreeMintAccess(addr1.address, true);
    await expect(nft.connect(addr1).freeMint(1))
      .to.be.revertedWith("Free minting disabled");
  });

  it("should prevent unauthorized users from free minting", async function () {
    await nft.setFreeMintEnabled(true);
    await expect(nft.connect(addr1).freeMint(1))
      .to.be.revertedWith("Not eligible for free mint");
  });

  it("should allow eligible users to free mint", async function () {
    await nft.setFreeMintEnabled(true);
    await nft.setFreeMintAccess(addr1.address, true);
    
    await expect(nft.connect(addr1).freeMint(1))
        .to.emit(nft, "FreeMintClaimed")
        .withArgs(addr1.address, 1);
        
    expect(await nft.balanceOf(addr1.address)).to.equal(1);
  });

  it("should enforce max free mint limit", async function () {
    await nft.setFreeMintEnabled(true);
    await nft.setFreeMintAccess(addr1.address, true);
    
    await nft.connect(addr1).freeMint(1);
    
    await expect(nft.connect(addr1).freeMint(1))
      .to.be.revertedWith("Free mint limit exceeded");
  });
});
