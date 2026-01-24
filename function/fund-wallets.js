/**
 * Fund low-balance wallets from W1
 */

const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

dotenv.config({ path: path.join(__dirname, ".env") });

const provider = new ethers.JsonRpcProvider("https://mainnet.base.org");
const delay = (ms) => new Promise(r => setTimeout(r, ms));

async function main() {
  console.log("\n💰 FUNDING LOW-BALANCE WALLETS\n");
  console.log("=".repeat(50));
  
  const w1 = new ethers.Wallet(process.env.WALLET_1_PRIVATE_KEY, provider);
  const w1Bal = await provider.getBalance(w1.address);
  console.log(`W1 Balance: ${ethers.formatEther(w1Bal)} ETH\n`);
  
  const lowBalanceWallets = [4, 6, 7, 9, 10, 11];
  const fundAmount = ethers.parseUnits("0.00002", "ether");
  const minRequired = ethers.parseUnits("0.000015", "ether");
  
  console.log(`Funding amount: 0.00002 ETH per wallet\n`);
  
  let funded = 0;
  for (const id of lowBalanceWallets) {
    const addr = process.env[`WALLET_${id}_ADDRESS`];
    const bal = await provider.getBalance(addr);
    
    if (bal >= minRequired) {
      console.log(`W${id}: Already has ${ethers.formatEther(bal)} ETH - skipping`);
      continue;
    }
    
    try {
      console.log(`W${id}: Sending 0.00002 ETH...`);
      const tx = await w1.sendTransaction({ to: addr, value: fundAmount });
      await tx.wait();
      const newBal = await provider.getBalance(addr);
      console.log(`✅ W${id}: Funded! New balance: ${ethers.formatEther(newBal)} ETH`);
      funded++;
      await delay(800);
    } catch (e) {
      console.log(`❌ W${id}: ${e.shortMessage || e.message.slice(0, 60)}`);
    }
  }
  
  const w1Final = await provider.getBalance(w1.address);
  console.log(`\n${funded} wallets funded`);
  console.log(`W1 Final Balance: ${ethers.formatEther(w1Final)} ETH`);
  console.log("=".repeat(50) + "\n");
}

main().catch(console.error);
