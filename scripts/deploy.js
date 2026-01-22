const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("\n🚀 Starting NFTminimint deployment...\n");

  // Get deployer info
  const [deployer] = await hre.ethers.getSigners();
  const balance = await deployer.getBalance();
  const network = hre.network.name;

  console.log("📋 Deployment Configuration:");
  console.log("  Network:", network);
  console.log("  Deployer:", deployer.address);
  console.log("  Balance:", hre.ethers.utils.formatEther(balance), "ETH");
  console.log("");

  // Deploy contract
  console.log("📦 Deploying NFTminimint contract...");
  const NFTminimint = await hre.ethers.getContractFactory("NFTminimint");
  const nftminimint = await NFTminimint.deploy();

  await nftminimint.deployed();

  console.log("✅ NFTminimint deployed to:", nftminimint.address);
  console.log("");

  // Log contract configuration
  const mintFee = await nftminimint.mintFee();
  const maxSupply = await nftminimint.maxSupply();
  const maxPerWallet = await nftminimint.maxPerWallet();
  const name = await nftminimint.name();
  const symbol = await nftminimint.symbol();

  console.log("⚙️  Contract Configuration:");
  console.log("  Name:", name);
  console.log("  Symbol:", symbol);
  console.log("  Mint Fee:", hre.ethers.utils.formatEther(mintFee), "ETH");
  console.log("  Max Supply:", maxSupply.toString());
  console.log("  Max Per Wallet:", maxPerWallet.toString());
  console.log("");

  // Save deployment info
  const deploymentInfo = {
    network,
    contractAddress: nftminimint.address,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    blockNumber: nftminimint.deployTransaction.blockNumber,
    transactionHash: nftminimint.deployTransaction.hash,
    config: {
      name,
      symbol,
      mintFee: mintFee.toString(),
      maxSupply: maxSupply.toString(),
      maxPerWallet: maxPerWallet.toString()
    }
  };

  // Write deployment info to file
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const deploymentFile = path.join(deploymentsDir, `${network}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  console.log("💾 Deployment info saved to:", deploymentFile);

  // Verify on Etherscan if not localhost
  if (network !== "localhost" && network !== "hardhat") {
    console.log("\n⏳ Waiting for block confirmations...");
    await nftminimint.deployTransaction.wait(5);

    console.log("🔍 Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: nftminimint.address,
        constructorArguments: []
      });
      console.log("✅ Contract verified on Etherscan!");
    } catch (error) {
      if (error.message.includes("Already Verified")) {
        console.log("ℹ️  Contract already verified");
      } else {
        console.log("⚠️  Verification failed:", error.message);
      }
    }
  }

  console.log("\n🎉 Deployment complete!\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
