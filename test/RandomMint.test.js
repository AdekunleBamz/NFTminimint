const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRandomMint Extension", function () {
  let nft;
  let owner;
  let alice;

  const getMintedTokenId = async (tx, contract) => {
    const receipt = await tx.wait();
    const event = receipt.logs
      .map((log) => {
        try {
          return contract.interface.parseLog(log);
        } catch {
          return null;
        }
      })
      .find((parsed) => parsed && parsed.name === "Transfer");

    return event.args.tokenId;
  };

  beforeEach(async function () {
    [owner, alice] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTRandomMint");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should initialize random mint", async function () {
    await nft.initializeRandomMint(3);

    expect(await nft.randomMintMaxSupply()).to.equal(3);
    expect(await nft.remainingTokens()).to.equal(3);
  });

  it("should mint random token IDs and decrement remaining", async function () {
    await nft.initializeRandomMint(3);

    const tx1 = await nft.randomMint(alice.address, 1);
    const id1 = await getMintedTokenId(tx1, nft);

    const tx2 = await nft.randomMint(alice.address, 2);
    const id2 = await getMintedTokenId(tx2, nft);

    expect(id1).to.not.equal(id2);
    expect(await nft.remainingTokens()).to.equal(1);
  });

  it("should revert when no tokens remain", async function () {
    await nft.initializeRandomMint(1);

    await nft.randomMint(alice.address, 1);

    await expect(nft.randomMint(alice.address, 2))
      .to.be.revertedWith("No tokens remaining");
  });
});
