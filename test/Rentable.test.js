const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTRentable Extension", function () {
    let mockRentable;
    let owner, user, renter;
    
    beforeEach(async function () {
        [owner, user, renter] = await ethers.getSigners();
        
        const MockNFTRentable = await ethers.getContractFactory("MockNFTRentable");
        mockRentable = await MockNFTRentable.deploy("MockRent", "MR");
        await mockRentable.waitForDeployment();
    });
    
    it("Should set and read user", async function () {
        await mockRentable.mint(user.address);
        const expires = Math.floor(Date.now() / 1000) + 3600;
        
        await mockRentable.setUser(0, renter.address, expires);
        expect(await mockRentable.userOf(0)).to.equal(renter.address);
        expect(await mockRentable.userExpires(0)).to.equal(expires);
    });
    
    it("Should clear user", async function () {
        await mockRentable.mint(user.address);
        const expires = Math.floor(Date.now() / 1000) + 3600;
        
        await mockRentable.setUser(0, renter.address, expires);
        await mockRentable.clearUser(0);
        
        expect(await mockRentable.userOf(0)).to.equal(ethers.ZeroAddress);
        expect(await mockRentable.userExpires(0)).to.equal(0);
    });
    
    it("Should report active rental", async function () {
        await mockRentable.mint(user.address);
        const expires = Math.floor(Date.now() / 1000) + 3600;
        
        await mockRentable.setUser(0, renter.address, expires);
        expect(await mockRentable.hasActiveRental(0)).to.equal(true);
    });
});
