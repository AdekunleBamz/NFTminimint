const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTProvenance Extension", function () {
  let nft;
  let owner;
  let alice;
  let bob;

  beforeEach(async function () {
    [owner, alice, bob] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTProvenance");
    nft = await NFT.deploy();
    await nft.waitForDeployment();
  });

  it("should record mint provenance", async function () {
    await nft.mintWithProvenance(alice.address, "uri1");

    expect(await nft.getOriginalCreator(0)).to.equal(alice.address);
    expect(await nft.getProvenanceCount(0)).to.equal(1);

    const record = await nft.getProvenanceRecord(0, 0);
    expect(record.from).to.equal(ethers.ZeroAddress);
    expect(record.to).to.equal(alice.address);
    expect(record.eventType).to.equal("mint");
  });

  it("should record transfers and sales", async function () {
    await nft.mintWithProvenance(alice.address, "uri1");

    await nft.recordTransfer(0, alice.address, bob.address);
    await nft.recordSale(0, bob.address, alice.address, 1000);

    expect(await nft.getProvenanceCount(0)).to.equal(3);

    const transferRecord = await nft.getProvenanceRecord(0, 1);
    expect(transferRecord.from).to.equal(alice.address);
    expect(transferRecord.to).to.equal(bob.address);
    expect(transferRecord.eventType).to.equal("transfer");

    const saleRecord = await nft.getProvenanceRecord(0, 2);
    expect(saleRecord.from).to.equal(bob.address);
    expect(saleRecord.to).to.equal(alice.address);
    expect(saleRecord.price).to.equal(1000n);
    expect(saleRecord.eventType).to.equal("sale");
  });

  it("should revert on invalid index", async function () {
    await nft.mintWithProvenance(alice.address, "uri1");

    await expect(nft.getProvenanceRecord(0, 2))
      .to.be.revertedWith("Invalid index");
  });
});
