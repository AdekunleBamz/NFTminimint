const hre = require("hardhat");

/**
 * Link script - run after deploy-all.js
 * Usage: npx hardhat run scripts/link-contracts.js --network <network>
 * 
 * Set these environment variables or modify directly:
 * - NFTCORE_ADDRESS
 * - NFTACCESS_ADDRESS
 * - NFTMINIMINT_ADDRESS
 */
async function main() {
  console.log("🔗 Starting contract linking...\n");

  // Get addresses from environment or set manually
  const NFTCORE_ADDRESS = process.env.NFTCORE_ADDRESS || "YOUR_NFTCORE_ADDRESS";
  const NFTACCESS_ADDRESS = process.env.NFTACCESS_ADDRESS || "YOUR_NFTACCESS_ADDRESS";
  const NFTMINIMINT_ADDRESS = process.env.NFTMINIMINT_ADDRESS || "YOUR_NFTMINIMINT_ADDRESS";

  if (NFTCORE_ADDRESS.includes("YOUR_")) {
    console.log("❌ Please set contract addresses!");
    console.log("Set environment variables or edit this script.");
    process.exit(1);
  }

  const [deployer] = await hre.ethers.getSigners();
  console.log("Linking with account:", deployer.address);
  console.log("");

  // Get contract instances
  const nftCore = await hre.ethers.getContractAt("NFTCore", NFTCORE_ADDRESS);
  const nftAccess = await hre.ethers.getContractAt("NFTAccess", NFTACCESS_ADDRESS);

  // Step 1: Authorize NFTminimint as minter
  console.log("🔗 Step 1/3: Authorizing NFTminimint as minter on NFTCore...");
  const tx1 = await nftCore.authorizeMinter(NFTMINIMINT_ADDRESS);
  await tx1.wait();
  console.log("✅ NFTminimint authorized as minter");
  console.log("   Transaction:", tx1.hash);
  console.log("");

  // Step 2: Authorize NFTminimint as caller
  console.log("🔗 Step 2/3: Authorizing NFTminimint as caller on NFTAccess...");
  const tx2 = await nftAccess.authorizeCaller(NFTMINIMINT_ADDRESS);
  await tx2.wait();
  console.log("✅ NFTminimint authorized as caller");
  console.log("   Transaction:", tx2.hash);
  console.log("");

  // Step 3: Open public minting
  console.log("🔗 Step 3/3: Opening public minting...");
  const tx3 = await nftAccess.setPublicMintOpen(true);
  await tx3.wait();
  console.log("✅ Public minting opened");
  console.log("   Transaction:", tx3.hash);
  console.log("");

  console.log("═══════════════════════════════════════");
  console.log("🎉 All contracts linked successfully!");
  console.log("═══════════════════════════════════════");
  console.log("\nYour NFT collection is now ready for FREE minting!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Linking failed:", error);
    process.exit(1);
  });
