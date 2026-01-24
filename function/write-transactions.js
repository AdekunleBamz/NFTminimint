/**
 * Write Transactions - Costs Gas!
 * Each wallet interacts with contracts using write functions
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

dotenv.config({ path: path.join(__dirname, ".env") });

const RPC_URL = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(RPC_URL);

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Direct ABIs for functions we need
const NFTminimintABI = [
  "function mint(string memory uri) external returns (uint256)",
  "function mintTo(address to, string memory uri) external returns (uint256)",
  "function batchMint(string[] memory uris) external returns (uint256)",
];

const NFTCoreABI = [
  "function transferFrom(address from, address to, uint256 tokenId) external",
  "function safeTransferFrom(address from, address to, uint256 tokenId) external",
  "function approve(address to, uint256 tokenId) external",
  "function setApprovalForAll(address operator, bool approved) external",
  "function ownerOf(uint256 tokenId) external view returns (address)",
  "function balanceOf(address owner) external view returns (uint256)",
  "function totalSupply() external view returns (uint256)",
];

const NFTAccessABI = [
  "function canMint(address account) external view returns (bool, string memory)",
  "function remainingMints(address wallet) external view returns (uint256)",
];

async function main() {
  console.log("\n💸 WRITE TRANSACTIONS (COSTS GAS)\n");
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
  
  // Contract addresses
  const addresses = {
    NFTCore: process.env.NFTCORE_ADDRESS,
    NFTAccess: process.env.NFTACCESS_ADDRESS,
    NFTminimint: process.env.NFTMINIMINT_ADDRESS,
  };

  console.log("📋 Contract Addresses:");
  console.log(`   NFTCore:     ${addresses.NFTCore}`);
  console.log(`   NFTAccess:   ${addresses.NFTAccess}`);
  console.log(`   NFTminimint: ${addresses.NFTminimint}`);

  // Track gas spent
  let totalGasUsed = 0n;
  let totalTxCount = 0;
  const txPerContract = {
    NFTCore: 0,
    NFTminimint: 0,
  };
  const mintedTokens = {}; // Track which tokens each wallet owns

  // Get gas price
  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice;
  console.log(`\n⛽ Gas Price: ${ethers.formatUnits(gasPrice, "gwei")} gwei\n`);

  // Check initial balances
  console.log("💰 Initial Balances:");
  const initialBalances = {};
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    initialBalances[w.id] = bal;
    console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH`);
    await delay(100);
  }

  // Contracts
  const minimint = new ethers.Contract(addresses.NFTminimint, NFTminimintABI, provider);
  const nftCore = new ethers.Contract(addresses.NFTCore, NFTCoreABI, provider);
  const nftAccess = new ethers.Contract(addresses.NFTAccess, NFTAccessABI, provider);

  console.log("\n" + "=".repeat(60));
  console.log("\n🔥 EXECUTING WRITE TRANSACTIONS\n");

  // Get current token ID (to track minted tokens)
  const startSupply = await nftCore.totalSupply();
  console.log(`   📊 Current NFT supply: ${startSupply}\n`);

  // ========== 1. MINT NFTs via NFTminimint ==========
  console.log("📦 [1/4] MINTING NFTs via NFTminimint");
  console.log("   Using mint(uri) - mints to msg.sender\n");

  // Check mint eligibility first
  for (const w of wallets.slice(0, 4)) {  // First 4 wallets with best balances
    try {
      const [canMint, reason] = await nftAccess.canMint(w.address);
      const remaining = await nftAccess.remainingMints(w.address);
      console.log(`   W${w.id}: canMint=${canMint}, remaining=${remaining}, reason="${reason}"`);
    } catch (e) {
      console.log(`   W${w.id}: canMint check failed - ${e.message.slice(0, 40)}`);
    }
    await delay(100);
  }

  console.log("");

  // Try minting with W1 and W2 (have the most ETH)
  for (const w of wallets.slice(0, 2)) {
    const bal = await provider.getBalance(w.address);
    console.log(`   W${w.id} balance: ${ethers.formatEther(bal)} ETH`);
    
    if (bal < ethers.parseUnits("0.00003", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (balance too low)`);
      continue;
    }

    try {
      const contract = minimint.connect(w.wallet);
      const uri = `ipfs://test-wallet-${w.id}-${Date.now()}`;
      
      // Estimate gas first
      const gasEst = await contract.mint.estimateGas(uri);
      console.log(`   W${w.id}: Estimated gas: ${gasEst}`);
      
      // Send transaction
      const tx = await contract.mint(uri);
      console.log(`   W${w.id}: Tx sent: ${tx.hash.slice(0, 20)}...`);
      
      const receipt = await tx.wait();
      
      // Parse logs to get tokenId
      let tokenId = null;
      for (const log of receipt.logs) {
        // Transfer event (ERC721) has tokenId as 3rd topic
        if (log.topics.length >= 4) {
          tokenId = BigInt(log.topics[3]);
          break;
        }
      }
      
      mintedTokens[w.id] = tokenId;
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTminimint++;
      
      const gasCost = ethers.formatEther(receipt.gasUsed * gasPrice);
      console.log(`   ✅ W${w.id} minted Token #${tokenId} | Gas: ${receipt.gasUsed} (~${gasCost} ETH)`);
      console.log(`      Tx: https://basescan.org/tx/${tx.hash}\n`);
      
      await delay(1000);
    } catch (err) {
      console.log(`   ❌ W${w.id}: ${err.shortMessage || err.message.substring(0, 80)}\n`);
    }
  }

  // ========== 2. setApprovalForAll via NFTCore ==========
  console.log("\n📦 [2/4] SET APPROVAL FOR ALL via NFTCore");
  console.log("   Approving W1 as operator for all NFTs\n");

  for (const w of wallets.slice(1, 3)) {  // W2, W3
    const bal = await provider.getBalance(w.address);
    if (bal < ethers.parseUnits("0.00002", "ether")) {
      console.log(`   ⏩ W${w.id}: Skipping (balance too low)`);
      continue;
    }

    try {
      const contract = nftCore.connect(w.wallet);
      
      // Estimate gas
      const gasEst = await contract.setApprovalForAll.estimateGas(wallets[0].address, true);
      console.log(`   W${w.id}: Estimated gas: ${gasEst}`);
      
      const tx = await contract.setApprovalForAll(wallets[0].address, true);
      console.log(`   W${w.id}: Tx sent: ${tx.hash.slice(0, 20)}...`);
      
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      
      const gasCost = ethers.formatEther(receipt.gasUsed * gasPrice);
      console.log(`   ✅ W${w.id} approved W1 for all | Gas: ${receipt.gasUsed} (~${gasCost} ETH)`);
      console.log(`      Tx: https://basescan.org/tx/${tx.hash}\n`);
      
      await delay(1000);
    } catch (err) {
      console.log(`   ❌ W${w.id}: ${err.shortMessage || err.message.substring(0, 80)}\n`);
    }
  }

  // ========== 3. APPROVE specific token via NFTCore ==========
  console.log("\n📦 [3/4] APPROVE SPECIFIC TOKEN via NFTCore\n");

  // If W1 minted a token, approve W2 for it
  if (mintedTokens[1] !== undefined) {
    const w = wallets[0];  // W1
    const tokenId = mintedTokens[1];
    
    try {
      const contract = nftCore.connect(w.wallet);
      
      const gasEst = await contract.approve.estimateGas(wallets[1].address, tokenId);
      console.log(`   W1: Approving W2 for Token #${tokenId}, est gas: ${gasEst}`);
      
      const tx = await contract.approve(wallets[1].address, tokenId);
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      
      console.log(`   ✅ W1 approved W2 for Token #${tokenId} | Gas: ${receipt.gasUsed}`);
      console.log(`      Tx: https://basescan.org/tx/${tx.hash}\n`);
      
      await delay(1000);
    } catch (err) {
      console.log(`   ❌ W1: ${err.shortMessage || err.message.substring(0, 80)}\n`);
    }
  } else {
    console.log("   ⏩ Skipping (no token minted by W1)\n");
  }

  // ========== 4. TRANSFER via NFTCore ==========
  console.log("\n📦 [4/4] TRANSFER NFT via NFTCore\n");

  // If W1 minted and approved W2, W2 can transfer the token
  if (mintedTokens[1] !== undefined) {
    const tokenId = mintedTokens[1];
    const from = wallets[0];  // W1
    const to = wallets[2];    // W3
    
    // W1 transfers their own token to W3
    try {
      const contract = nftCore.connect(from.wallet);
      
      // Check ownership
      const owner = await contract.ownerOf(tokenId);
      console.log(`   Token #${tokenId} owner: ${owner.slice(0, 10)}...`);
      
      const gasEst = await contract.transferFrom.estimateGas(from.address, to.address, tokenId);
      console.log(`   W1: Transferring Token #${tokenId} to W3, est gas: ${gasEst}`);
      
      const tx = await contract.transferFrom(from.address, to.address, tokenId);
      const receipt = await tx.wait();
      
      totalGasUsed += receipt.gasUsed;
      totalTxCount++;
      txPerContract.NFTCore++;
      
      console.log(`   ✅ W1 → W3: Token #${tokenId} | Gas: ${receipt.gasUsed}`);
      console.log(`      Tx: https://basescan.org/tx/${tx.hash}\n`);
      
    } catch (err) {
      console.log(`   ❌ Transfer failed: ${err.shortMessage || err.message.substring(0, 80)}\n`);
    }
  } else {
    console.log("   ⏩ Skipping (no token to transfer)\n");
  }

  // ========== SUMMARY ==========
  console.log("=".repeat(60));
  console.log("\n📊 TRANSACTION SUMMARY:\n");
  
  const totalGasCost = ethers.formatEther(totalGasUsed * gasPrice);
  console.log(`   Total Transactions: ${totalTxCount}`);
  console.log(`   Total Gas Used: ${totalGasUsed}`);
  console.log(`   Total Gas Cost: ~${totalGasCost} ETH\n`);
  
  console.log("📊 TRANSACTIONS PER CONTRACT:");
  for (const [name, count] of Object.entries(txPerContract)) {
    console.log(`   ${name.padEnd(15)} | ${count.toString().padStart(3)} |`);
  }
  
  // Final balances
  console.log("\n💰 Final Balances:");
  let totalSpent = 0n;
  for (const w of wallets) {
    const bal = await provider.getBalance(w.address);
    const spent = initialBalances[w.id] - bal;
    if (spent > 0n) {
      console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH (spent ${ethers.formatEther(spent)} ETH)`);
      totalSpent += spent;
    } else {
      console.log(`   W${w.id.toString().padStart(2)}: ${ethers.formatEther(bal)} ETH`);
    }
    await delay(100);
  }
  
  console.log(`\n   💸 Total ETH Spent on Gas: ${ethers.formatEther(totalSpent)} ETH`);
  console.log("=".repeat(60) + "\n");
}

main().catch(console.error);
