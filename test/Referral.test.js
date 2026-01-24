const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTReferral Extension", function () {
  let nft;
  let owner;
  let referrer;
  let referee;

  beforeEach(async function () {
    [owner, referrer, referee] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTReferral");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should record referral and reward", async function () {
    await nft.mintWithReferral(referee.address, "uri1", referrer.address);

    expect(await nft.referralCount(referrer.address)).to.equal(1);
    expect(await nft.referralRewards(referrer.address)).to.equal(10);
  });

  it("should not record self-referral", async function () {
    await nft.mintWithReferral(referrer.address, "uri1", referrer.address);

    expect(await nft.referralCount(referrer.address)).to.equal(0);
    expect(await nft.referralRewards(referrer.address)).to.equal(0);
  });

  it("should allow claiming rewards", async function () {
    await nft.mintWithReferral(referee.address, "uri1", referrer.address);

    await expect(nft.connect(referrer).claimReward(5))
      .to.emit(nft, "ReferralRewardClaimed")
      .withArgs(referrer.address, 5);

    expect(await nft.referralRewards(referrer.address)).to.equal(5);
  });

  it("should prevent over-claiming rewards", async function () {
    await nft.mintWithReferral(referee.address, "uri1", referrer.address);

    await expect(nft.connect(referrer).claimReward(20))
      .to.be.revertedWith("Insufficient rewards");
  });
});
