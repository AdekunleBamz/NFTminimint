const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

// Load .env from function directory
const envPath = path.join(__dirname, ".env");
console.log("Loading env from:", envPath);

const result = dotenv.config({ path: envPath });
if (result.error) {
  console.log("dotenv error:", result.error.message);
  process.exit(1);
}

console.log("Parsed keys:", Object.keys(result.parsed || {}));

// Check for wallet addresses
const addresses = [];
for (let i = 1; i <= 11; i++) {
  const addr = process.env[`WALLET_${i}_ADDRESS`];
  if (addr) {
    addresses.push({ wallet: i, address: addr });
  }
}

if (addresses.length === 0) {
  console.log("No wallet addresses found!");
  process.exit(1);
}

console.log(`\nFound ${addresses.length} wallets\n`);

// Connect to Base mainnet
const rpcUrl = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(rpcUrl);

async function main() {
  const network = await provider.getNetwork();
  console.log(`Connected to chain: ${network.chainId}\n`);
  
  console.log("Wallet Balances:");
  console.log("-".repeat(80));
  
  let total = 0n;
  for (const { wallet, address } of addresses) {
    const balance = await provider.getBalance(address);
    const eth = ethers.formatEther(balance);
    total += balance;
    console.log(`WALLET_${wallet.toString().padStart(2, " ")} | ${address} | ${eth} ETH`);
  }
  
  console.log("-".repeat(80));
  console.log(`TOTAL: ${ethers.formatEther(total)} ETH`);
  
  // WALLET_1 analysis
  const w1Balance = await provider.getBalance(addresses[0].address);
  console.log(`\nWALLET_1 (Funding Wallet): ${ethers.formatEther(w1Balance)} ETH`);
  
  if (w1Balance === 0n) {
    console.log("⚠️  WALLET_1 is EMPTY - needs funding!");
  } else if (w1Balance < ethers.parseEther("0.01")) {
    console.log("⚠️  WALLET_1 has LOW balance");
  } else {
    console.log("✅ WALLET_1 has funds");
  }
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
