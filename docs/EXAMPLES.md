# Examples

## Basic Minting

```javascript
const { ethers } = require("hardhat");

async function mintNFT() {
  // Get contract instance
  const nftMinimint = await ethers.getContractAt(
    "NFTminimint",
    "YOUR_NFTMINIMINT_ADDRESS"
  );

  // Mint a single NFT (FREE!)
  const tx = await nftMinimint.mint("ipfs://your-metadata-uri");
  const receipt = await tx.wait();
  
  console.log("NFT minted! Transaction:", tx.hash);
}
```

## Batch Minting

```javascript
async function batchMintNFTs() {
  const nftMinimint = await ethers.getContractAt(
    "NFTminimint",
    "YOUR_NFTMINIMINT_ADDRESS"
  );

  const uris = [
    "ipfs://metadata1",
    "ipfs://metadata2",
    "ipfs://metadata3",
    "ipfs://metadata4",
    "ipfs://metadata5"
  ];

  // Batch mint 5 NFTs (all FREE!)
  const tx = await nftMinimint.batchMint(uris);
  await tx.wait();
  
  console.log("5 NFTs minted!");
}
```

## Airdrop to Multiple Recipients

```javascript
async function airdropNFTs() {
  const nftMinimint = await ethers.getContractAt(
    "NFTminimint",
    "YOUR_NFTMINIMINT_ADDRESS"
  );

  const recipients = [
    "0xRecipient1...",
    "0xRecipient2...",
    "0xRecipient3..."
  ];
  
  const uris = [
    "ipfs://gift1",
    "ipfs://gift2",
    "ipfs://gift3"
  ];

  const tx = await nftMinimint.airdrop(recipients, uris);
  await tx.wait();
  
  console.log("Airdrop complete!");
}
```

## Setting Token Attributes

```javascript
async function setAttributes() {
  const nftMetadata = await ethers.getContractAt(
    "NFTMetadata",
    "YOUR_NFTMETADATA_ADDRESS"
  );

  const tokenId = 1;
  
  // Set multiple attributes
  await nftMetadata.setAttribute(tokenId, "rarity", "legendary");
  await nftMetadata.setAttribute(tokenId, "power", "9000");
  await nftMetadata.setAttribute(tokenId, "element", "fire");
  
  // Read attributes
  const rarity = await nftMetadata.getAttribute(tokenId, "rarity");
  console.log("Rarity:", rarity); // "legendary"
  
  // Get all attribute keys
  const keys = await nftMetadata.getAttributeKeys(tokenId);
  console.log("Attributes:", keys); // ["rarity", "power", "element"]
}
```

## Configuring Whitelist

```javascript
async function configureWhitelist() {
  const nftAccess = await ethers.getContractAt(
    "NFTAccess",
    "YOUR_NFTACCESS_ADDRESS"
  );

  // Add addresses to whitelist
  const addresses = [
    "0xAddress1...",
    "0xAddress2...",
    "0xAddress3..."
  ];
  
  await nftAccess.batchAddToWhitelist(addresses);
  
  // Enable whitelist requirement
  await nftAccess.setWhitelistEnabled(true);
  
  // Close public mint (only whitelisted can mint)
  await nftAccess.setPublicMintOpen(false);
  
  console.log("Whitelist configured!");
}
```

## Setting Royalties

```javascript
async function configureRoyalties() {
  const nftCollection = await ethers.getContractAt(
    "NFTCollection",
    "YOUR_NFTCOLLECTION_ADDRESS"
  );

  // Set 5% royalty on all sales
  const royaltyReceiver = "0xYourWallet...";
  const royaltyBps = 500; // 5% in basis points
  
  await nftCollection.setDefaultRoyalty(royaltyReceiver, royaltyBps);
  
  // Set custom royalty for specific token (10%)
  await nftCollection.setTokenRoyalty(1, royaltyReceiver, 1000);
  
  // Check royalty info for a 1 ETH sale
  const salePrice = ethers.parseEther("1");
  const [receiver, amount] = await nftCollection.royaltyInfo(1, salePrice);
  
  console.log(`Royalty: ${ethers.formatEther(amount)} ETH`);
}
```

## Checking Mint Eligibility

```javascript
async function checkCanMint(userAddress) {
  const nftAccess = await ethers.getContractAt(
    "NFTAccess",
    "YOUR_NFTACCESS_ADDRESS"
  );

  const [canMint, reason] = await nftAccess.canMint(userAddress);
  
  if (canMint) {
    console.log("User can mint!");
  } else {
    console.log("Cannot mint:", reason);
  }
  
  // Get detailed stats
  const stats = await nftAccess.getMintStats(userAddress);
  console.log("Minted:", stats.minted.toString());
  console.log("Remaining:", stats.remaining.toString());
  console.log("Limit:", stats.limit.toString());
}
```
