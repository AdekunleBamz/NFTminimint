# Deployment Guide

## NFTminimint Multi-Contract Deployment

This guide explains how to deploy the NFTminimint modular contract system.

## Deployment Order

The contracts MUST be deployed in this specific order:

1. **NFTCore** (No dependencies)
2. **NFTMetadata** (Requires NFTCore address)
3. **NFTAccess** (Requires NFTCore address)
4. **NFTCollection** (Requires NFTCore address)
5. **NFTminimint** (Requires all 4 contract addresses)

## Constructor Arguments

### 1. NFTCore
```
- name_ (string): Collection name (e.g., "My NFT Collection")
- symbol_ (string): Collection symbol (e.g., "MNFT")
```

### 2. NFTMetadata
```
- nftCore_ (address): Address of deployed NFTCore contract
```

### 3. NFTAccess
```
- nftCore_ (address): Address of deployed NFTCore contract
```

### 4. NFTCollection
```
- nftCore_ (address): Address of deployed NFTCore contract
- maxSupply_ (uint256): Maximum supply (e.g., 10000)
```

### 5. NFTminimint
```
- nftCore_ (address): Address of deployed NFTCore
- nftMetadata_ (address): Address of deployed NFTMetadata
- nftAccess_ (address): Address of deployed NFTAccess
- nftCollection_ (address): Address of deployed NFTCollection
```

## Post-Deployment Linking

After all contracts are deployed, you must link them:

### Step 1: Authorize NFTminimint as Minter
Call on **NFTCore**:
```solidity
authorizeMinter(NFTminimint_address)
```

### Step 2: Authorize NFTminimint as Caller
Call on **NFTAccess**:
```solidity
authorizeCaller(NFTminimint_address)
```

### Step 3: Open Public Minting
Call on **NFTAccess**:
```solidity
setPublicMintOpen(true)
```

## Verification

After linking, verify by minting a test token through NFTminimint:
```solidity
mint("ipfs://test-uri")
```

## Gas Estimates

| Contract | Deployment Gas |
|----------|----------------|
| NFTCore | ~2,500,000 |
| NFTMetadata | ~1,200,000 |
| NFTAccess | ~1,800,000 |
| NFTCollection | ~1,500,000 |
| NFTminimint | ~800,000 |

Total: ~7,800,000 gas
