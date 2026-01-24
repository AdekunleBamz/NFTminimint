const hre = require("hardhat");

/**
 * Royalty configuration script
 */
async function main() {
  console.log("💰 Royalty Configuration\n");

  // Configure
  const NFTCOLLECTION_ADDRESS = process.env.NFTCOLLECTION_ADDRESS || "YOUR_ADDRESS";
  
  // Royalty settings (in basis points: 500 = 5%)
  const ROYALTY_RECEIVER = process.env.ROYALTY_RECEIVER || "YOUR_WALLET";
  const ROYALTY_FEE = 500; // 5%

  if (NFTCOLLECTION_ADDRESS.includes("YOUR_")) {
    console.log("❌ Please set NFTCOLLECTION_ADDRESS!");
    process.exit(1);
  }

  const [deployer] = await hre.ethers.getSigners();
  console.log("Configuring with account:", deployer.address);
  console.log("");

  const nftCollection = await hre.ethers.getContractAt("NFTCollection", NFTCOLLECTION_ADDRESS);

  // Set default royalty
  console.log(`Setting default royalty to ${ROYALTY_FEE / 100}%...`);
  console.log(`Receiver: ${ROYALTY_RECEIVER}`);
  
  const tx = await nftCollection.setDefaultRoyalty(ROYALTY_RECEIVER, ROYALTY_FEE);
  await tx.wait();
  
  console.log("✅ Royalty configured. Tx:", tx.hash);
  console.log("");

  // Verify
  const salePrice = hre.ethers.parseEther("1"); // 1 ETH sale
  const [receiver, amount] = await nftCollection.royaltyInfo(1, salePrice);
  
  console.log("Verification (for 1 ETH sale):");
  console.log(`  Receiver: ${receiver}`);
  console.log(`  Royalty: ${hre.ethers.formatEther(amount)} ETH`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Configuration failed:", error);
    process.exit(1);
  });
