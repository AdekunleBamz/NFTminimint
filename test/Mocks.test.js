const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Mock Contracts", function () {
    let mockCore, mockAccess, mockMetadata, mockCollection;
    let owner, minter, user1, user2;
    
    before(async function () {
        [owner, minter, user1, user2] = await ethers.getSigners();
    });
    
    describe("MockNFTCore", function () {
        beforeEach(async function () {
            const MockNFTCore = await ethers.getContractFactory("MockNFTCore");
            mockCore = await MockNFTCore.deploy("MockNFT", "MNFT");
        });
        
        it("Should deploy with correct name and symbol", async function () {
            expect(await mockCore.name()).to.equal("MockNFT");
            expect(await mockCore.symbol()).to.equal("MNFT");
        });
        
        it("Should authorize minter", async function () {
            await mockCore.authorizeMinter(minter.address);
            // Minter should now be able to mint
            await mockCore.connect(minter).mintTo(user1.address, "ipfs://test");
            expect(await mockCore.totalSupply()).to.equal(1);
        });
        
        it("Should reject unauthorized minting", async function () {
            await expect(
                mockCore.connect(user1).mintTo(user1.address, "ipfs://test")
            ).to.be.revertedWith("Not authorized");
        });
        
        it("Should mint and assign token correctly", async function () {
            await mockCore.authorizeMinter(owner.address);
            await mockCore.mintTo(user1.address, "ipfs://metadata/1");
            
            expect(await mockCore.ownerOf(1)).to.equal(user1.address);
            expect(await mockCore.balanceOf(user1.address)).to.equal(1);
            expect(await mockCore.tokenURI(1)).to.equal("ipfs://metadata/1");
        });
        
        it("Should transfer token correctly", async function () {
            await mockCore.authorizeMinter(owner.address);
            await mockCore.mintTo(user1.address, "ipfs://test");
            
            await mockCore.connect(user1).transferFrom(user1.address, user2.address, 1);
            
            expect(await mockCore.ownerOf(1)).to.equal(user2.address);
            expect(await mockCore.balanceOf(user1.address)).to.equal(0);
            expect(await mockCore.balanceOf(user2.address)).to.equal(1);
        });
    });
    
    describe("MockNFTAccess", function () {
        beforeEach(async function () {
            const MockNFTAccess = await ethers.getContractFactory("MockNFTAccess");
            mockAccess = await MockNFTAccess.deploy();
        });
        
        it("Should manage public mint status", async function () {
            expect(await mockAccess.isPublicMintOpen()).to.be.false;
            
            await mockAccess.setPublicMintOpen(true);
            expect(await mockAccess.isPublicMintOpen()).to.be.true;
        });
        
        it("Should manage whitelist", async function () {
            expect(await mockAccess.isWhitelisted(user1.address)).to.be.false;
            
            await mockAccess.addToWhitelist(user1.address);
            expect(await mockAccess.isWhitelisted(user1.address)).to.be.true;
            
            await mockAccess.removeFromWhitelist(user1.address);
            expect(await mockAccess.isWhitelisted(user1.address)).to.be.false;
        });
        
        it("Should track mints per wallet", async function () {
            await mockAccess.authorizeCaller(minter.address);
            
            await mockAccess.connect(minter).recordMint(user1.address, 3);
            expect(await mockAccess.mintedPerWallet(user1.address)).to.equal(3);
            
            await mockAccess.connect(minter).recordMint(user1.address, 2);
            expect(await mockAccess.mintedPerWallet(user1.address)).to.equal(5);
        });
        
        it("Should check canMint correctly", async function () {
            await mockAccess.setPublicMintOpen(true);
            
            expect(await mockAccess.canMint(user1.address, 1)).to.be.true;
            expect(await mockAccess.canMint(user1.address, 11)).to.be.false; // Exceeds limit
        });
        
        it("Should pause minting", async function () {
            await mockAccess.setPublicMintOpen(true);
            expect(await mockAccess.canMint(user1.address, 1)).to.be.true;
            
            await mockAccess.setPaused(true);
            expect(await mockAccess.canMint(user1.address, 1)).to.be.false;
        });
    });
    
    describe("MockNFTMetadata", function () {
        beforeEach(async function () {
            const MockNFTMetadata = await ethers.getContractFactory("MockNFTMetadata");
            mockMetadata = await MockNFTMetadata.deploy();
        });
        
        it("Should set contract URI", async function () {
            await mockMetadata.setContractURI("ipfs://contract-metadata");
            expect(await mockMetadata.contractURI()).to.equal("ipfs://contract-metadata");
        });
        
        it("Should set and get attributes", async function () {
            await mockMetadata.authorizeCaller(owner.address);
            
            await mockMetadata.setAttribute(1, "color", "blue");
            expect(await mockMetadata.getAttribute(1, "color")).to.equal("blue");
        });
        
        it("Should freeze metadata", async function () {
            await mockMetadata.authorizeCaller(owner.address);
            
            await mockMetadata.setAttribute(1, "rarity", "legendary");
            await mockMetadata.freezeMetadata(1);
            
            expect(await mockMetadata.isMetadataFrozen(1)).to.be.true;
            
            await expect(
                mockMetadata.setAttribute(1, "rarity", "common")
            ).to.be.revertedWith("Metadata frozen");
        });
        
        it("Should get all attributes", async function () {
            await mockMetadata.authorizeCaller(owner.address);
            
            await mockMetadata.setAttribute(1, "color", "red");
            await mockMetadata.setAttribute(1, "size", "large");
            
            const [keys, values] = await mockMetadata.getAllAttributes(1);
            expect(keys.length).to.equal(2);
            expect(keys).to.include("color");
            expect(keys).to.include("size");
        });
    });
    
    describe("MockNFTCollection", function () {
        beforeEach(async function () {
            const MockNFTCollection = await ethers.getContractFactory("MockNFTCollection");
            mockCollection = await MockNFTCollection.deploy(10000);
        });
        
        it("Should initialize with max supply", async function () {
            expect(await mockCollection.maxSupply()).to.equal(10000);
            expect(await mockCollection.currentSupply()).to.equal(0);
        });
        
        it("Should track supply correctly", async function () {
            await mockCollection.authorizeCaller(owner.address);
            
            await mockCollection.incrementSupply(100);
            expect(await mockCollection.currentSupply()).to.equal(100);
            expect(await mockCollection.remainingSupply()).to.equal(9900);
        });
        
        it("Should enforce max supply", async function () {
            await mockCollection.authorizeCaller(owner.address);
            
            await expect(
                mockCollection.incrementSupply(10001)
            ).to.be.revertedWith("Exceeds max supply");
        });
        
        it("Should set default royalty", async function () {
            await mockCollection.setDefaultRoyalty(owner.address, 500);
            
            const [receiver, amount] = await mockCollection.royaltyInfo(1, ethers.parseEther("1"));
            expect(receiver).to.equal(owner.address);
            expect(amount).to.equal(ethers.parseEther("0.05")); // 5%
        });
        
        it("Should set token-specific royalty", async function () {
            await mockCollection.setDefaultRoyalty(owner.address, 500);
            await mockCollection.setTokenRoyalty(1, user1.address, 1000);
            
            const [receiver, amount] = await mockCollection.royaltyInfo(1, ethers.parseEther("1"));
            expect(receiver).to.equal(user1.address);
            expect(amount).to.equal(ethers.parseEther("0.1")); // 10%
        });
    });
});
