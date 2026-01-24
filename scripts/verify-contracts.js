const hre = require("hardhat");

/**
 * Verification script - run after deployment
 * Verifies all contracts on block explorer
 */
async function main() {
  console.log("🔍 Starting contract verification...\n");

  // Set your deployed addresses here
  const NFTCORE_ADDRESS = process.env.NFTCORE_ADDRESS || "YOUR_ADDRESS";
  const NFTMETADATA_ADDRESS = process.env.NFTMETADATA_ADDRESS || "YOUR_ADDRESS";
  const NFTACCESS_ADDRESS = process.env.NFTACCESS_ADDRESS || "YOUR_ADDRESS";
  const NFTCOLLECTION_ADDRESS = process.env.NFTCOLLECTION_ADDRESS || "YOUR_ADDRESS";
  const NFTMINIMINT_ADDRESS = process.env.NFTMINIMINT_ADDRESS || "YOUR_ADDRESS";

  // Configuration (match your deployment)
  const COLLECTION_NAME = "MiniMint Collection";
  const COLLECTION_SYMBOL = "MINT";
  const MAX_SUPPLY = 10000;

  console.log("📋 Verifying NFTCore...");
  try {
    await hre.run("verify:verify", {
      address: NFTCORE_ADDRESS,
      constructorArguments: [COLLECTION_NAME, COLLECTION_SYMBOL],
    });
    console.log("✅ NFTCore verified\n");
  } catch (error) {
    console.log("⚠️ NFTCore verification failed:", error.message, "\n");
  }

  console.log("📋 Verifying NFTMetadata...");
  try {
    await hre.run("verify:verify", {
      address: NFTMETADATA_ADDRESS,
      constructorArguments: [NFTCORE_ADDRESS],
    });
    console.log("✅ NFTMetadata verified\n");
  } catch (error) {
    console.log("⚠️ NFTMetadata verification failed:", error.message, "\n");
  }

  console.log("📋 Verifying NFTAccess...");
  try {
    await hre.run("verify:verify", {
      address: NFTACCESS_ADDRESS,
      constructorArguments: [NFTCORE_ADDRESS],
    });
    console.log("✅ NFTAccess verified\n");
  } catch (error) {
    console.log("⚠️ NFTAccess verification failed:", error.message, "\n");
  }

  console.log("📋 Verifying NFTCollection...");
  try {
    await hre.run("verify:verify", {
      address: NFTCOLLECTION_ADDRESS,
      constructorArguments: [NFTCORE_ADDRESS, MAX_SUPPLY],
    });
    console.log("✅ NFTCollection verified\n");
  } catch (error) {
    console.log("⚠️ NFTCollection verification failed:", error.message, "\n");
  }

  console.log("📋 Verifying NFTminimint...");
  try {
    await hre.run("verify:verify", {
      address: NFTMINIMINT_ADDRESS,
      constructorArguments: [
        NFTCORE_ADDRESS,
        NFTMETADATA_ADDRESS,
        NFTACCESS_ADDRESS,
        NFTCOLLECTION_ADDRESS,
      ],
    });
    console.log("✅ NFTminimint verified\n");
  } catch (error) {
    console.log("⚠️ NFTminimint verification failed:", error.message, "\n");
  }

  console.log("═══════════════════════════════════════");
  console.log("🎉 Verification process complete!");
  console.log("═══════════════════════════════════════");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Verification failed:", error);
    process.exit(1);
  });
