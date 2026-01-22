const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTminimint", function () {
  let NFTminimint;
  let nftminimint;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    // Get the ContractFactory and Signers
    NFTminimint = await ethers.getContractFactory("NFTminimint");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Deploy the contract
    nftminimint = await NFTminimint.deploy();
    await nftminimint.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await nftminimint.owner()).to.equal(owner.address);
    });

    it("Should have correct name and symbol", async function () {
      expect(await nftminimint.name()).to.equal("NFTminimint");
      expect(await nftminimint.symbol()).to.equal("NFTM");
    });

    it("Should start with zero total supply", async function () {
      expect(await nftminimint.totalSupply()).to.equal(0);
    });

    it("Should set default mint configuration", async function () {
      expect(await nftminimint.mintFee()).to.equal(ethers.utils.parseEther("0.01"));
      expect(await nftminimint.maxSupply()).to.equal(1024);
      expect(await nftminimint.maxPerWallet()).to.equal(10);
    });
  });

  describe("Minting", function () {
    it("Should mint NFT with correct fee", async function () {
      const mintFee = await nftminimint.mintFee();
      const tokenURI = "https://example.com/token/1";

      await expect(nftminimint.mintNFT(addr1.address, tokenURI, { value: mintFee }))
        .to.emit(nftminimint, "NFTMinted")
        .withArgs(addr1.address, 0, tokenURI);

      expect(await nftminimint.ownerOf(0)).to.equal(addr1.address);
      expect(await nftminimint.totalSupply()).to.equal(1);
      expect(await nftminimint.getTokenURI(0)).to.equal(tokenURI);
    });

    it("Should fail when insufficient fee is sent", async function () {
      const insufficientFee = ethers.utils.parseEther("0.001");
      const tokenURI = "https://example.com/token/1";

      await expect(
        nftminimint.mintNFT(addr1.address, tokenURI, { value: insufficientFee })
      ).to.be.reverted;
    });

    it("Should allow multiple mints with incrementing token IDs", async function () {
      const mintFee = await nftminimint.mintFee();

      // First mint
      await nftminimint.mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee });
      expect(await nftminimint.totalSupply()).to.equal(1);

      // Second mint
      await nftminimint.mintNFT(addr2.address, "https://example.com/token/2", { value: mintFee });
      expect(await nftminimint.totalSupply()).to.equal(2);
      expect(await nftminimint.ownerOf(1)).to.equal(addr2.address);
    });

    it("Should pause and prevent minting", async function () {
      const mintFee = await nftminimint.mintFee();
      await nftminimint.pause();

      await expect(
        nftminimint.mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee })
      ).to.be.reverted;

      await nftminimint.unpause();
      await expect(
        nftminimint.mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee })
      ).to.not.be.reverted;
    });

    it("Should enforce maxPerWallet", async function () {
      const mintFee = await nftminimint.mintFee();
      await nftminimint.setMaxPerWallet(2);

      await nftminimint.connect(addr1).mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee });
      await nftminimint.connect(addr1).mintNFT(addr1.address, "https://example.com/token/2", { value: mintFee });

      await expect(
        nftminimint.connect(addr1).mintNFT(addr1.address, "https://example.com/token/3", { value: mintFee })
      ).to.be.reverted;
    });

    it("Should allow ownerMint without fee", async function () {
      await expect(
        nftminimint.ownerMint(addr1.address, "https://example.com/token/1")
      ).to.emit(nftminimint, "NFTMinted");

      expect(await nftminimint.ownerOf(0)).to.equal(addr1.address);
      expect(await nftminimint.totalSupply()).to.equal(1);
    });
  });

  describe("Token URI", function () {
    it("Should return correct token URI", async function () {
      const mintFee = ethers.utils.parseEther("0.01");
      const tokenURI = "https://example.com/token/123";

      await nftminimint.mintNFT(addr1.address, tokenURI, { value: mintFee });

      expect(await nftminimint.tokenURI(0)).to.equal(tokenURI);
      expect(await nftminimint.getTokenURI(0)).to.equal(tokenURI);
    });

    it("Should revert for non-existent token", async function () {
      await expect(nftminimint.tokenURI(999)).to.be.reverted;
    });
  });

  describe("Withdrawal", function () {
    it("Should allow owner to withdraw contract balance", async function () {
      const mintFee = await nftminimint.mintFee();

      // Mint an NFT to add funds to the contract
      await nftminimint.mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee });

      // Check contract balance
      const contractBalanceBefore = await ethers.provider.getBalance(nftminimint.address);
      expect(contractBalanceBefore).to.equal(mintFee);

      // Withdraw funds
      const ownerBalanceBefore = await owner.getBalance();
      const tx = await nftminimint.withdraw(owner.address);
      await tx.wait();

      // Verify withdrawal
      const contractBalanceAfter = await ethers.provider.getBalance(nftminimint.address);
      const ownerBalanceAfter = await owner.getBalance();

      expect(contractBalanceAfter).to.equal(0);
      expect(ownerBalanceAfter).to.be.gt(ownerBalanceBefore);
    });

    it("Should not allow non-owner to withdraw", async function () {
      await expect(
        nftminimint.connect(addr1).withdraw(addr1.address)
      ).to.be.reverted;
    });

    it("Should revert when no funds to withdraw", async function () {
      await expect(
        nftminimint.withdraw(owner.address)
      ).to.be.reverted;
    });
  });

  describe("Ownership", function () {
    it("Should transfer ownership correctly", async function () {
      await nftminimint.transferOwnership(addr1.address);
      expect(await nftminimint.owner()).to.equal(addr1.address);
    });

    it("Should allow new owner to withdraw", async function () {
      const mintFee = await nftminimint.mintFee();

      // Mint an NFT
      await nftminimint.mintNFT(addr1.address, "https://example.com/token/1", { value: mintFee });

      // Transfer ownership
      await nftminimint.transferOwnership(addr1.address);

      // New owner should be able to withdraw
      await expect(nftminimint.connect(addr1).withdraw(addr1.address)).to.not.be.reverted;
    });
  });

  describe("Interface Support", function () {
    it("Should support ERC721 interface", async function () {
      const ERC721_INTERFACE_ID = "0x80ac58cd";
      expect(await nftminimint.supportsInterface(ERC721_INTERFACE_ID)).to.be.true;
    });

    it("Should support ERC721Metadata interface", async function () {
      const ERC721_METADATA_INTERFACE_ID = "0x5b5e139f";
      expect(await nftminimint.supportsInterface(ERC721_METADATA_INTERFACE_ID)).to.be.true;
    });
  });
});
