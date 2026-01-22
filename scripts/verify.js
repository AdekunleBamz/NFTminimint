const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

/**
 * Verify contract on Etherscan
 * Usage: npx hardhat run scripts/verify.js --network sepolia
 */

async function main() {
  const network = hre.network.name;
  console.log("\n🔍 Verifying NFTminimint on", network, "...\n");

  // Load deployment info
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  const deploymentFile = path.join(deploymentsDir, `${network}.json`);

  if (!fs.existsSync(deploymentFile)) {
    console.error("❌ Deployment file not found:", deploymentFile);
    console.log("   Please deploy the contract first using: npx hardhat run scripts/deploy.js --network", network);
    process.exit(1);
  }

  const deployment = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  console.log("📋 Contract Address:", deployment.contractAddress);
  console.log("   Deployed at:", deployment.timestamp);
  console.log("");

  try {
    await hre.run("verify:verify", {
      address: deployment.contractAddress,
      constructorArguments: []
    });
    console.log("\n✅ Contract verified successfully!");
  } catch (error) {
    if (error.message.includes("Already Verified")) {
      console.log("\nℹ️  Contract is already verified on Etherscan");
    } else {
      console.error("\n❌ Verification failed:", error.message);
      process.exit(1);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
