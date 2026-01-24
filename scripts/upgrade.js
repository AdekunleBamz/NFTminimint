const hre = require("hardhat");

/**
 * Upgrade Script - Handles contract upgrade scenarios
 * 
 * Note: This script is for re-deploying contracts if needed.
 * The modular architecture allows upgrading individual components.
 */

async function main() {
    console.log("\n🔄 NFTminimint Upgrade Script\n");
    console.log("=".repeat(50));
    
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deployer:", deployer.address);
    
    // Get existing contract addresses from environment or config
    const existingAddresses = {
        nftCore: process.env.NFT_CORE_ADDRESS,
        nftMetadata: process.env.NFT_METADATA_ADDRESS,
        nftAccess: process.env.NFT_ACCESS_ADDRESS,
        nftCollection: process.env.NFT_COLLECTION_ADDRESS,
        nftMinimint: process.env.NFT_MINIMINT_ADDRESS
    };
    
    console.log("\n📍 Existing Contracts:");
    for (const [name, address] of Object.entries(existingAddresses)) {
        console.log(`   ${name}: ${address || "Not set"}`);
    }
    
    // Example: Upgrade NFTMinimint controller only
    const upgradeController = process.env.UPGRADE_CONTROLLER === "true";
    
    if (upgradeController) {
        console.log("\n📦 Upgrading NFTMinimint Controller...");
        
        if (!existingAddresses.nftCore || 
            !existingAddresses.nftMetadata || 
            !existingAddresses.nftAccess || 
            !existingAddresses.nftCollection) {
            throw new Error("Missing existing contract addresses");
        }
        
        const NFTMinimint = await hre.ethers.getContractFactory("NFTminimint");
        const newController = await NFTMinimint.deploy(
            existingAddresses.nftCore,
            existingAddresses.nftMetadata,
            existingAddresses.nftAccess,
            existingAddresses.nftCollection
        );
        await newController.waitForDeployment();
        
        const newAddress = await newController.getAddress();
        console.log("✅ New NFTMinimint deployed:", newAddress);
        
        console.log("\n⚠️  Important: Update authorizations on other contracts!");
        console.log("   - NFTCore: authorizeMinter(newAddress)");
        console.log("   - NFTMetadata: authorizeCaller(newAddress)");
        console.log("   - NFTAccess: authorizeCaller(newAddress)");
        console.log("   - NFTCollection: authorizeCaller(newAddress)");
    }
    
    // Example: Add new functionality
    const deployExtension = process.env.DEPLOY_EXTENSION;
    
    if (deployExtension) {
        console.log(`\n📦 Deploying Extension: ${deployExtension}...`);
        
        // This would deploy a new extension contract
        // Extensions are independent and can be added without modifying existing contracts
        console.log("Extension deployment would happen here");
    }
    
    console.log("\n" + "=".repeat(50));
    console.log("✨ Upgrade process completed!\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("\n❌ Upgrade failed:", error);
        process.exit(1);
    });
