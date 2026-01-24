const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRefundable Extension", function () {
    let mockRefundable;
    
    beforeEach(async function () {
        const MockNFTRefundable = await ethers.getContractFactory("MockNFTRefundable");
        mockRefundable = await MockNFTRefundable.deploy();
        await mockRefundable.waitForDeployment();
    });
    
    it("Should record refund info", async function () {
        await mockRefundable.record(1, 1000);
        const [price, deadline, refunded] = await mockRefundable.getRefundInfo(1);
        
        expect(price).to.equal(1000);
        expect(deadline).to.be.gt(0);
        expect(refunded).to.equal(false);
    });
    
    it("Should process refund once", async function () {
        await mockRefundable.record(1, 500);
        
        const amount = await mockRefundable.process(1, ethers.ZeroAddress);
        expect(amount).to.equal(500);
        
        const [, , refunded] = await mockRefundable.getRefundInfo(1);
        expect(refunded).to.equal(true);
    });
    
    it("Should not allow refund after deadline", async function () {
        await mockRefundable.setRefundPeriod(1);
        await mockRefundable.record(1, 1000);
        
        // Fast-forward time
        await ethers.provider.send("evm_increaseTime", [2]);
        await ethers.provider.send("evm_mine", []);
        
        await expect(
            mockRefundable.process(1, ethers.ZeroAddress)
        ).to.be.revertedWith("Not refundable");
    });
});
