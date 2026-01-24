const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTGated Extension", function () {
    let mockGated;
    let owner, user;
    
    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();
        
        const MockNFTGated = await ethers.getContractFactory("MockNFTGated");
        mockGated = await MockNFTGated.deploy("MockGated", "MG");
        await mockGated.waitForDeployment();
    });
    
    it("Should deny access when balance is insufficient", async function () {
        const featureId = await mockGated.createFeature(
            "VIP",
            1,
            0,
            0
        );
        
        await expect(
            mockGated.connect(user).access(featureId)
        ).to.be.revertedWith("Access denied");
    });
    
    it("Should allow access when user meets requirements", async function () {
        const featureId = await mockGated.createFeature(
            "VIP",
            1,
            0,
            0
        );
        
        await mockGated.mint(user.address);
        await mockGated.connect(user).access(featureId);
    });
    
    it("Should block access when feature is inactive", async function () {
        const featureId = await mockGated.createFeature(
            "VIP",
            1,
            0,
            0
        );
        
        await mockGated.mint(user.address);
        await mockGated.setFeatureActive(featureId, false);
        
        await expect(
            mockGated.connect(user).access(featureId)
        ).to.be.revertedWith("Access denied");
    });
});
