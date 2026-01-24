const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTBatchTransfer Extension", function () {
    let mockBatch;
    let owner, user1, user2, user3;
    
    beforeEach(async function () {
        [owner, user1, user2, user3] = await ethers.getSigners();
        
        const MockNFTBatchTransfer = await ethers.getContractFactory("MockNFTBatchTransfer");
        mockBatch = await MockNFTBatchTransfer.deploy("MockBatch", "MB");
        await mockBatch.waitForDeployment();
    });
    
    it("Should batch transfer to a single recipient", async function () {
        const tokenIds = [];
        for (let i = 0; i < 3; i++) {
            await mockBatch.mint(owner.address);
            tokenIds.push(i);
        }
        
        await mockBatch.batchTransferTo(user1.address, tokenIds);
        
        expect(await mockBatch.balanceOf(user1.address)).to.equal(3);
        expect(await mockBatch.balanceOf(owner.address)).to.equal(0);
    });
    
    it("Should batch transfer to multiple recipients", async function () {
        await mockBatch.mint(owner.address);
        await mockBatch.mint(owner.address);
        await mockBatch.mint(owner.address);
        
        const recipients = [user1.address, user2.address, user3.address];
        const tokenIds = [0, 1, 2];
        
        await mockBatch.batchTransferToMany(recipients, tokenIds);
        
        expect(await mockBatch.ownerOf(0)).to.equal(user1.address);
        expect(await mockBatch.ownerOf(1)).to.equal(user2.address);
        expect(await mockBatch.ownerOf(2)).to.equal(user3.address);
    });
    
    it("Should reject mismatched array lengths", async function () {
        await mockBatch.mint(owner.address);
        
        await expect(
            mockBatch.batchTransferToMany([user1.address], [0, 1])
        ).to.be.revertedWith("Arrays length mismatch");
    });
});
