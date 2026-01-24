const { ethers } = require("ethers");
const provider = new ethers.JsonRpcProvider("https://mainnet.base.org");

const address = "0xd32b5108df769d73dc3624d44bf20d0ba0c99fff";
const nftCoreExpected = "0x73A44374Adb7cf99390A97Ab6DF7C272e3E1E612";

const abi = [
  "function nftCore() view returns (address)",
  "function publicMintOpen() view returns (bool)",
  "function whitelistEnabled() view returns (bool)",
  "function paused() view returns (bool)",
  "function owner() view returns (address)"
];

async function check() {
  const contract = new ethers.Contract(address, abi, provider);
  try {
    const core = await contract.nftCore();
    const publicMint = await contract.publicMintOpen();
    const whitelist = await contract.whitelistEnabled();
    const paused = await contract.paused();
    const owner = await contract.owner();
    
    console.log("Checking:", address);
    console.log("nftCore:", core);
    console.log("Expected:", nftCoreExpected);
    console.log("Match:", core.toLowerCase() === nftCoreExpected.toLowerCase() ? "✅ YES - This IS NFTAccess" : "❌ NO");
    console.log("publicMintOpen:", publicMint);
    console.log("whitelistEnabled:", whitelist);
    console.log("paused:", paused);
    console.log("owner:", owner);
  } catch (e) {
    console.log("❌ Not NFTAccess or error:", e.message);
  }
}
check();
