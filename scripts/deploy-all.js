const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting NFTminimint deployment...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.address)).toString());
  console.log("");

  // Configuration
  const COLLECTION_NAME = "MiniMint Collection";
  const COLLECTION_SYMBOL = "MINT";
  const MAX_SUPPLY = 10000;

  // Step 1: Deploy NFTCore
  console.log("📦 Step 1/5: Deploying NFTCore...");
  const NFTCore = await hre.ethers.getContractFactory("NFTCore");
  const nftCore = await NFTCore.deploy(COLLECTION_NAME, COLLECTION_SYMBOL);
  await nftCore.waitForDeployment();
  const nftCoreAddress = await nftCore.getAddress();
  console.log("✅ NFTCore deployed to:", nftCoreAddress);
  console.log("");

  // Step 2: Deploy NFTMetadata
  console.log("📦 Step 2/5: Deploying NFTMetadata...");
  const NFTMetadata = await hre.ethers.getContractFactory("NFTMetadata");
  const nftMetadata = await NFTMetadata.deploy(nftCoreAddress);
  await nftMetadata.waitForDeployment();
  const nftMetadataAddress = await nftMetadata.getAddress();
  console.log("✅ NFTMetadata deployed to:", nftMetadataAddress);
  console.log("");

  // Step 3: Deploy NFTAccess
  console.log("📦 Step 3/5: Deploying NFTAccess...");
  const NFTAccess = await hre.ethers.getContractFactory("NFTAccess");
  const nftAccess = await NFTAccess.deploy(nftCoreAddress);
  await nftAccess.waitForDeployment();
  const nftAccessAddress = await nftAccess.getAddress();
  console.log("✅ NFTAccess deployed to:", nftAccessAddress);
  console.log("");

  // Step 4: Deploy NFTCollection
  console.log("📦 Step 4/5: Deploying NFTCollection...");
  const NFTCollection = await hre.ethers.getContractFactory("NFTCollection");
  const nftCollection = await NFTCollection.deploy(nftCoreAddress, MAX_SUPPLY);
  await nftCollection.waitForDeployment();
  const nftCollectionAddress = await nftCollection.getAddress();
  console.log("✅ NFTCollection deployed to:", nftCollectionAddress);
  console.log("");

  // Step 5: Deploy NFTminimint
  console.log("📦 Step 5/5: Deploying NFTminimint...");
  const NFTminimint = await hre.ethers.getContractFactory("NFTminimint");
  const nftMinimint = await NFTminimint.deploy(
    nftCoreAddress,
    nftMetadataAddress,
    nftAccessAddress,
    nftCollectionAddress
  );
  await nftMinimint.waitForDeployment();
  const nftMinimintAddress = await nftMinimint.getAddress();
  console.log("✅ NFTminimint deployed to:", nftMinimintAddress);
  console.log("");

  // Return addresses for linking
  return {
    nftCore: nftCoreAddress,
    nftMetadata: nftMetadataAddress,
    nftAccess: nftAccessAddress,
    nftCollection: nftCollectionAddress,
    nftMinimint: nftMinimintAddress
  };
}

main()
  .then((addresses) => {
    console.log("═══════════════════════════════════════");
    console.log("🎉 All contracts deployed successfully!");
    console.log("═══════════════════════════════════════");
    console.log("\nContract Addresses:");
    console.log("NFTCore:       ", addresses.nftCore);
    console.log("NFTMetadata:   ", addresses.nftMetadata);
    console.log("NFTAccess:     ", addresses.nftAccess);
    console.log("NFTCollection: ", addresses.nftCollection);
    console.log("NFTminimint:   ", addresses.nftMinimint);
    console.log("\n⚠️  Don't forget to run the link script next!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
