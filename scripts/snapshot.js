const hre = require("hardhat");

/**
 * Snapshot Script - Take snapshot of collection state
 * Useful for airdrops to holders or analyzing collection
 */

async function main() {
    console.log("\n📸 NFTminimint Collection Snapshot\n");
    console.log("=".repeat(50));
    
    const nftCoreAddress = process.env.NFT_CORE_ADDRESS;
    const nftCollectionAddress = process.env.NFT_COLLECTION_ADDRESS;
    
    if (!nftCoreAddress) {
        console.log("❌ NFT_CORE_ADDRESS not set");
        console.log("Usage: NFT_CORE_ADDRESS=0x... npx hardhat run scripts/snapshot.js");
        process.exit(1);
    }
    
    // Get contract instances
    const NFTCore = await hre.ethers.getContractFactory("NFTCore");
    const nftCore = NFTCore.attach(nftCoreAddress);
    
    console.log("📍 NFTCore:", nftCoreAddress);
    
    // Get collection info
    const name = await nftCore.name();
    const symbol = await nftCore.symbol();
    const totalSupply = await nftCore.totalSupply();
    
    console.log(`\n📊 Collection: ${name} (${symbol})`);
    console.log(`   Total Supply: ${totalSupply}`);
    
    // Build holder snapshot
    console.log("\n🔍 Building holder snapshot...\n");
    
    const holders = {};
    const tokenOwners = [];
    
    for (let i = 1; i <= Number(totalSupply); i++) {
        try {
            const owner = await nftCore.ownerOf(i);
            
            if (!holders[owner]) {
                holders[owner] = [];
            }
            holders[owner].push(i);
            
            tokenOwners.push({
                tokenId: i,
                owner: owner
            });
            
            if (i % 100 === 0) {
                console.log(`   Processed ${i}/${totalSupply} tokens...`);
            }
        } catch (error) {
            // Token might be burned
            console.log(`   Token ${i}: Burned or invalid`);
        }
    }
    
    // Generate snapshot report
    console.log("\n" + "=".repeat(50));
    console.log("📋 SNAPSHOT REPORT\n");
    
    const holderAddresses = Object.keys(holders);
    console.log(`Unique Holders: ${holderAddresses.length}`);
    
    // Sort holders by token count
    const sortedHolders = holderAddresses
        .map(addr => ({
            address: addr,
            count: holders[addr].length,
            tokens: holders[addr]
        }))
        .sort((a, b) => b.count - a.count);
    
    console.log("\n🏆 Top 10 Holders:");
    sortedHolders.slice(0, 10).forEach((holder, index) => {
        console.log(`   ${index + 1}. ${holder.address}: ${holder.count} tokens`);
    });
    
    // Distribution stats
    const distribution = {
        "1 token": 0,
        "2-5 tokens": 0,
        "6-10 tokens": 0,
        "11-50 tokens": 0,
        "50+ tokens": 0
    };
    
    sortedHolders.forEach(holder => {
        if (holder.count === 1) distribution["1 token"]++;
        else if (holder.count <= 5) distribution["2-5 tokens"]++;
        else if (holder.count <= 10) distribution["6-10 tokens"]++;
        else if (holder.count <= 50) distribution["11-50 tokens"]++;
        else distribution["50+ tokens"]++;
    });
    
    console.log("\n📊 Distribution:");
    Object.entries(distribution).forEach(([range, count]) => {
        console.log(`   ${range}: ${count} holders`);
    });
    
    // Output snapshot data
    const snapshot = {
        timestamp: new Date().toISOString(),
        block: await hre.ethers.provider.getBlockNumber(),
        contract: nftCoreAddress,
        collection: { name, symbol, totalSupply: Number(totalSupply) },
        uniqueHolders: holderAddresses.length,
        holders: sortedHolders,
        tokenOwners: tokenOwners
    };
    
    // Write to file
    const fs = require("fs");
    const filename = `snapshot-${Date.now()}.json`;
    fs.writeFileSync(filename, JSON.stringify(snapshot, null, 2));
    
    console.log(`\n💾 Snapshot saved to: ${filename}`);
    console.log("\n" + "=".repeat(50) + "\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Snapshot failed:", error);
        process.exit(1);
    });
