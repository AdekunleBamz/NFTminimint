const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTPermit Extension", function () {
    let mockPermit;
    let owner, spender, other;
    
    beforeEach(async function () {
        [owner, spender, other] = await ethers.getSigners();
        
        const MockNFTPermit = await ethers.getContractFactory("MockNFTPermit");
        mockPermit = await MockNFTPermit.deploy("MockPermit", "MP");
        await mockPermit.waitForDeployment();
    });
    
    it("Should approve via permit", async function () {
        const tokenId = await mockPermit.mint(owner.address);
        const chainId = (await ethers.provider.getNetwork()).chainId;
        const deadline = Math.floor(Date.now() / 1000) + 3600;
        
        const nonce = await mockPermit.nonces(0);
        
        const domain = {
            name: "MockPermit",
            version: "1",
            chainId,
            verifyingContract: await mockPermit.getAddress()
        };
        
        const types = {
            Permit: [
                { name: "spender", type: "address" },
                { name: "tokenId", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" }
            ]
        };
        
        const value = {
            spender: spender.address,
            tokenId: 0,
            nonce,
            deadline
        };
        
        const signature = await owner.signTypedData(domain, types, value);
        const { v, r, s } = ethers.Signature.from(signature);
        
        await mockPermit.permit(spender.address, 0, deadline, v, r, s);
        expect(await mockPermit.getApproved(0)).to.equal(spender.address);
        expect(await mockPermit.nonces(0)).to.equal(nonce + 1n);
    });
    
    it("Should reject invalid signature", async function () {
        await mockPermit.mint(owner.address);
        const chainId = (await ethers.provider.getNetwork()).chainId;
        const deadline = Math.floor(Date.now() / 1000) + 3600;
        
        const nonce = await mockPermit.nonces(0);
        
        const domain = {
            name: "MockPermit",
            version: "1",
            chainId,
            verifyingContract: await mockPermit.getAddress()
        };
        
        const types = {
            Permit: [
                { name: "spender", type: "address" },
                { name: "tokenId", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" }
            ]
        };
        
        const value = {
            spender: spender.address,
            tokenId: 0,
            nonce,
            deadline
        };
        
        // Signed by wrong account
        const signature = await other.signTypedData(domain, types, value);
        const { v, r, s } = ethers.Signature.from(signature);
        
        await expect(
            mockPermit.permit(spender.address, 0, deadline, v, r, s)
        ).to.be.revertedWith("Invalid signature");
    });
});
