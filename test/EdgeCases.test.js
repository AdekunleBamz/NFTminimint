const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Edge Cases", function () {
    let nftCore, nftAccess, nftMetadata, nftCollection, nftMinimint;
    let owner, user1, user2, user3;
    
    beforeEach(async function () {
        [owner, user1, user2, user3] = await ethers.getSigners();
        
        // Deploy contracts
        const NFTCore = await ethers.getContractFactory("NFTCore");
        nftCore = await NFTCore.deploy("EdgeCase", "EDGE");
        
        const NFTMetadata = await ethers.getContractFactory("NFTMetadata");
        nftMetadata = await NFTMetadata.deploy();
        
        const NFTAccess = await ethers.getContractFactory("NFTAccess");
        nftAccess = await NFTAccess.deploy();
        
        const NFTCollection = await ethers.getContractFactory("NFTCollection");
        nftCollection = await NFTCollection.deploy(100);
        
        const NFTMinimint = await ethers.getContractFactory("NFTminimint");
        nftMinimint = await NFTMinimint.deploy(
            await nftCore.getAddress(),
            await nftMetadata.getAddress(),
            await nftAccess.getAddress(),
            await nftCollection.getAddress()
        );
        
        // Link contracts
        await nftCore.authorizeMinter(await nftMinimint.getAddress());
        await nftMetadata.authorizeCaller(await nftMinimint.getAddress());
        await nftAccess.authorizeCaller(await nftMinimint.getAddress());
        await nftCollection.authorizeCaller(await nftMinimint.getAddress());
        await nftAccess.setPublicMintOpen(true);
    });
    
    describe("Empty String Handling", function () {
        it("Should handle empty token URI", async function () {
            await nftMinimint.connect(user1).mint("");
            const uri = await nftCore.tokenURI(1);
            expect(uri).to.equal("");
        });
        
        it("Should handle empty attribute key", async function () {
            await nftMinimint.connect(user1).mint("ipfs://test");
            await nftMetadata.authorizeCaller(owner.address);
            await nftMetadata.setAttribute(1, "", "value");
            expect(await nftMetadata.getAttribute(1, "")).to.equal("value");
        });
        
        it("Should handle empty attribute value", async function () {
            await nftMinimint.connect(user1).mint("ipfs://test");
            await nftMetadata.authorizeCaller(owner.address);
            await nftMetadata.setAttribute(1, "key", "");
            expect(await nftMetadata.getAttribute(1, "key")).to.equal("");
        });
    });
    
    describe("Boundary Conditions", function () {
        it("Should handle first token ID correctly", async function () {
            await nftMinimint.connect(user1).mint("ipfs://first");
            expect(await nftCore.ownerOf(1)).to.equal(user1.address);
        });
        
        it("Should handle max supply boundary", async function () {
            // Set small max supply
            await nftCollection.setMaxSupply(3);
            
            await nftMinimint.connect(user1).mint("ipfs://1");
            await nftMinimint.connect(user1).mint("ipfs://2");
            await nftMinimint.connect(user1).mint("ipfs://3");
            
            // Fourth mint should fail
            await expect(
                nftMinimint.connect(user1).mint("ipfs://4")
            ).to.be.reverted;
        });
        
        it("Should handle wallet mint limit exactly", async function () {
            await nftAccess.setWalletMintLimit(3);
            
            await nftMinimint.connect(user1).mint("ipfs://1");
            await nftMinimint.connect(user1).mint("ipfs://2");
            await nftMinimint.connect(user1).mint("ipfs://3");
            
            // Fourth mint should fail
            await expect(
                nftMinimint.connect(user1).mint("ipfs://4")
            ).to.be.reverted;
        });
    });
    
    describe("Rapid Consecutive Operations", function () {
        it("Should handle rapid mints", async function () {
            const promises = [];
            for (let i = 0; i < 5; i++) {
                promises.push(nftMinimint.connect(user1).mint(`ipfs://${i}`));
            }
            
            await Promise.all(promises);
            expect(await nftCore.totalSupply()).to.equal(5);
        });
        
        it("Should handle multiple users minting simultaneously", async function () {
            const promises = [
                nftMinimint.connect(user1).mint("ipfs://u1"),
                nftMinimint.connect(user2).mint("ipfs://u2"),
                nftMinimint.connect(user3).mint("ipfs://u3")
            ];
            
            await Promise.all(promises);
            expect(await nftCore.totalSupply()).to.equal(3);
        });
    });
    
    describe("Special Characters", function () {
        it("Should handle URI with special characters", async function () {
            const specialURI = "ipfs://QmTest?query=value&other=123#fragment";
            await nftMinimint.connect(user1).mint(specialURI);
            expect(await nftCore.tokenURI(1)).to.equal(specialURI);
        });
        
        it("Should handle Unicode in attributes", async function () {
            await nftMinimint.connect(user1).mint("ipfs://test");
            await nftMetadata.authorizeCaller(owner.address);
            
            const unicodeKey = "名前";
            const unicodeValue = "アート🎨";
            
            await nftMetadata.setAttribute(1, unicodeKey, unicodeValue);
            expect(await nftMetadata.getAttribute(1, unicodeKey)).to.equal(unicodeValue);
        });
    });
    
    describe("State Transitions", function () {
        it("Should handle pause/unpause during operations", async function () {
            await nftMinimint.connect(user1).mint("ipfs://1");
            
            await nftAccess.setPaused(true);
            await expect(
                nftMinimint.connect(user1).mint("ipfs://2")
            ).to.be.reverted;
            
            await nftAccess.setPaused(false);
            await nftMinimint.connect(user1).mint("ipfs://2");
            
            expect(await nftCore.totalSupply()).to.equal(2);
        });
        
        it("Should handle whitelist toggle correctly", async function () {
            await nftAccess.setPublicMintOpen(false);
            await nftAccess.setWhitelistEnabled(true);
            
            // User not whitelisted
            await expect(
                nftMinimint.connect(user1).mint("ipfs://test")
            ).to.be.reverted;
            
            // Add to whitelist
            await nftAccess.addToWhitelist(user1.address);
            await nftMinimint.connect(user1).mint("ipfs://test");
            
            expect(await nftCore.totalSupply()).to.equal(1);
        });
    });
    
    describe("Royalty Edge Cases", function () {
        it("Should handle 0% royalty", async function () {
            await nftCollection.setDefaultRoyalty(owner.address, 0);
            
            const [receiver, amount] = await nftCollection.royaltyInfo(1, ethers.parseEther("1"));
            expect(amount).to.equal(0);
        });
        
        it("Should handle max royalty (10%)", async function () {
            await nftCollection.setDefaultRoyalty(owner.address, 1000);
            
            const [receiver, amount] = await nftCollection.royaltyInfo(1, ethers.parseEther("1"));
            expect(amount).to.equal(ethers.parseEther("0.1"));
        });
        
        it("Should reject royalty > 10%", async function () {
            await expect(
                nftCollection.setDefaultRoyalty(owner.address, 1001)
            ).to.be.reverted;
        });
    });
});
