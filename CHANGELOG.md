# Changelog

All notable changes to the NFTminimint project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024

### Added
- **Modular Architecture**: Complete rewrite with 5 separate deployable contracts
  - NFTCore: Base ERC721 with minting/burning
  - NFTMetadata: Custom attributes and metadata management
  - NFTAccess: Whitelist and access control
  - NFTCollection: Supply limits and royalties
  - NFTminimint: Main controller interface

- **FREE Minting**: Removed all minting fees - completely free to mint!

- **Interface Definitions**: Full interface contracts for integration
  - INFTCore
  - INFTMetadata
  - INFTAccess
  - INFTCollection
  - INFTminimint

- **Library Contracts**:
  - NFTErrors: Custom error definitions for gas efficiency
  - NFTEvents: Common event definitions
  - NFTConstants: System-wide constants
  - StringUtils: String manipulation helpers
  - AddressUtils: Address validation helpers

- **Deployment Scripts**:
  - deploy-all.js: Full deployment automation
  - link-contracts.js: Post-deployment linking
  - verify-contracts.js: Block explorer verification
  - airdrop.js: Batch airdrop utility
  - manage-whitelist.js: Whitelist management
  - configure-royalty.js: Royalty configuration
  - collection-stats.js: Collection statistics viewer

- **Documentation**:
  - DEPLOYMENT.md: Step-by-step deployment guide
  - ARCHITECTURE.md: System architecture overview
  - API.md: Complete API reference
  - SECURITY.md: Security considerations

- **Test Suite**: Comprehensive test coverage for all contracts

### Changed
- Upgraded to OpenZeppelin v5.0.0
- Migrated from single contract to modular architecture
- Improved gas efficiency with custom errors
- Enhanced access control with role-based permissions

### Removed
- 0.01 ETH minting fee (now FREE!)
- Single monolithic contract design
- Legacy deployment scripts

## [1.0.0] - Previous

### Features
- Basic ERC721 NFT minting
- 0.01 ETH mint fee
- Simple whitelist functionality
