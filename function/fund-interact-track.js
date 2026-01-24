/**
 * Fund Low-Balance Wallets & Track Contract Interactions
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");
const fs = require("fs");

dotenv.config({ path: path.join(__dirname, ".env") });

const RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(RPC_URL);

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

function loadABI(name) {
  const p = path.join(__dirname, "..", "artifacts", "contracts", `${name}.sol`, `${name}.json`);
  if (!fs.existsSync(p)) return null;
  return JSON.parse(fs.readFileSync(p, "utf8")).abi;
}

async function main() {
  console.log("\n🚀 FUND & INTERACT WITH TRACKING\n");
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
  
  const w1 = wallets[0];
  
  // Contract addresses
  const contracts = {
    NFTCore: process.env.NFTCORE_ADDRESS,
    NFTMetadata: process.env.NFTMETADATA_ADDRESS,
    NFTAccess: process.env.NFTACCESS_ADDRESS,
    NFTCollection: process.env.NFTCOLLECTION_ADDRESS,
    NFTminimint: process.env.NFTMINIMINT_ADDRESS,
  };

  // Track transactions per contract
  const txCount = {
    NFTCore: 0,
    NFTMetadata: 0,
    NFTAccess: 0,
    NFTCollection: 0,
    NFTminimint: 0,
  };

  // ========== STEP 1: FUND LOW-BALANCE WALLETS ==========
  console.log("\n💸 STEP 1: FUNDING LOW-BALANCE WALLETS\n");
  
  const MIN_BALANCE = ethers.parseUnits("0.00001", "ether");
  const FUND_AMOUNT = ethers.parseUnits("0.00002", "ether"); // Small amount
  
  let w1Balance = await provider.getBalance(w1.address);
  console.log(`   W1 Balance: ${ethers.formatEther(w1Balance)} ETH`);
  
  let funded = 0;
  for (let i = 1; i < wallets.length; i++) {
    const target = wallets[i];
    const bal = await provider.getBalance(target.address);
    
    if (bal < MIN_BALANCE) {
      console.log(`   W${target.id}: ${ethers.formatEther(bal)} ETH (LOW)`);
      
      // Check if W1 can afford
      const gasPrice = (await provider.getFeeData()).gasPrice;
      const txCost = 21000n * gasPrice + FUND_AMOUNT;
      
      if (w1Balance > txCost) {
        try {
          const tx = await w1.wallet.sendTransaction({
            to: target.address,
            value: FUND_AMOUNT
          });
          await tx.wait();
          w1Balance -= txCost;
          funded++;
          console.log(`      ✅ Funded +${ethers.formatEther(FUND_AMOUNT)} ETH`);
          await delay(300);
        } catch (err) {
          console.log(`      ❌ Failed: ${err.message.substring(0, 40)}`);
        }
      } else {
        console.log(`      ⚠️ W1 insufficient for funding`);
      }
    }
    await delay(100);
  }
  
  console.log(`\n   Funded ${funded} wallets`);

  // ========== STEP 2: INTERACT WITH CONTRACTS ==========
  console.log("\n" + "=".repeat(60));
  console.log("\n🔄 STEP 2: CONTRACT INTERACTIONS\n");

  const VIEW_CALLS = {
    NFTCore: ["name", "symbol", "totalSupply"],
    NFTMetadata: ["baseURI"],
    NFTAccess: ["publicMintOpen", "paused", "whitelistEnabled"],
    NFTCollection: ["isSoldOut", "maxSupply"],
    NFTminimint: ["VERSION", "nftCore"],
  };

  let round = 1;
  let keepGoing = true;
  
  while (keepGoing && round <= 3) {
    console.log(`--- Round ${round} ---\n`);
    let roundTx = 0;

    for (const w of wallets) {
      const bal = await provider.getBalance(w.address);
      if (bal < MIN_BALANCE) continue;

      for (const [contractName, addr] of Object.entries(contracts)) {
        if (!addr) continue;
        
        const abi = loadABI(contractName);
        if (!abi) continue;
        
        const funcs = VIEW_CALLS[contractName] || [];
        const contract = new ethers.Contract(addr, abi, w.wallet);
        
        for (const funcName of funcs) {
          try {
            const result = await contract[funcName]();
            txCount[contractName]++;
            roundTx++;
            
            const display = String(result).substring(0, 20);
            console.log(`   ✅ W${w.id.toString().padStart(2)} → ${contractName}.${funcName}() = ${display}`);
            
            break; // 1 call per contract per wallet per round
          } catch (err) {
            // Silent - RPC limit
          }
          await delay(150);
        }
      }
    }

    console.log(`\n   Round ${round}: ${roundTx} calls\n`);
    if (roundTx === 0) keepGoing = false;
    round++;
    await delay(300);
  }

  // ========== SUMMARY ==========
  console.log("=".repeat(60));
  console.log("\n📊 TRANSACTION COUNT PER CONTRACT:\n");
  
  let totalTx = 0;
  for (const [name, count] of Object.entries(txCount)) {
    totalTx += count;
    const bar = "█".repeat(Math.min(count, 30));
    console.log(`   ${name.padEnd(15)} | ${count.toString().padStart(3)} | ${bar}`);
  }
  
  console.log(`   ${"─".repeat(40)}`);
  console.log(`   ${"TOTAL".padEnd(15)} | ${totalTx.toString().padStart(3)} |`);

  // Final balances
  console.log("\n💰 Final Wallet Balances:\n");
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH`);
    await delay(50);
  }

  console.log("\n" + "=".repeat(60) + "\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
