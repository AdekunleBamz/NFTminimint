const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRoyaltySplit Extension", function () {
    let mockSplit;
    let owner, a1, a2;
    
    beforeEach(async function () {
        [owner, a1, a2] = await ethers.getSigners();
        
        const MockNFTRoyaltySplit = await ethers.getContractFactory("MockNFTRoyaltySplit");
        mockSplit = await MockNFTRoyaltySplit.deploy();
        await mockSplit.waitForDeployment();
    });
    
    it("Should calculate split amounts", async function () {
        await mockSplit.addRecipient(a1.address, 6000); // 60%
        await mockSplit.addRecipient(a2.address, 4000); // 40%
        
        const [recipients, amounts] = await mockSplit.calculate(1000);
        expect(recipients[0]).to.equal(a1.address);
        expect(recipients[1]).to.equal(a2.address);
        expect(amounts[0]).to.equal(600);
        expect(amounts[1]).to.equal(400);
    });
    
    it("Should set split in one call", async function () {
        await mockSplit.setSplit([a1.address, a2.address], [7000, 3000]);
        const [recipients, amounts] = await mockSplit.calculate(1000);
        expect(recipients.length).to.equal(2);
        expect(amounts[0]).to.equal(700);
        expect(amounts[1]).to.equal(300);
    });
});

