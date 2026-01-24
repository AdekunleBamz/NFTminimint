const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTDynamicPricing Extension", function () {
    let mockPricing;
    
    beforeEach(async function () {
        const MockNFTDynamicPricing = await ethers.getContractFactory("MockNFTDynamicPricing");
        mockPricing = await MockNFTDynamicPricing.deploy();
        await mockPricing.waitForDeployment();
    });
    
    it("Should return base price when disabled", async function () {
        await mockPricing.setBasePrice(100);
        await mockPricing.setEnabled(false);
        
        expect(await mockPricing.getPrice(0)).to.equal(100);
        expect(await mockPricing.getPrice(10)).to.equal(100);
    });
    
    it("Should return tiered price when enabled", async function () {
        await mockPricing.setBasePrice(100);
        await mockPricing.addTier(10, 200);
        await mockPricing.addTier(20, 300);
        await mockPricing.setEnabled(true);
        
        expect(await mockPricing.getPrice(0)).to.equal(200);
        expect(await mockPricing.getPrice(9)).to.equal(200);
        expect(await mockPricing.getPrice(10)).to.equal(300);
        expect(await mockPricing.getPrice(19)).to.equal(300);
        expect(await mockPricing.getPrice(20)).to.equal(300);
    });
    
    it("Should clear tiers and fall back to base price", async function () {
        await mockPricing.setBasePrice(150);
        await mockPricing.addTier(5, 200);
        await mockPricing.setEnabled(true);
        
        expect(await mockPricing.getPrice(0)).to.equal(200);
        
        await mockPricing.clearTiers();
        expect(await mockPricing.getPrice(0)).to.equal(150);
    });
});
