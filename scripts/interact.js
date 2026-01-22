const hre = require("hardhat");

/**
 * Interact with deployed NFTminimint contract
 * Usage: npx hardhat run scripts/interact.js --network localhost
 */

async function main() {
  const contractAddress = process.env.CONTRACT_ADDRESS || "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  
  console.log("\n📡 Connecting to NFTminimint at:", contractAddress);
  console.log("   Network:", hre.network.name);
  console.log("");

  // Get contract instance
  const NFTminimint = await hre.ethers.getContractFactory("NFTminimint");
  const nftminimint = NFTminimint.attach(contractAddress);

  // Get signers
  const [owner, user1] = await hre.ethers.getSigners();

  // Read contract info
  console.log("📊 Contract Info:");
  console.log("  Name:", await nftminimint.name());
  console.log("  Symbol:", await nftminimint.symbol());
  console.log("  Owner:", await nftminimint.owner());
  console.log("  Total Supply:", (await nftminimint.totalSupply()).toString());
  console.log("  Max Supply:", (await nftminimint.maxSupply()).toString());
  console.log("  Remaining:", (await nftminimint.remainingSupply()).toString());
  console.log("  Mint Fee:", hre.ethers.utils.formatEther(await nftminimint.mintFee()), "ETH");
  console.log("  Max Per Wallet:", (await nftminimint.maxPerWallet()).toString());
  console.log("  Paused:", await nftminimint.paused());
  console.log("");

  // Check user status
  console.log("👤 User Status (", user1.address, "):");
  console.log("  Minted:", (await nftminimint.mintedByWallet(user1.address)).toString());
  console.log("  Remaining:", (await nftminimint.remainingForWallet(user1.address)).toString());
  console.log("  Can Mint:", await nftminimint.canMint(user1.address));
  console.log("");

  // Example: Mint an NFT
  const shouldMint = process.env.MINT === "true";
  if (shouldMint) {
    console.log("🎨 Minting NFT...");
    const mintFee = await nftminimint.mintFee();
    const tokenURI = "https://example.com/metadata/1.json";

    const tx = await nftminimint.connect(user1).mintNFT(user1.address, tokenURI, { value: mintFee });
    const receipt = await tx.wait();

    const mintEvent = receipt.events?.find(e => e.event === "NFTMinted");
    console.log("✅ Minted token ID:", mintEvent?.args?.tokenId?.toString());
    console.log("   TX Hash:", receipt.transactionHash);
    console.log("");
  }

  // Example: Batch mint
  const shouldBatchMint = process.env.BATCH_MINT === "true";
  if (shouldBatchMint) {
    console.log("🎨 Batch minting NFTs...");
    const mintFee = await nftminimint.mintFee();
    const tokenURIs = [
      "https://example.com/metadata/1.json",
      "https://example.com/metadata/2.json",
      "https://example.com/metadata/3.json"
    ];
    const totalCost = mintFee.mul(tokenURIs.length);

    const tx = await nftminimint.connect(user1).batchMint(user1.address, tokenURIs, { value: totalCost });
    const receipt = await tx.wait();

    console.log("✅ Batch minted", tokenURIs.length, "NFTs");
    console.log("   TX Hash:", receipt.transactionHash);
    console.log("");
  }

  console.log("🎉 Interaction complete!\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
