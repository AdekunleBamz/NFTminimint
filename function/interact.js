/**
 * Fund Wallets & Interact with Contracts - Base Mainnet
 * With rate limiting for public RPC
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");
const fs = require("fs");

dotenv.config({ path: path.join(__dirname, ".env") });

const RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Delay helper
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Load ABI helper
function loadABI(name) {
  const p = path.join(__dirname, "..", "artifacts", "contracts", `${name}.sol`, `${name}.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8")).abi;
}

async function main() {
  console.log("\n🚀 WALLET FUNDING & CONTRACT INTERACTION\n");
  console.log("=".repeat(60));
  
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
  
  console.log(`👛 Loaded ${wallets.length} wallets`);
  
  // Contract addresses
  const contracts = {
    NFTCore: process.env.NFTCORE_ADDRESS,
    NFTMetadata: process.env.NFTMETADATA_ADDRESS,
    NFTAccess: process.env.NFTACCESS_ADDRESS,
    NFTCollection: process.env.NFTCOLLECTION_ADDRESS,
    NFTminimint: process.env.NFTMINIMINT_ADDRESS,
  };
  
  console.log(`📄 Contracts: ${Object.values(contracts).filter(Boolean).length}/5\n`);

  // Check initial balances
  console.log("💰 Initial Balances:");
  let totalBalance = 0n;
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    totalBalance += bal;
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH`);
    await delay(100);
  }
  console.log(`   Total: ${ethers.formatEther(totalBalance)} ETH\n`);

  // View functions per contract
  const VIEW_CALLS = {
    NFTCore: "name",
    NFTMetadata: "baseURI", 
    NFTAccess: "publicMintOpen",
    NFTCollection: "isSoldOut",
    NFTminimint: "VERSION",
  };

  console.log("=".repeat(60));
  console.log("\n🔄 CONTRACT INTERACTIONS (1 call per wallet per contract)\n");

  let totalSuccess = 0;
  let totalFail = 0;
  let round = 1;
  let keepGoing = true;

  while (keepGoing && round <= 5) {
    console.log(`--- Round ${round} ---\n`);
    let roundSuccess = 0;

    for (const w of wallets) {
      // Check balance
      const bal = await provider.getBalance(w.address);
      if (bal < ethers.parseUnits("0.00001", "ether")) {
        console.log(`   W${w.id}: Skipping (low balance)`);
        continue;
      }

      for (const [contractName, addr] of Object.entries(contracts)) {
        if (!addr) continue;
        
        const abi = loadABI(contractName);
        if (!abi) continue;
        
        const funcName = VIEW_CALLS[contractName];
        if (!funcName) continue;

        const contract = new ethers.Contract(addr, abi, w.wallet);
        
        try {
          const result = await contract[funcName]();
          roundSuccess++;
          totalSuccess++;
          
          const display = String(result).substring(0, 25);
          console.log(`   ✅ W${w.id.toString().padStart(2)} → ${contractName}.${funcName}() = ${display}`);
        } catch (err) {
          totalFail++;
          // Silent fail - RPC rate limit
        }
        
        // Rate limit: 200ms between calls
        await delay(200);
      }
    }

    console.log(`\n   Round ${round}: ${roundSuccess} successful calls\n`);
    
    // Stop if no successful calls
    if (roundSuccess === 0) {
      keepGoing = false;
    }
    
    round++;
    await delay(500); // Pause between rounds
  }

  // Final summary
  console.log("=".repeat(60));
  console.log("\n📊 FINAL SUMMARY:\n");
  console.log(`   Total Successful Calls: ${totalSuccess}`);
  console.log(`   Total Rounds: ${round - 1}`);
  console.log(`   Calls per Wallet: ~${Math.floor(totalSuccess / wallets.length)}`);

  // Final balances
  console.log("\n💰 Final Balances:");
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH`);
    await delay(100);
  }

  console.log("\n" + "=".repeat(60) + "\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
