const hre = require("hardhat");

/**
 * Airdrop script - Distribute NFTs to multiple addresses
 */
async function main() {
  console.log("🎁 Starting airdrop...\n");

  // Configure these
  const NFTMINIMINT_ADDRESS = process.env.NFTMINIMINT_ADDRESS || "YOUR_ADDRESS";
  
  // Recipients and their token URIs
  const airdrops = [
    { recipient: "0x...", uri: "ipfs://..." },
    { recipient: "0x...", uri: "ipfs://..." },
    // Add more...
  ];

  if (NFTMINIMINT_ADDRESS.includes("YOUR_")) {
    console.log("❌ Please set NFTMINIMINT_ADDRESS!");
    process.exit(1);
  }

  const [deployer] = await hre.ethers.getSigners();
  console.log("Airdropping from:", deployer.address);
  console.log("");

  const nftMinimint = await hre.ethers.getContractAt("NFTminimint", NFTMINIMINT_ADDRESS);

  // Split into batches of 50
  const batchSize = 50;
  const batches = [];
  for (let i = 0; i < airdrops.length; i += batchSize) {
    batches.push(airdrops.slice(i, i + batchSize));
  }

  console.log(`📦 Processing ${batches.length} batch(es)...`);
  console.log("");

  let totalAirdropped = 0;
  for (let i = 0; i < batches.length; i++) {
    const batch = batches[i];
    const recipients = batch.map(a => a.recipient);
    const uris = batch.map(a => a.uri);

    console.log(`🔄 Batch ${i + 1}/${batches.length}: ${batch.length} NFTs...`);
    
    const tx = await nftMinimint.airdrop(recipients, uris);
    await tx.wait();
    
    totalAirdropped += batch.length;
    console.log(`✅ Batch ${i + 1} complete. Transaction: ${tx.hash}`);
  }

  console.log("");
  console.log("═══════════════════════════════════════");
  console.log(`🎉 Airdrop complete! ${totalAirdropped} NFTs distributed.`);
  console.log("═══════════════════════════════════════");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Airdrop failed:", error);
    process.exit(1);
  });
