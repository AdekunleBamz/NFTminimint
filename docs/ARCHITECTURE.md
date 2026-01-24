# Architecture Overview

## NFTminimint Modular Architecture

The NFTminimint system uses a modular architecture with 5 separate deployable contracts.

## Contract Diagram

```
                    ┌─────────────────┐
                    │   NFTminimint   │
                    │  (Controller)   │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
           ▼                 ▼                 ▼
    ┌─────────────┐   ┌──────────────┐   ┌─────────────┐
    │ NFTMetadata │   │   NFTCore    │   │ NFTAccess   │
    │ (Attributes)│   │   (ERC721)   │   │ (Whitelist) │
    └─────────────┘   └──────┬───────┘   └─────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  NFTCollection  │
                    │   (Royalties)   │
                    └─────────────────┘
```

## Contract Responsibilities

### NFTCore
- ERC721 token standard implementation
- Token minting and burning
- URI storage and management
- Token enumeration
- Creator and timestamp tracking

### NFTMetadata
- Custom attribute management
- Metadata freezing (global and per-token)
- Contract URI management
- OpenSea compatibility

### NFTAccess
- Whitelist management
- Public mint controls
- Per-wallet mint limits
- Pause functionality
- Admin role management

### NFTCollection
- Maximum supply enforcement
- EIP-2981 royalty standard
- Per-token royalty overrides

### NFTminimint
- User-facing minting interface
- Batch minting operations
- Airdrop functionality
- FREE minting (no fees!)

## Design Principles

1. **Separation of Concerns**: Each contract handles one responsibility
2. **Upgradability**: Contracts can be upgraded individually
3. **Gas Efficiency**: Only interact with needed contracts
4. **Security**: Role-based access control throughout
5. **Flexibility**: Easy to extend or replace components
