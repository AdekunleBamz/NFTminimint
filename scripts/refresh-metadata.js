const hre = require("hardhat");

/**
 * Metadata Refresh Script
 * Updates token metadata and attributes in batch
 */

async function main() {
    console.log("\n🔄 NFTminimint Metadata Refresh\n");
    console.log("=".repeat(50));
    
    const nftMetadataAddress = process.env.NFT_METADATA_ADDRESS;
    const nftMinimintAddress = process.env.NFT_MINIMINT_ADDRESS;
    
    if (!nftMetadataAddress || !nftMinimintAddress) {
        console.log("❌ Required addresses not set");
        console.log("Usage:");
        console.log("  NFT_METADATA_ADDRESS=0x... NFT_MINIMINT_ADDRESS=0x... npx hardhat run scripts/refresh-metadata.js");
        process.exit(1);
    }
    
    const [signer] = await hre.ethers.getSigners();
    console.log("Signer:", signer.address);
    
    // Get contract instances
    const NFTMetadata = await hre.ethers.getContractFactory("NFTMetadata");
    const nftMetadata = NFTMetadata.attach(nftMetadataAddress);
    
    // Example: Update contract URI
    const updateContractURI = process.env.NEW_CONTRACT_URI;
    if (updateContractURI) {
        console.log("\n📝 Updating contract URI...");
        console.log(`   New URI: ${updateContractURI}`);
        
        const tx = await nftMetadata.setContractURI(updateContractURI);
        await tx.wait();
        console.log("   ✅ Contract URI updated!");
    }
    
    // Example: Batch update attributes
    const updateAttributes = process.env.UPDATE_ATTRIBUTES === "true";
    if (updateAttributes) {
        console.log("\n📝 Batch updating attributes...");
        
        // Example attribute updates
        const updates = [
            { tokenId: 1, key: "rarity", value: "legendary" },
            { tokenId: 2, key: "rarity", value: "rare" },
            { tokenId: 3, key: "rarity", value: "common" },
        ];
        
        for (const update of updates) {
            try {
                // Check if metadata is frozen
                const frozen = await nftMetadata.isMetadataFrozen(update.tokenId);
                if (frozen) {
                    console.log(`   Token ${update.tokenId}: ⚠️ Metadata frozen, skipping`);
                    continue;
                }
                
                const tx = await nftMetadata.setAttribute(
                    update.tokenId,
                    update.key,
                    update.value
                );
                await tx.wait();
                console.log(`   Token ${update.tokenId}: ✅ ${update.key}=${update.value}`);
            } catch (error) {
                console.log(`   Token ${update.tokenId}: ❌ Failed - ${error.message}`);
            }
        }
    }
    
    // Example: Freeze metadata for specific tokens
    const freezeTokens = process.env.FREEZE_TOKENS;
    if (freezeTokens) {
        const tokenIds = freezeTokens.split(",").map(id => parseInt(id.trim()));
        console.log(`\n🔒 Freezing metadata for tokens: ${tokenIds.join(", ")}`);
        
        for (const tokenId of tokenIds) {
            try {
                const tx = await nftMetadata.freezeMetadata(tokenId);
                await tx.wait();
                console.log(`   Token ${tokenId}: ✅ Metadata frozen`);
            } catch (error) {
                console.log(`   Token ${tokenId}: ❌ Failed - ${error.message}`);
            }
        }
    }
    
    console.log("\n" + "=".repeat(50));
    console.log("✨ Metadata refresh completed!\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Metadata refresh failed:", error);
        process.exit(1);
    });
