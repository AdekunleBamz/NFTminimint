/**
 * Gas Estimation for Contract Interactions - Base Mainnet
 * Estimates gas costs for each wallet to interact with each contract once
 */

const path = require("path");
const fs = require("fs");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

dotenv.config({ path: path.join(__dirname, ".env") });

const rpcUrl = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(rpcUrl);

// Load ABIs
function loadABI(contractName) {
  const artifactPath = path.join(
    __dirname, "..", "artifacts", "contracts",
    `${contractName}.sol`, `${contractName}.json`
  );
  if (!fs.existsSync(artifactPath)) return null;
  return JSON.parse(fs.readFileSync(artifactPath, "utf8")).abi;
}

// Contract interactions to estimate
const INTERACTIONS = {
  NFTminimint: {
    name: "Main Minting Contract",
    methods: [
      { name: "mint", type: "write", gas: 150000, desc: "Mint 1 NFT" },
      { name: "batchMint", type: "write", gas: 300000, desc: "Batch mint (3 NFTs)" },
    ]
  },
  NFTCore: {
    name: "Core ERC721",
    methods: [
      { name: "name", type: "view", gas: 25000, desc: "Read name" },
      { name: "totalSupply", type: "view", gas: 25000, desc: "Read supply" },
      { name: "transferFrom", type: "write", gas: 65000, desc: "Transfer NFT" },
      { name: "approve", type: "write", gas: 50000, desc: "Approve operator" },
    ]
  },
  NFTAccess: {
    name: "Access Control",
    methods: [
      { name: "canMint", type: "view", gas: 30000, desc: "Check mint eligibility" },
      { name: "remainingMints", type: "view", gas: 25000, desc: "Check remaining" },
    ]
  },
  NFTCollection: {
    name: "Collection Manager", 
    methods: [
      { name: "getStats", type: "view", gas: 30000, desc: "Get stats" },
      { name: "isSoldOut", type: "view", gas: 25000, desc: "Check sold out" },
    ]
  },
  NFTMetadata: {
    name: "Metadata Manager",
    methods: [
      { name: "baseURI", type: "view", gas: 25000, desc: "Read base URI" },
    ]
  }
};

async function main() {
  console.log("\n⛽ GAS ESTIMATION - Base Mainnet\n");
  console.log("=".repeat(70));

  // Get current gas price
  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice || ethers.parseUnits("0.001", "gwei");
  console.log(`\n📡 Chain ID: 8453 (Base)`);
  console.log(`⛽ Gas Price: ${ethers.formatUnits(gasPrice, "gwei")} gwei`);

  // Collect wallets
  const wallets = [];
  for (let i = 1; i <= 11; i++) {
    const address = process.env[`WALLET_${i}_ADDRESS`];
    if (address) {
      const balance = await provider.getBalance(address);
      wallets.push({ id: i, address, balance });
    }
  }

  console.log(`\n👛 Wallets: ${wallets.length}\n`);

  // Estimate gas for each contract interaction
  console.log("📊 GAS ESTIMATES PER INTERACTION:\n");
  
  let totalGasPerWallet = 0n;
  
  for (const [contract, config] of Object.entries(INTERACTIONS)) {
    console.log(`📄 ${contract} (${config.name}):`);
    
    for (const method of config.methods) {
      const gas = BigInt(method.gas);
      const cost = gas * gasPrice;
      totalGasPerWallet += gas;
      
      const icon = method.type === "view" ? "👁️ " : "✍️ ";
      console.log(
        `   ${icon}${method.name.padEnd(18)} | ` +
        `${method.gas.toString().padStart(7)} gas | ` +
        `${ethers.formatEther(cost).substring(0, 12).padStart(12)} ETH | ` +
        `${method.desc}`
      );
    }
    console.log();
  }

  // Calculate total cost per wallet (for typical interaction: 1 mint)
  const mintGas = 150000n;
  const mintCost = mintGas * gasPrice;
  
  // Full interaction (all methods once)
  const fullCost = totalGasPerWallet * gasPrice;

  console.log("=".repeat(70));
  console.log("\n💰 COST SUMMARY:\n");
  console.log(`   Single Mint:        ${mintGas.toString().padStart(10)} gas = ${ethers.formatEther(mintCost)} ETH`);
  console.log(`   Full Interaction:   ${totalGasPerWallet.toString().padStart(10)} gas = ${ethers.formatEther(fullCost)} ETH`);
  console.log(`   × ${wallets.length} wallets:        ${(totalGasPerWallet * BigInt(wallets.length)).toString().padStart(10)} gas = ${ethers.formatEther(fullCost * BigInt(wallets.length))} ETH`);

  // Check each wallet's readiness
  console.log("\n" + "=".repeat(70));
  console.log("\n🔍 WALLET READINESS (for 1 mint each):\n");

  let readyCount = 0;
  let totalShortfall = 0n;

  for (const wallet of wallets) {
    const canMint = wallet.balance >= mintCost;
    const status = canMint ? "✅ Ready" : "❌ Needs funds";
    
    if (canMint) readyCount++;
    else totalShortfall += mintCost - wallet.balance;

    console.log(
      `   WALLET_${wallet.id.toString().padEnd(2)} | ` +
      `${ethers.formatEther(wallet.balance).substring(0, 12).padStart(12)} ETH | ` +
      `${status}`
    );
  }

  // WALLET_1 funding analysis
  console.log("\n" + "=".repeat(70));
  console.log("\n💼 WALLET_1 FUNDING ANALYSIS:\n");

  const w1 = wallets[0];
  const fundingBuffer = ethers.parseEther("0.0001"); // Buffer per wallet for gas
  const perWalletNeed = mintCost + fundingBuffer;
  const toFundOthers = perWalletNeed * BigInt(wallets.length - 1);
  const w1OwnNeed = mintCost;
  const totalNeeded = toFundOthers + w1OwnNeed;

  console.log(`   Current WALLET_1 Balance:  ${ethers.formatEther(w1.balance)} ETH`);
  console.log(`   Cost per mint:             ${ethers.formatEther(mintCost)} ETH`);
  console.log(`   Per wallet (mint+buffer):  ${ethers.formatEther(perWalletNeed)} ETH`);
  console.log(`   To fund 10 other wallets:  ${ethers.formatEther(toFundOthers)} ETH`);
  console.log(`   WALLET_1 own mint:         ${ethers.formatEther(w1OwnNeed)} ETH`);
  console.log(`   TOTAL NEEDED:              ${ethers.formatEther(totalNeeded)} ETH`);

  console.log();
  
  if (w1.balance >= totalNeeded) {
    console.log("   ✅ WALLET_1 has SUFFICIENT funds to:");
    console.log("      - Fund all 10 other wallets");
    console.log("      - Perform its own mint");
    const surplus = w1.balance - totalNeeded;
    console.log(`      - Surplus: ${ethers.formatEther(surplus)} ETH`);
  } else {
    const shortfall = totalNeeded - w1.balance;
    console.log("   ⚠️  WALLET_1 needs MORE ETH");
    console.log(`   💸 Add at least: ${ethers.formatEther(shortfall)} ETH`);
    console.log(`   📍 Recommended:  ${ethers.formatEther(shortfall + ethers.parseEther("0.001"))} ETH (with buffer)`);
  }

  console.log("\n" + "=".repeat(70) + "\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
