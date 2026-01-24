/**
 * @title Deploy All Contracts to Base Mainnet
 * @notice Deploys all 5 contracts in correct order and links them
 * @dev Run: node function/deploy-base.js
 */

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });

// Base mainnet config
const BASE_RPC = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const PRIVATE_KEY = process.env.WALLET_1_PRIVATE_KEY;

// Collection config - CUSTOMIZE THESE
const CONFIG = {
  name: "NFTminimint",
  symbol: "MINT",
  maxSupply: 10000
};

async function main() {
  console.log("\n🚀 NFTminimint Base Mainnet Deployment\n");
  console.log("=".repeat(50));

  // Setup provider and wallet
  const provider = new ethers.JsonRpcProvider(BASE_RPC);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  
  // Check network
  const network = await provider.getNetwork();
  console.log(`\n📡 Network: Base (Chain ID: ${network.chainId})`);
  
  // Check balance
  const balance = await provider.getBalance(wallet.address);
  console.log(`💰 Deployer: ${wallet.address}`);
  console.log(`💵 Balance: ${ethers.formatEther(balance)} ETH\n`);

  if (balance < ethers.parseEther("0.01")) {
    console.log("❌ Insufficient balance. Need at least 0.01 ETH for deployment.");
    process.exit(1);
  }

  // Load compiled contracts from Hardhat artifacts
  const artifactsPath = path.join(__dirname, "..", "artifacts", "contracts");
  
  const loadArtifact = (name) => {
    const artifactPath = path.join(artifactsPath, `${name}.sol`, `${name}.json`);
    if (!fs.existsSync(artifactPath)) {
      throw new Error(`Artifact not found: ${artifactPath}. Run 'npx hardhat compile' first.`);
    }
    return JSON.parse(fs.readFileSync(artifactPath, "utf8"));
  };

  console.log("📦 Loading contract artifacts...");
  const NFTCoreArtifact = loadArtifact("NFTCore");
  const NFTMetadataArtifact = loadArtifact("NFTMetadata");
  const NFTAccessArtifact = loadArtifact("NFTAccess");
  const NFTCollectionArtifact = loadArtifact("NFTCollection");
  const NFTminimintArtifact = loadArtifact("NFTminimint");

  const deployedAddresses = {};

  // 1. Deploy NFTCore
  console.log("\n[1/5] Deploying NFTCore...");
  const NFTCoreFactory = new ethers.ContractFactory(
    NFTCoreArtifact.abi,
    NFTCoreArtifact.bytecode,
    wallet
  );
  const nftCore = await NFTCoreFactory.deploy(CONFIG.name, CONFIG.symbol);
  await nftCore.waitForDeployment();
  deployedAddresses.NFTCore = await nftCore.getAddress();
  console.log(`   ✅ NFTCore deployed: ${deployedAddresses.NFTCore}`);

  // 2. Deploy NFTMetadata
  console.log("\n[2/5] Deploying NFTMetadata...");
  const NFTMetadataFactory = new ethers.ContractFactory(
    NFTMetadataArtifact.abi,
    NFTMetadataArtifact.bytecode,
    wallet
  );
  const nftMetadata = await NFTMetadataFactory.deploy(deployedAddresses.NFTCore);
  await nftMetadata.waitForDeployment();
  deployedAddresses.NFTMetadata = await nftMetadata.getAddress();
  console.log(`   ✅ NFTMetadata deployed: ${deployedAddresses.NFTMetadata}`);

  // 3. Deploy NFTAccess
  console.log("\n[3/5] Deploying NFTAccess...");
  const NFTAccessFactory = new ethers.ContractFactory(
    NFTAccessArtifact.abi,
    NFTAccessArtifact.bytecode,
    wallet
  );
  const nftAccess = await NFTAccessFactory.deploy(deployedAddresses.NFTCore);
  await nftAccess.waitForDeployment();
  deployedAddresses.NFTAccess = await nftAccess.getAddress();
  console.log(`   ✅ NFTAccess deployed: ${deployedAddresses.NFTAccess}`);

  // 4. Deploy NFTCollection
  console.log("\n[4/5] Deploying NFTCollection...");
  const NFTCollectionFactory = new ethers.ContractFactory(
    NFTCollectionArtifact.abi,
    NFTCollectionArtifact.bytecode,
    wallet
  );
  const nftCollection = await NFTCollectionFactory.deploy(
    deployedAddresses.NFTCore,
    CONFIG.maxSupply
  );
  await nftCollection.waitForDeployment();
  deployedAddresses.NFTCollection = await nftCollection.getAddress();
  console.log(`   ✅ NFTCollection deployed: ${deployedAddresses.NFTCollection}`);

  // 5. Deploy NFTminimint (main controller)
  console.log("\n[5/5] Deploying NFTminimint...");
  const NFTminimintFactory = new ethers.ContractFactory(
    NFTminimintArtifact.abi,
    NFTminimintArtifact.bytecode,
    wallet
  );
  const nftminimint = await NFTminimintFactory.deploy(
    deployedAddresses.NFTCore,
    deployedAddresses.NFTMetadata,
    deployedAddresses.NFTAccess,
    deployedAddresses.NFTCollection
  );
  await nftminimint.waitForDeployment();
  deployedAddresses.NFTminimint = await nftminimint.getAddress();
  console.log(`   ✅ NFTminimint deployed: ${deployedAddresses.NFTminimint}`);

  // Link contracts
  console.log("\n🔗 Linking contracts...");
  
  // Authorize NFTminimint as minter in NFTCore
  console.log("   - Authorizing NFTminimint as minter in NFTCore...");
  const authMintTx = await nftCore.authorizeMinter(deployedAddresses.NFTminimint);
  await authMintTx.wait();
  console.log("   ✅ NFTminimint authorized as minter");

  // Authorize NFTminimint as caller in NFTAccess
  console.log("   - Authorizing NFTminimint as caller in NFTAccess...");
  const authCallTx = await nftAccess.authorizeCaller(deployedAddresses.NFTminimint);
  await authCallTx.wait();
  console.log("   ✅ NFTminimint authorized as caller");

  // Save deployment info
  console.log("\n💾 Saving deployment info...");
  
  const deploymentInfo = {
    network: "base",
    chainId: 8453,
    deployer: wallet.address,
    timestamp: new Date().toISOString(),
    config: CONFIG,
    contracts: deployedAddresses
  };

  // Save to deployments folder
  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  fs.writeFileSync(
    path.join(deploymentsDir, "base.json"),
    JSON.stringify(deploymentInfo, null, 2)
  );

  // Also append to .env for easy access
  const envAdditions = `
# ============================================
# DEPLOYED CONTRACT ADDRESSES (Base Mainnet)
# ============================================
NFTCORE_ADDRESS=${deployedAddresses.NFTCore}
NFTMETADATA_ADDRESS=${deployedAddresses.NFTMetadata}
NFTACCESS_ADDRESS=${deployedAddresses.NFTAccess}
NFTCOLLECTION_ADDRESS=${deployedAddresses.NFTCollection}
NFTMINIMINT_ADDRESS=${deployedAddresses.NFTminimint}
`;

  fs.appendFileSync(path.join(__dirname, ".env"), envAdditions);

  console.log("\n" + "=".repeat(50));
  console.log("🎉 DEPLOYMENT COMPLETE!\n");
  console.log("Contract Addresses:");
  console.log("  NFTCore:       ", deployedAddresses.NFTCore);
  console.log("  NFTMetadata:   ", deployedAddresses.NFTMetadata);
  console.log("  NFTAccess:     ", deployedAddresses.NFTAccess);
  console.log("  NFTCollection: ", deployedAddresses.NFTCollection);
  console.log("  NFTminimint:   ", deployedAddresses.NFTminimint);
  console.log("\n💾 Saved to: deployments/base.json");
  console.log("💾 Appended to: function/.env");
  console.log("=".repeat(50) + "\n");

  return deployedAddresses;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:", error);
    process.exit(1);
  });
