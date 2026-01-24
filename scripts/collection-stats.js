const hre = require("hardhat");

/**
 * Collection stats script - View collection statistics
 */
async function main() {
  console.log("📊 Collection Statistics\n");

  // Configure
  const NFTCORE_ADDRESS = process.env.NFTCORE_ADDRESS || "YOUR_ADDRESS";
  const NFTACCESS_ADDRESS = process.env.NFTACCESS_ADDRESS || "YOUR_ADDRESS";
  const NFTCOLLECTION_ADDRESS = process.env.NFTCOLLECTION_ADDRESS || "YOUR_ADDRESS";

  if (NFTCORE_ADDRESS.includes("YOUR_")) {
    console.log("❌ Please set contract addresses!");
    process.exit(1);
  }

  const nftCore = await hre.ethers.getContractAt("NFTCore", NFTCORE_ADDRESS);
  const nftAccess = await hre.ethers.getContractAt("NFTAccess", NFTACCESS_ADDRESS);
  const nftCollection = await hre.ethers.getContractAt("NFTCollection", NFTCOLLECTION_ADDRESS);

  console.log("═══════════════════════════════════════");
  console.log("           COLLECTION STATS            ");
  console.log("═══════════════════════════════════════\n");

  // Core stats
  const name = await nftCore.name();
  const symbol = await nftCore.symbol();
  const totalMinted = await nftCore.totalMinted();
  const totalBurned = await nftCore.totalBurned();
  const circulating = await nftCore.circulatingSupply();

  console.log("📌 Basic Info:");
  console.log(`   Name: ${name}`);
  console.log(`   Symbol: ${symbol}`);
  console.log("");

  console.log("📈 Supply Stats:");
  console.log(`   Total Minted: ${totalMinted}`);
  console.log(`   Total Burned: ${totalBurned}`);
  console.log(`   Circulating: ${circulating}`);

  // Collection stats
  const maxSupply = await nftCollection.maxSupply();
  const remaining = await nftCollection.remainingSupply();
  console.log(`   Max Supply: ${maxSupply}`);
  console.log(`   Remaining: ${remaining}`);
  console.log("");

  // Access stats
  const publicMintOpen = await nftAccess.publicMintOpen();
  const whitelistEnabled = await nftAccess.whitelistEnabled();
  const whitelistCount = await nftAccess.whitelistCount();
  const paused = await nftAccess.paused();

  console.log("🔐 Access Control:");
  console.log(`   Public Mint: ${publicMintOpen ? "✅ Open" : "❌ Closed"}`);
  console.log(`   Whitelist: ${whitelistEnabled ? "✅ Enabled" : "❌ Disabled"}`);
  console.log(`   Whitelist Count: ${whitelistCount}`);
  console.log(`   Paused: ${paused ? "⚠️ Yes" : "✅ No"}`);
  console.log("");

  console.log("═══════════════════════════════════════\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Failed:", error);
    process.exit(1);
  });
