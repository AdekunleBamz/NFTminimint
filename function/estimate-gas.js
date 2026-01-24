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
  })
  .map(([key, address]) => ({ key: key.replace("_ADDRESS", ""), address }));

const knownContractKeys = [
  "NFTMINIMINT_ADDRESS",
  "NFTCORE_ADDRESS",
  "NFTMETADATA_ADDRESS",
  "NFTACCESS_ADDRESS",
  "NFTCOLLECTION_ADDRESS",
  "NFTGATED_ADDRESS",
  "NFTALLOWLIST_ADDRESS",
  "NFTPROVENANCE_ADDRESS",
  "NFTRANDOMMINT_ADDRESS"
];

function loadContractAddresses() {
  if (process.env.CONTRACTS_JSON) {
    try {
      const parsed = JSON.parse(process.env.CONTRACTS_JSON);
      return Object.entries(parsed)
        .filter(([, address]) => address)
        .map(([name, address]) => ({ name, address }));
    } catch (error) {
      console.log("Failed to parse CONTRACTS_JSON. Using individual addresses.");
    }
  }

  return knownContractKeys
    .filter((key) => process.env[key])
    .map((key) => ({ name: key.replace("_ADDRESS", ""), address: process.env[key] }));
}

const candidates = [
  { name: "owner", iface: new ethers.Interface(["function owner() view returns (address)"]), args: [] },
  { name: "name", iface: new ethers.Interface(["function name() view returns (string)"]), args: [] },
  { name: "symbol", iface: new ethers.Interface(["function symbol() view returns (string)"]), args: [] },
  { name: "totalSupply", iface: new ethers.Interface(["function totalSupply() view returns (uint256)"]), args: [] },
  { name: "paused", iface: new ethers.Interface(["function paused() view returns (bool)"]), args: [] },
  { name: "maxSupply", iface: new ethers.Interface(["function maxSupply() view returns (uint256)"]), args: [] },
  { name: "mintFee", iface: new ethers.Interface(["function mintFee() view returns (uint256)"]), args: [] }
];

async function pickCallable(address, from) {
  for (const candidate of candidates) {
    try {
      const data = candidate.iface.encodeFunctionData(candidate.name, candidate.args);
      await provider.estimateGas({ to: address, data, from });
      return { ...candidate, data };
    } catch (error) {
      continue;
    }
  }
  return null;
}

async function main() {
  const contracts = loadContractAddresses();

  if (walletEntries.length === 0) {
    console.log("No wallet addresses found in function/.env.");
    return;
  }

  if (contracts.length === 0) {
    console.log("No contract addresses found. Add CONTRACTS_JSON or *_ADDRESS entries in function/.env.");
    return;
  }

  const feeData = await provider.getFeeData();
  const gasPrice = feeData.maxFeePerGas || feeData.gasPrice;
  if (!gasPrice) {
    console.log("Unable to fetch gas price.");
    return;
  }

  const probeWallet = walletEntries[0].address;
  const contractCalls = [];

  for (const contract of contracts) {
    const callable = await pickCallable(contract.address, probeWallet);
    contractCalls.push({
      ...contract,
      callable
    });
  }

  console.log(`RPC: ${rpcUrl}`);
  console.log(`Gas price (max fee): ${ethers.formatUnits(gasPrice, "gwei")} gwei`);
  console.log("");

  for (const wallet of walletEntries) {
    let totalCost = 0n;
    const balance = await provider.getBalance(wallet.address);

    console.log(`${wallet.key}: ${wallet.address}`);
    console.log(`  Balance: ${ethers.formatEther(balance)} ETH`);

    for (const contract of contractCalls) {
      if (!contract.callable) {
        console.log(`  ${contract.name}: no compatible view method found`);
        continue;
      }

      const gas = await provider.estimateGas({
        to: contract.address,
        data: contract.callable.data,
        from: wallet.address
      });

      const cost = gas * gasPrice;
      totalCost += cost;

      console.log(`  ${contract.name}: ${gas.toString()} gas (~${ethers.formatEther(cost)} ETH)`);
    }

    console.log(`  Total estimate: ${ethers.formatEther(totalCost)} ETH`);
    console.log("");
  }

  const wallet1 = walletEntries.find((entry) => entry.key === "WALLET_1");
  if (wallet1) {
    const w1Balance = await provider.getBalance(wallet1.address);
    let w1Total = 0n;

    for (const contract of contractCalls) {
      if (!contract.callable) continue;
      const gas = await provider.estimateGas({
        to: contract.address,
        data: contract.callable.data,
        from: wallet1.address
      });
      w1Total += gas * gasPrice;
    }

    if (w1Balance < w1Total) {
      console.log(
        `WALLET_1 needs more ETH. Estimated total: ${ethers.formatEther(w1Total)} ETH, balance: ${ethers.formatEther(w1Balance)} ETH.`
      );
    } else {
      console.log(
        `WALLET_1 balance is sufficient for one interaction per contract. Estimated total: ${ethers.formatEther(w1Total)} ETH.`
      );
    }
  }
}

main().catch((error) => {
  console.error("Error estimating gas:", error.message || error);
  process.exit(1);
});
