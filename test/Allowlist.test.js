const { expect } = require("chai");
const { ethers } = require("hardhat");

const hashLeaf = (address) =>
  ethers.keccak256(ethers.solidityPacked(["address"], [address]));

const hashPair = (a, b) => {
  const aBig = BigInt(a);
  const bBig = BigInt(b);
  const [left, right] = aBig <= bBig ? [a, b] : [b, a];
  return ethers.keccak256(
    ethers.solidityPacked(["bytes32", "bytes32"], [left, right])
  );
};

describe("NFTAllowlist Extension", function () {
  let nft;
  let owner;
  let allowlisted;
  let other;
  let root;
  let proofForAllowlisted;

  beforeEach(async function () {
    [owner, allowlisted, other] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTAllowlist");
    nft = await NFT.deploy();
    await nft.waitForDeployment();

    const leaf1 = hashLeaf(allowlisted.address);
    const leaf2 = hashLeaf(other.address);
    root = hashPair(leaf1, leaf2);
    proofForAllowlisted = [leaf2];

    await nft.setMerkleRoot(root);
    await nft.setAllowlistMintEnabled(true);
  });

  it("should allow minting with valid proof", async function () {
    await expect(nft.connect(allowlisted).allowlistMint(proofForAllowlisted, "uri1"))
      .to.emit(nft, "AllowlistClaimed")
      .withArgs(allowlisted.address);

    expect(await nft.balanceOf(allowlisted.address)).to.equal(1);
    expect(await nft.hasClaimedAllowlist(allowlisted.address)).to.equal(true);
  });

  it("should prevent non-allowlisted minting", async function () {
    const invalidProof = [hashLeaf(allowlisted.address)];

    await expect(nft.connect(owner).allowlistMint(invalidProof, "uri1"))
      .to.be.revertedWith("Not on allowlist");
  });

  it("should prevent double claims", async function () {
    await nft.connect(allowlisted).allowlistMint(proofForAllowlisted, "uri1");

    await expect(nft.connect(allowlisted).allowlistMint(proofForAllowlisted, "uri2"))
      .to.be.revertedWith("Already claimed");
  });

  it("should block allowlist minting when disabled", async function () {
    await nft.setAllowlistMintEnabled(false);

    await expect(nft.connect(allowlisted).allowlistMint(proofForAllowlisted, "uri1"))
      .to.be.revertedWith("Allowlist mint disabled");
  });
});
