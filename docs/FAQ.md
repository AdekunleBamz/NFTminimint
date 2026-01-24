# Frequently Asked Questions

## General

### What is NFTminimint?
NFTminimint is a modular NFT minting platform built with Solidity. It uses a 5-contract architecture for maximum flexibility and upgradability.

### Is minting really free?
Yes! Unlike the previous version which charged 0.01 ETH, NFTminimint v2.0 has completely removed all minting fees. You only pay gas fees.

### What networks are supported?
NFTminimint works on any EVM-compatible network:
- Ethereum Mainnet
- Polygon
- Arbitrum
- Optimism
- Base
- BNB Chain
- Testnets (Sepolia, Goerli, Mumbai, etc.)

## Deployment

### Why are there 5 contracts?
The modular architecture allows:
- Independent upgrades to each component
- Gas savings (interact with only needed contracts)
- Better separation of concerns
- Easier testing and maintenance

### What order do I deploy in?
1. NFTCore (no dependencies)
2. NFTMetadata (needs NFTCore address)
3. NFTAccess (needs NFTCore address)
4. NFTCollection (needs NFTCore address)
5. NFTminimint (needs all 4 addresses)

### Do I need to link contracts after deployment?
Yes! After deployment, you must:
1. Call `authorizeMinter()` on NFTCore
2. Call `authorizeCaller()` on NFTAccess
3. Call `setPublicMintOpen(true)` on NFTAccess

## Features

### How does the whitelist work?
1. Add addresses with `addToWhitelist()` or `batchAddToWhitelist()`
2. Enable whitelist with `setWhitelistEnabled(true)`
3. Only whitelisted addresses can mint when enabled

### Can I limit how many NFTs each wallet can mint?
Yes! Use `setWalletMintLimit(limit)` on NFTAccess. Set to 0 for unlimited.

### How do royalties work?
NFTminimint supports EIP-2981 royalties:
- Set default royalty: `setDefaultRoyalty(receiver, bps)`
- Set per-token royalty: `setTokenRoyalty(tokenId, receiver, bps)`
- Basis points: 500 = 5%, 1000 = 10%

### Can I freeze metadata?
Yes! You can:
- Freeze all metadata: `freezeMetadata()` (irreversible!)
- Freeze single token: `freezeTokenMetadata(tokenId)` (irreversible!)

## Troubleshooting

### "Not authorized minter" error
Make sure you called `authorizeMinter(NFTminimint_address)` on NFTCore.

### "Public mint not open" error
Call `setPublicMintOpen(true)` on NFTAccess.

### "Not whitelisted" error
Either:
- Add the address to whitelist with `addToWhitelist()`
- Or disable whitelist with `setWhitelistEnabled(false)`

### "Wallet limit reached" error
The wallet has reached its mint limit. Either:
- Increase limit with `setWalletMintLimit(newLimit)`
- Or set to 0 for unlimited

### Contract verification fails
Ensure you're using the exact same:
- Compiler version
- Optimizer settings
- Constructor arguments
