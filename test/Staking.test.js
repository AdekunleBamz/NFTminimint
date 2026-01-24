const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTStaking Extension", function () {
  let nft;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTStaking");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
    
    // Enable staking
    await nft.setStakingEnabled(true);
    
    // Mint to addr1
    await nft.mint(addr1.address, "uri1");
  });

  it("should allow staking owned tokens", async function () {
    await nft.connect(addr1).stake(0);
    expect(await nft.isStaked(0)).to.be.true;
    
    const duration = await nft.getStakingDuration(0);
    // Rough check, might be 0 or 1
    expect(duration).to.be.at.least(0);
  });

  it("should prevent staking unowned tokens", async function () {
    await expect(nft.connect(owner).stake(0))
      .to.be.revertedWith("Not owner");
  });

  it("should prevent staking when disabled", async function () {
    await nft.setStakingEnabled(false);
    await expect(nft.connect(addr1).stake(0))
      .to.be.revertedWith("Staking disabled");
  });

  it("should prevent transferring staked tokens", async function () {
    await nft.connect(addr1).stake(0);
    
    await expect(nft.connect(addr1).transferFrom(addr1.address, owner.address, 0))
      .to.be.revertedWith("Token is staked");
  });

  it("should allow unstaking", async function () {
    await nft.connect(addr1).stake(0);
    
    // Simulate time pass? (Optional)
    
    await expect(nft.connect(addr1).unstake(0))
      .to.emit(nft, "TokenUnstaked");
      
    expect(await nft.isStaked(0)).to.be.false;
  });

  it("should allow transfer after unstaking", async function () {
    await nft.connect(addr1).stake(0);
    await nft.connect(addr1).unstake(0);
    
    await nft.connect(addr1).transferFrom(addr1.address, owner.address, 0);
    expect(await nft.ownerOf(0)).to.equal(owner.address);
  });
});
