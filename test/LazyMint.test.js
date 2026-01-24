const { expect } = require("chai");
const { ethers } = require("hardhat");

const buildVoucherHash = (tokenId, uri, price, creator) => {
  return ethers.keccak256(
    ethers.solidityPacked(
      ["uint256", "string", "uint256", "address"],
      [tokenId, uri, price, creator]
    )
  );
};

describe("NFTLazyMint Extension", function () {
  let nft;
  let owner;
  let signer;
  let buyer;

  beforeEach(async function () {
    [owner, signer, buyer] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("MockNFTLazyMint");
    nft = await NFT.deploy();
    await nft.waitForDeployment();

    await nft.setVoucherSigner(signer.address);
  });

  it("should verify valid voucher signatures", async function () {
    const voucher = {
      tokenId: 1,
      uri: "ipfs://token-1",
      price: 0,
      creator: signer.address,
      signature: "0x",
    };

    const hash = buildVoucherHash(voucher.tokenId, voucher.uri, voucher.price, voucher.creator);
    voucher.signature = await signer.signMessage(ethers.getBytes(hash));

    expect(await nft.verifyVoucher(voucher)).to.equal(true);
  });

  it("should redeem a voucher and mark it used", async function () {
    const voucher = {
      tokenId: 2,
      uri: "ipfs://token-2",
      price: 100,
      creator: signer.address,
      signature: "0x",
    };

    const hash = buildVoucherHash(voucher.tokenId, voucher.uri, voucher.price, voucher.creator);
    voucher.signature = await signer.signMessage(ethers.getBytes(hash));

    await expect(nft.connect(buyer).redeem(voucher, { value: 100 }))
      .to.emit(nft, "VoucherRedeemed")
      .withArgs(voucher.tokenId, buyer.address, signer.address);

    expect(await nft.owners(voucher.tokenId)).to.equal(buyer.address);
    expect(await nft.isVoucherUsed(hash)).to.equal(true);
  });

  it("should reject invalid signatures", async function () {
    const voucher = {
      tokenId: 3,
      uri: "ipfs://token-3",
      price: 0,
      creator: signer.address,
      signature: "0x",
    };

    const hash = buildVoucherHash(voucher.tokenId, voucher.uri, voucher.price, voucher.creator);
    voucher.signature = await owner.signMessage(ethers.getBytes(hash));

    await expect(nft.connect(buyer).redeem(voucher))
      .to.be.revertedWith("Invalid voucher");
  });

  it("should prevent voucher reuse", async function () {
    const voucher = {
      tokenId: 4,
      uri: "ipfs://token-4",
      price: 0,
      creator: signer.address,
      signature: "0x",
    };

    const hash = buildVoucherHash(voucher.tokenId, voucher.uri, voucher.price, voucher.creator);
    voucher.signature = await signer.signMessage(ethers.getBytes(hash));

    await nft.connect(buyer).redeem(voucher);

    await expect(nft.connect(buyer).redeem(voucher))
      .to.be.revertedWith("Voucher already used");
  });
});
