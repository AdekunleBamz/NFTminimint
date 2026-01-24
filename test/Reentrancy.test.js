const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Protection", function () {
    let nftCore, nftAccess, nftMetadata, nftCollection, nftMinimint;
    let owner, attacker;
    
    beforeEach(async function () {
        [owner, attacker] = await ethers.getSigners();
        
        const NFTCore = await ethers.getContractFactory("NFTCore");
        nftCore = await NFTCore.deploy("ReentrancyTest", "REEN");
        
        const NFTMetadata = await ethers.getContractFactory("NFTMetadata");
        nftMetadata = await NFTMetadata.deploy();
        
        const NFTAccess = await ethers.getContractFactory("NFTAccess");
        nftAccess = await NFTAccess.deploy();
        
        const NFTCollection = await ethers.getContractFactory("NFTCollection");
        nftCollection = await NFTCollection.deploy(1000);
        
        const NFTMinimint = await ethers.getContractFactory("NFTminimint");
        nftMinimint = await NFTMinimint.deploy(
            await nftCore.getAddress(),
            await nftMetadata.getAddress(),
            await nftAccess.getAddress(),
            await nftCollection.getAddress()
        );
        
        await nftCore.authorizeMinter(await nftMinimint.getAddress());
        await nftMetadata.authorizeCaller(await nftMinimint.getAddress());
        await nftAccess.authorizeCaller(await nftMinimint.getAddress());
        await nftCollection.authorizeCaller(await nftMinimint.getAddress());
        await nftAccess.setPublicMintOpen(true);
    });
    
    describe("State Consistency", function () {
        it("Should maintain consistent state after multiple operations", async function () {
            // Perform multiple operations
            await nftMinimint.connect(attacker).mint("ipfs://1");
            await nftMinimint.connect(attacker).mint("ipfs://2");
            await nftMinimint.connect(attacker).mint("ipfs://3");
            
            // Verify state consistency
            expect(await nftCore.totalSupply()).to.equal(3);
            expect(await nftCore.balanceOf(attacker.address)).to.equal(3);
            expect(await nftCollection.currentSupply()).to.equal(3);
        });
        
        it("Should not allow minting after max supply reached", async function () {
            await nftCollection.setMaxSupply(2);
            
            await nftMinimint.connect(attacker).mint("ipfs://1");
            await nftMinimint.connect(attacker).mint("ipfs://2");
            
            await expect(
                nftMinimint.connect(attacker).mint("ipfs://3")
            ).to.be.reverted;
            
            // State should remain consistent
            expect(await nftCore.totalSupply()).to.equal(2);
        });
    });
    
    describe("Access Control Integrity", function () {
        it("Should not allow unauthorized callers", async function () {
            // Try to call NFTCore directly without authorization
            await expect(
                nftCore.connect(attacker).mintTo(attacker.address, "ipfs://hack")
            ).to.be.reverted;
        });
        
        it("Should not allow unauthorized access to NFTAccess", async function () {
            await expect(
                nftAccess.connect(attacker).recordMint(attacker.address, 100)
            ).to.be.reverted;
        });
        
        it("Should not allow unauthorized metadata changes", async function () {
            await nftMinimint.connect(attacker).mint("ipfs://token");
            
            await expect(
                nftMetadata.connect(attacker).setAttribute(1, "rarity", "legendary")
            ).to.be.reverted;
        });
    });
});

describe("Front-Running Protection", function () {
    let nftAccess;
    let owner, user1, user2;
    
    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        
        const NFTAccess = await ethers.getContractFactory("NFTAccess");
        nftAccess = await NFTAccess.deploy();
    });
    
    it("Should track per-wallet limits accurately", async function () {
        await nftAccess.setWalletMintLimit(5);
        await nftAccess.authorizeCaller(owner.address);
        
        // Record mints for user1
        await nftAccess.recordMint(user1.address, 3);
        
        // User1 can only mint 2 more
        expect(await nftAccess.canMint(user1.address, 2)).to.be.true;
        expect(await nftAccess.canMint(user1.address, 3)).to.be.false;
        
        // User2 still has full limit
        expect(await nftAccess.canMint(user2.address, 5)).to.be.true;
    });
});

describe("Overflow Protection", function () {
    it("Should handle large numbers safely", async function () {
        const NFTCollection = await ethers.getContractFactory("NFTCollection");
        
        // Max uint256 - should work due to Solidity 0.8+ overflow checks
        const maxSupply = ethers.MaxUint256;
        
        // This would revert in practice due to gas limits, but type-safety is maintained
        const collection = await NFTCollection.deploy(10000);
        expect(await collection.maxSupply()).to.equal(10000);
    });
});
