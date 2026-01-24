const path = require("path");
const dotenv = require("dotenv");
const { ethers } = require("ethers");

dotenv.config({ path: path.join(__dirname, ".env") });

const rpcUrl = process.env.BASE_RPC_URL || "https://mainnet.base.org";
const provider = new ethers.JsonRpcProvider(rpcUrl);

const walletEntries = Object.entries(process.env)
  .filter(([key, value]) => /^WALLET_\d+_ADDRESS$/.test(key) && value)
  .sort((a, b) => {
    const aNum = Number(a[0].match(/^WALLET_(\d+)_ADDRESS$/)[1]);
    const bNum = Number(b[0].match(/^WALLET_(\d+)_ADDRESS$/)[1]);
    return aNum - bNum;
  });

async function main() {
  if (walletEntries.length === 0) {
    console.log("No wallet addresses found in function/.env.");
    return;
  }

  console.log(`RPC: ${rpcUrl}`);
  console.log("Wallet balances (ETH):");

  for (const [key, address] of walletEntries) {
    const balance = await provider.getBalance(address);
    console.log(`${key.replace("_ADDRESS", "")}: ${address} -> ${ethers.formatEther(balance)}`);
  }
}

main().catch((error) => {
  console.error("Error checking balances:", error.message || error);
  process.exit(1);
});
