# NFTminimint

A minimal NFT minting platform built with Solidity and Hardhat.

## Features

- Simple ERC-721 NFT contract
- Mint NFTs with custom metadata
- Deploy to Ethereum-compatible networks

## Installation

```bash
npm install
```

## Usage

1. Compile the contract:
```bash
npx hardhat compile
```

2. Deploy to a network:
```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

3. Mint an NFT:
```javascript
// Use the deployed contract address and ABI to mint
```

## Contract Details

- **Standard**: ERC-721
- **Network**: Ethereum, Polygon, etc.
- **Minting Fee**: 0.01 ETH per NFT

## License

MIT
