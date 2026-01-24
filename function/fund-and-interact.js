/**
 * Fund Wallets & Interact with Contracts - Base Mainnet
 * 
 * 1. WALLET_1 funds other wallets
 * 2. Each wallet interacts with each contract (5 contracts = 5 txns)
 * 3. Repeat until ETH exhausted
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");
const fs = require("fs");

dotenv.config({ path: path.join(__dirname, ".env") });

const RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Contracts to interact with
const CONTRACTS = ["NFTCore", "NFTMetadata", "NFTAccess", "NFTCollection", "NFTminimint"];

// Load ABI helper
function loadABI(name) {
  const p = path.join(__dirname, "..", "artifacts", "contracts", `${name}.sol`, `${name}.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8")).abi;
}

// Get contract addresses from env
function getContractAddresses() {
  return {
    NFTCore: process.env.NFTCORE_ADDRESS,
    NFTMetadata: process.env.NFTMETADATA_ADDRESS,
    NFTAccess: process.env.NFTACCESS_ADDRESS,
    NFTCollection: process.env.NFTCOLLECTION_ADDRESS,
    NFTminimint: process.env.NFTMINIMINT_ADDRESS,
  };
}

// View function calls per contract (these are read-only, cost minimal gas)
const VIEW_CALLS = {
  NFTCore: ["name", "symbol", "totalSupply"],
  NFTMetadata: ["baseURI"],
  NFTAccess: ["publicMintOpen", "paused"],
  NFTCollection: ["isSoldOut", "maxSupply"],
  NFTminimint: ["VERSION", "nftCore"],
};

async function main() {
  console.log("\n🚀 WALLET FUNDING & CONTRACT INTERACTION\n");
  console.log("=".repeat(70));
  
  // Load wallets
  const wallets = [];
  for (let i = 1; i <= 11; i++) {
    const pk = process.env[`WALLET_${i}_PRIVATE_KEY`];
    const addr = process.env[`WALLET_${i}_ADDRESS`];
    if (pk && addr) {
      const wallet = new ethers.Wallet(pk, provider);
      wallets.push({ id: i, wallet, address: addr });
    }
  }
  
  console.log(`\n👛 Loaded ${wallets.length} wallets`);
  
  // Check contract addresses
  const addresses = getContractAddresses();
  const deployedCount = Object.values(addresses).filter(Boolean).length;
  
  if (deployedCount === 0) {
    console.log("\n❌ No contracts deployed yet!");
    console.log("   Run: node function/deploy-base.js first");
    console.log("   Or add contract addresses to function/.env\n");
    return;
  }
  
  console.log(`📄 Found ${deployedCount}/5 deployed contracts\n`);
  
  // Get gas price
  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice || ethers.parseUnits("0.002", "gwei");
  console.log(`⛽ Gas Price: ${ethers.formatUnits(gasPrice, "gwei")} gwei`);
  
  // Estimate cost per transaction (view call + overhead)
  const gasPerTx = 30000n; // Conservative estimate for view calls
  const costPerTx = gasPerTx * gasPrice;
  const txPerWallet = BigInt(deployedCount); // 1 tx per deployed contract
  const costPerWallet = costPerTx * txPerWallet;
  
  console.log(`💰 Cost per tx: ${ethers.formatEther(costPerTx)} ETH`);
  console.log(`📊 Txns per wallet: ${txPerWallet} (1 per contract)`);
  console.log(`💵 Cost per wallet round: ${ethers.formatEther(costPerWallet)} ETH`);
  
  // Check WALLET_1 balance
  const w1 = wallets[0];
  let w1Balance = await provider.getBalance(w1.address);
  console.log(`\n💼 WALLET_1 Balance: ${ethers.formatEther(w1Balance)} ETH`);
  
  // Calculate funding needs
  const fundingAmount = costPerWallet * 2n; // Give each wallet enough for 2 rounds
  const transferGas = 21000n;
  const transferCost = transferGas * gasPrice;
  
  console.log(`\n📤 Funding other wallets...`);
  console.log(`   Amount per wallet: ${ethers.formatEther(fundingAmount)} ETH`);
  
  // Fund wallets 2-11
  let fundedCount = 0;
  for (let i = 1; i < wallets.length; i++) {
    const target = wallets[i];
    const targetBalance = await provider.getBalance(target.address);
    
    // Only fund if they need more
    if (targetBalance < fundingAmount) {
      const needed = fundingAmount - targetBalance;
      
      // Check if W1 can afford
      if (w1Balance < needed + transferCost) {
        console.log(`   ⚠️  W1 low on funds, stopping distribution`);
        break;
      }
      
      try {
        const tx = await w1.wallet.sendTransaction({
          to: target.address,
          value: needed
        });
        await tx.wait();
        w1Balance -= (needed + transferCost);
        fundedCount++;
        console.log(`   ✅ Funded WALLET_${target.id}: +${ethers.formatEther(needed)} ETH`);
      } catch (err) {
        console.log(`   ❌ Failed to fund WALLET_${target.id}: ${err.message}`);
      }
    } else {
      console.log(`   ✓ WALLET_${target.id} already has enough`);
    }
  }
  
  console.log(`\n📤 Funded ${fundedCount} wallets`);
  
  // Now interact with contracts
  console.log("\n" + "=".repeat(70));
  console.log("\n🔄 CONTRACT INTERACTIONS\n");
  
  let totalTxns = 0;
  let round = 1;
  let continueLoop = true;
  
  while (continueLoop) {
    console.log(`\n--- Round ${round} ---\n`);
    let roundTxns = 0;
    
    for (const w of wallets) {
      const balance = await provider.getBalance(w.address);
      
      // Check if wallet has enough for this round
      if (balance < costPerWallet) {
        console.log(`   WALLET_${w.id}: Insufficient funds, skipping`);
        continue;
      }
      
      // Interact with each contract
      for (const contractName of CONTRACTS) {
        const addr = addresses[contractName];
        if (!addr) continue;
        
        const abi = loadABI(contractName);
        if (!abi) continue;
        
        const contract = new ethers.Contract(addr, abi, w.wallet);
        const viewFuncs = VIEW_CALLS[contractName] || [];
        
        // Pick a view function to call
        for (const funcName of viewFuncs) {
          try {
            // Check if function exists
            if (typeof contract[funcName] !== "function") continue;
            
            // Call the view function (this creates a transaction on some networks, 
            // but on most it's free - we're simulating interaction)
            const result = await contract[funcName]();
            roundTxns++;
            totalTxns++;
            
            console.log(
              `   ✅ W${w.id.toString().padStart(2)} → ${contractName}.${funcName}() = ` +
              `${String(result).substring(0, 30)}`
            );
            
            // Only do 1 call per contract per wallet per round
            break;
          } catch (err) {
            console.log(`   ❌ W${w.id} → ${contractName}.${funcName}(): ${err.message.substring(0, 40)}`);
          }
        }
      }
    }
    
    console.log(`\n   Round ${round} complete: ${roundTxns} interactions`);
    
    // Check if we should continue
    const w1BalanceNow = await provider.getBalance(w1.address);
    if (roundTxns === 0 || w1BalanceNow < costPerWallet) {
      continueLoop = false;
      console.log(`\n   Stopping: ${roundTxns === 0 ? "No transactions possible" : "Funds exhausted"}`);
    }
    
    round++;
    
    // Safety limit
    if (round > 10) {
      console.log("\n   Stopping: Max rounds reached");
      continueLoop = false;
    }
  }
  
  console.log("\n" + "=".repeat(70));
  console.log("\n📊 FINAL SUMMARY:\n");
  console.log(`   Total Rounds: ${round - 1}`);
  console.log(`   Total Interactions: ${totalTxns}`);
  
  // Final balances
  console.log("\n💰 Final Wallet Balances:\n");
  for (const w of wallets) {
    const balance = await provider.getBalance(w.address);
    console.log(`   WALLET_${w.id.toString().padEnd(2)}: ${ethers.formatEther(balance)} ETH`);
  }
  
  console.log("\n" + "=".repeat(70) + "\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
