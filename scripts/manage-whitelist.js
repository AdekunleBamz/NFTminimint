const hre = require("hardhat");

/**
 * Whitelist management script
 */
async function main() {
  console.log("📋 Whitelist Management\n");

  // Configure
  const NFTACCESS_ADDRESS = process.env.NFTACCESS_ADDRESS || "YOUR_ADDRESS";
  
  // Action: "add", "remove", "check", "enable", "disable"
  const action = process.env.ACTION || "check";
  
  // Addresses for add/remove/check
  const addresses = [
    // "0x...",
    // "0x...",
  ];

  if (NFTACCESS_ADDRESS.includes("YOUR_")) {
    console.log("❌ Please set NFTACCESS_ADDRESS!");
    process.exit(1);
  }

  const [deployer] = await hre.ethers.getSigners();
  console.log("Managing with account:", deployer.address);
  console.log("");

  const nftAccess = await hre.ethers.getContractAt("NFTAccess", NFTACCESS_ADDRESS);

  switch (action) {
    case "add":
      console.log(`Adding ${addresses.length} addresses to whitelist...`);
      const txAdd = await nftAccess.batchAddToWhitelist(addresses);
      await txAdd.wait();
      console.log("✅ Added to whitelist. Tx:", txAdd.hash);
      break;

    case "remove":
      console.log(`Removing ${addresses.length} addresses from whitelist...`);
      for (const addr of addresses) {
        const txRemove = await nftAccess.removeFromWhitelist(addr);
        await txRemove.wait();
        console.log(`✅ Removed ${addr}`);
      }
      break;

    case "check":
      console.log("Checking whitelist status...");
      for (const addr of addresses) {
        const isWhitelisted = await nftAccess.isWhitelisted(addr);
        console.log(`${addr}: ${isWhitelisted ? "✅ Whitelisted" : "❌ Not whitelisted"}`);
      }
      break;

    case "enable":
      console.log("Enabling whitelist...");
      const txEnable = await nftAccess.setWhitelistEnabled(true);
      await txEnable.wait();
      console.log("✅ Whitelist enabled. Tx:", txEnable.hash);
      break;

    case "disable":
      console.log("Disabling whitelist...");
      const txDisable = await nftAccess.setWhitelistEnabled(false);
      await txDisable.wait();
      console.log("✅ Whitelist disabled. Tx:", txDisable.hash);
      break;

    default:
      console.log("Invalid action. Use: add, remove, check, enable, disable");
  }

  // Show current status
  console.log("");
  const count = await nftAccess.whitelistCount();
  const enabled = await nftAccess.whitelistEnabled();
  console.log(`Current whitelist count: ${count}`);
  console.log(`Whitelist enabled: ${enabled}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Operation failed:", error);
    process.exit(1);
  });
