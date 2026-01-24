/**
 * Write Transactions with ALL wallets that have enough ETH
 * Each wallet performs multiple gas-costing transactions
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

dotenv.config({ path: path.join(__dirname, ".env") });

const RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(RPC_URL);

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Minimum balance to participate (covers ~2-3 transactions)
const MIN_BALANCE = ethers.parseUnits("0.000015", "ether");

// ABIs
const NFTminimintABI = [
  "function mint(string memory uri) external returns (uint256)",
  "function mintTo(address to, string memory uri) external returns (uint256)",
];

const NFTCoreABI = [
  "function transferFrom(address from, address to, uint256 tokenId) external",
  "function approve(address to, uint256 tokenId) external",
  "function setApprovalForAll(address operator, bool approved) external",
  "function ownerOf(uint256 tokenId) external view returns (address)",
  "function balanceOf(address owner) external view returns (uint256)",
  "function totalSupply() external view returns (uint256)",
];

async function main() {
  console.log("\n🔥 WRITE TRANSACTIONS - ALL ELIGIBLE WALLETS\n");
  console.log("=".repeat(65));
  
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
  
  // Contract addresses
  const addresses = {
    NFTCore: process.env.NFTCORE_ADDRESS,
    NFTminimint: process.env.NFTMINIMINT_ADDRESS,
  };

  // Get gas price
  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice;
  console.log(`⛽ Gas Price: ${ethers.formatUnits(gasPrice, "gwei")} gwei`);
  console.log(`💰 Min Balance Required: ${ethers.formatEther(MIN_BALANCE)} ETH\n`);

  // Check balances and find eligible wallets
  console.log("📊 WALLET ELIGIBILITY CHECK:\n");
  const eligibleWallets = [];
  const initialBalances = {};
  
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    initialBalances[w.id] = bal;
    const eligible = bal >= MIN_BALANCE;
    const status = eligible ? "✅ ELIGIBLE" : "❌ Low balance";
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal).padEnd(22)} ETH | ${status}`);
    if (eligible) eligibleWallets.push(w);
    await delay(100);
  }

  console.log(`\n   📋 ${eligibleWallets.length} wallets eligible for transactions\n`);
  console.log("=".repeat(65));

  // Contracts
  const minimint = new ethers.Contract(addresses.NFTminimint, NFTminimintABI, provider);
  const nftCore = new ethers.Contract(addresses.NFTCore, NFTCoreABI, provider);

  // Track results
  let totalGasUsed = 0n;
  let totalTxCount = 0;
  const txPerContract = { NFTCore: 0, NFTminimint: 0 };
  const txPerWallet = {};
  const mintedTokens = {}; // wallet id -> array of token IDs

  // Get current supply
  const startSupply = await nftCore.totalSupply();
  console.log(`\n📊 Current NFT Supply: ${startSupply}\n`);

  // ========== PHASE 1: MINT NFTs ==========
  console.log("═".repeat(65));
  console.log("📦 PHASE 1: MINTING NFTs (one per eligible wallet)\n");

  for (const w of eligibleWallets) {
    try {
      const contract = minimint.connect(w.wallet);
      const uri = `ipfs://nftminimint-w${w.id}-${Date.now()}`;
      
      const tx = await contract.mint(uri);
      const receipt = await tx.wait();
      
      // Parse tokenId from Transfer event
      let tokenId = null;
      for (const log of receipt.logs) {
        if (log.topics.length >= 4) {
          tokenId = BigInt(log.topics[3]);
          break;
        }
      }
      
      mintedTokens[w.id] = mintedTokens[w.id] || [];
      mintedTokens[w.id].push(tokenId);
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTminimint++;
      txPerWallet[w.id] = (txPerWallet[w.id] || 0) + 1;
      
      console.log(`   ✅ W${w.id.toString().padStart(2)} minted Token #${tokenId} | Gas: ${receipt.gasUsed}`);
      await delay(800);
    } catch (err) {
      console.log(`   ❌ W${w.id.toString().padStart(2)}: ${err.shortMessage || err.message.slice(0, 60)}`);
    }
  }

  // ========== PHASE 2: setApprovalForAll ==========
  console.log("\n═".repeat(65));
  console.log("📦 PHASE 2: SET APPROVAL FOR ALL (approve W1 as operator)\n");

  for (const w of eligibleWallets.filter(w => w.id !== 1)) {
    const bal = await provider.getBalance(w.address);
    if (bal < ethers.parseUnits("0.000005", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (gas depleted)`);
      continue;
    }

    try {
      const contract = nftCore.connect(w.wallet);
      const tx = await contract.setApprovalForAll(wallets[0].address, true);
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      txPerWallet[w.id] = (txPerWallet[w.id] || 0) + 1;
      
      console.log(`   ✅ W${w.id.toString().padStart(2)} approved W1 as operator | Gas: ${receipt.gasUsed}`);
      await delay(800);
    } catch (err) {
      console.log(`   ❌ W${w.id.toString().padStart(2)}: ${err.shortMessage || err.message.slice(0, 60)}`);
    }
  }

  // ========== PHASE 3: APPROVE specific tokens ==========
  console.log("\n═".repeat(65));
  console.log("📦 PHASE 3: APPROVE SPECIFIC TOKENS\n");

  for (const w of eligibleWallets) {
    const tokens = mintedTokens[w.id];
    if (!tokens || tokens.length === 0) continue;
    
    const bal = await provider.getBalance(w.address);
    if (bal < ethers.parseUnits("0.000005", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (gas depleted)`);
      continue;
    }

    const tokenId = tokens[0];
    // Approve the next wallet (or W1 if last wallet)
    const approveeTo = wallets[(w.id % wallets.length)].address;
    
    try {
      const contract = nftCore.connect(w.wallet);
      const tx = await contract.approve(approveeTo, tokenId);
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      txPerWallet[w.id] = (txPerWallet[w.id] || 0) + 1;
      
      console.log(`   ✅ W${w.id.toString().padStart(2)} approved W${(w.id % wallets.length) + 1} for Token #${tokenId} | Gas: ${receipt.gasUsed}`);
      await delay(800);
    } catch (err) {
      console.log(`   ❌ W${w.id.toString().padStart(2)}: ${err.shortMessage || err.message.slice(0, 60)}`);
    }
  }

  // ========== PHASE 4: TRANSFER NFTs ==========
  console.log("\n═".repeat(65));
  console.log("📦 PHASE 4: TRANSFER NFTs (to next wallet in chain)\n");

  for (let i = 0; i < eligibleWallets.length; i++) {
    const w = eligibleWallets[i];
    const tokens = mintedTokens[w.id];
    if (!tokens || tokens.length === 0) continue;
    
    const bal = await provider.getBalance(w.address);
    if (bal < ethers.parseUnits("0.000005", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (gas depleted)`);
      continue;
    }

    const tokenId = tokens[0];
    // Transfer to next eligible wallet (circular)
    const nextWallet = eligibleWallets[(i + 1) % eligibleWallets.length];
    
    try {
      const contract = nftCore.connect(w.wallet);
      
      // Verify ownership
      const owner = await contract.ownerOf(tokenId);
      if (owner.toLowerCase() !== w.address.toLowerCase()) {
        console.log(`   ⚠️  W${w.id}: Token #${tokenId} no longer owned`);
        continue;
      }
      
      const tx = await contract.transferFrom(w.address, nextWallet.address, tokenId);
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      txPerWallet[w.id] = (txPerWallet[w.id] || 0) + 1;
      
      console.log(`   ✅ W${w.id.toString().padStart(2)} → W${nextWallet.id}: Token #${tokenId} | Gas: ${receipt.gasUsed}`);
      await delay(800);
    } catch (err) {
      console.log(`   ❌ W${w.id.toString().padStart(2)}: ${err.shortMessage || err.message.slice(0, 60)}`);
    }
  }

  // ========== PHASE 5: SECOND MINT (if still have gas) ==========
  console.log("\n═".repeat(65));
  console.log("📦 PHASE 5: SECOND MINT (wallets with remaining gas)\n");

  for (const w of eligibleWallets) {
    const bal = await provider.getBalance(w.address);
    if (bal < ethers.parseUnits("0.000003", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (gas depleted)`);
      continue;
    }

    try {
      const contract = minimint.connect(w.wallet);
      const uri = `ipfs://nftminimint-w${w.id}-round2-${Date.now()}`;
      
      const tx = await contract.mint(uri);
      const receipt = await tx.wait();
      
      let tokenId = null;
      for (const log of receipt.logs) {
        if (log.topics.length >= 4) {
          tokenId = BigInt(log.topics[3]);
          break;
        }
      }
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTminimint++;
      txPerWallet[w.id] = (txPerWallet[w.id] || 0) + 1;
      
      console.log(`   ✅ W${w.id.toString().padStart(2)} minted Token #${tokenId} (2nd) | Gas: ${receipt.gasUsed}`);
      await delay(800);
    } catch (err) {
      console.log(`   ❌ W${w.id.toString().padStart(2)}: ${err.shortMessage || err.message.slice(0, 60)}`);
    }
  }

  // ========== SUMMARY ==========
  console.log("\n" + "═".repeat(65));
  console.log("📊 FINAL SUMMARY\n");
  
  const totalGasCost = ethers.formatEther(totalGasUsed * gasPrice);
  console.log(`   🔢 Total Transactions: ${totalTxCount}`);
  console.log(`   ⛽ Total Gas Used: ${totalGasUsed}`);
  console.log(`   💰 Est. Gas Cost: ~${totalGasCost} ETH\n`);
  
  console.log("📊 TRANSACTIONS PER CONTRACT:");
  for (const [name, count] of Object.entries(txPerContract)) {
    console.log(`   ${name.padEnd(15)} | ${count.toString().padStart(3)} tx |`);
  }
  
  console.log("\n📊 TRANSACTIONS PER WALLET:");
  for (const w of wallets) {
    const count = txPerWallet[w.id] || 0;
    if (count > 0) {
      console.log(`   W${w.id.toString().padStart(2).padEnd(3)} | ${count.toString().padStart(2)} tx |`);
    }
  }
  
  // Final balances
  console.log("\n💰 FINAL BALANCES (with gas spent):\n");
  let totalSpent = 0n;
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    const spent = initialBalances[w.id] - bal;
    const spentStr = spent > 0n ? ` (spent ${ethers.formatEther(spent)} ETH)` : "";
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal).padEnd(24)} ETH${spentStr}`);
    if (spent > 0n) totalSpent += spent;
    await delay(100);
  }
  
  console.log(`\n   💸 TOTAL ETH SPENT ON GAS: ${ethers.formatEther(totalSpent)} ETH`);
  
  // Final supply
  const endSupply = await nftCore.totalSupply();
  console.log(`   🎨 NFTs Minted This Session: ${endSupply - startSupply}`);
  console.log(`   📈 New Total Supply: ${endSupply}`);
  
  console.log("\n" + "═".repeat(65) + "\n");
}

main().catch(console.error);
