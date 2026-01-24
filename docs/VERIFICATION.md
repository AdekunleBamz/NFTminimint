# Verification Guide

## Verifying Contracts on BaseScan

After deployment, verify your contracts on BaseScan for transparency.

### Prerequisites

1. Get a BaseScan API key from https://basescan.org/apis
2. Add to `.env`:
   ```
   BASESCAN_API_KEY=your_api_key_here
   ```

### Verification Commands

```bash
# NFTCore
npx hardhat verify --network base 0x73A44374Adb7cf99390A97Ab6DF7C272e3E1E612

# NFTMetadata
npx hardhat verify --network base 0x3ed5e52f08C1A4f805923E686dA0a28Ae5a2fe74

# NFTAccess
npx hardhat verify --network base 0xd32b5108df769d73dc3624d44bf20d0ba0c99fff

# NFTCollection
npx hardhat verify --network base 0xD2a7Eec2A4397BAB9398FEcBa860776C7614da0c

# NFTminimint
npx hardhat verify --network base 0xd6e3d8c95B4E23B1d58449B32d16a03643E4B2c0
```

### View Verified Contracts

- [NFTminimint on BaseScan](https://basescan.org/address/0xd6e3d8c95B4E23B1d58449B32d16a03643E4B2c0)
