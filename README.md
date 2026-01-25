# NFTminimint

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://soliditylang.org/)
[![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-yellow.svg)](https://hardhat.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-v5.0-blue.svg)](https://openzeppelin.com/)

A modular, fee-free NFT minting platform built with Solidity and Hardhat.

## 🚀 Features

- **Modular Architecture**: 5 separate deployable contracts
- **FREE Minting**: No minting fees - completely free!
- **ERC-721 Standard**: Full OpenZeppelin v5 compliance
- **EIP-2981 Royalties**: Built-in royalty support
- **Whitelist System**: Flexible access control
- **Batch Operations**: Batch mint and airdrop support
- **Metadata Management**: Custom attributes and freezing

## 📦 Contract Architecture

| Contract | Purpose |
|----------|---------|
| NFTCoreV2 | Base ERC721 with minting/burning |
| NFTMetadataV2 | Custom attributes and metadata |
| NFTAccessV2 | Whitelist and access control |
| NFTCollectionV2 | Supply limits and royalties |
| NFTminimintV2 | Main controller interface |

## 🌐 Deployed Contracts (Base Mainnet)

### V2 Contracts (Latest)

| Contract | Address |
|----------|---------|
| NFTCoreV2 | [`0xDADADe844995d4A34FbA65A98E371a0eDA57BeC2`](https://basescan.org/address/0xDADADe844995d4A34FbA65A98E371a0eDA57BeC2) |
| NFTMetadataV2 | [`0x107fCd5f1D4172E254564cf4D1Fd3ADa1B8Ea657`](https://basescan.org/address/0x107fCd5f1D4172E254564cf4D1Fd3ADa1B8Ea657) |
| NFTAccessV2 | [`0x37d4E045861a48bf2f06944b93f0ce2691d220f6`](https://basescan.org/address/0x37d4E045861a48bf2f06944b93f0ce2691d220f6) |
| NFTCollectionV2 | [`0x0972C25D2ee399AB1D71EdD7C64caD92Ed2DD29e`](https://basescan.org/address/0x0972C25D2ee399AB1D71EdD7C64caD92Ed2DD29e) |
| NFTminimintV2 | [`0x790D7DCe41EFEB8d3fa99345556A38d23ada196E`](https://basescan.org/address/0x790D7DCe41EFEB8d3fa99345556A38d23ada196E) |

### V1 Contracts (Legacy)

| Contract | Address |
|----------|---------|
| NFTCore | [`0x73A44374Adb7cf99390A97Ab6DF7C272e3E1E612`](https://basescan.org/address/0x73A44374Adb7cf99390A97Ab6DF7C272e3E1E612) |
| NFTMetadata | [`0x3ed5e52f08C1A4f805923E686dA0a28Ae5a2fe74`](https://basescan.org/address/0x3ed5e52f08C1A4f805923E686dA0a28Ae5a2fe74) |
| NFTAccess | [`0xd32b5108df769d73dc3624d44bf20d0ba0c99fff`](https://basescan.org/address/0xd32b5108df769d73dc3624d44bf20d0ba0c99fff) |
| NFTCollection | [`0xD2a7Eec2A4397BAB9398FEcBa860776C7614da0c`](https://basescan.org/address/0xD2a7Eec2A4397BAB9398FEcBa860776C7614da0c) |
| NFTminimint | [`0xd6e3d8c95B4E23B1d58449B32d16a03643E4B2c0`](https://basescan.org/address/0xd6e3d8c95B4E23B1d58449B32d16a03643E4B2c0) |

## Installation

> Note: Hardhat requires a supported Node.js LTS. This repo includes a `.nvmrc`.

```bash
# if you use nvm
nvm install
nvm use
```

```bash
npm install
```

## Quick Start

1. Compile contracts:
```bash
npx hardhat compile
```

2. Run tests:
```bash
npx hardhat test
```

3. Deploy contracts:
```bash
npx hardhat run scripts/deploy.js --network <network>
```

## Frontend (Preview)

Open the static frontend in your browser:

```bash
open frontend/index.html
```

The UI includes a live minting preview, gallery, and roadmap sections to help you
visualize a polished NFT minting experience.

## Contract Details

- **Standard**: ERC-721 + EIP-2981
- **Solidity**: ^0.8.20
- **OpenZeppelin**: v5.0.0
- **Minting Fee**: FREE! 🎉

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Security Guide](docs/SECURITY.md)

## 🤝 Contributing

We welcome contributions to the NFTminimint project! Here's how you can help:

### Ways to Contribute

- **Smart Contracts**: Enhance contracts with new features, improve gas efficiency
- **Testing**: Add comprehensive test coverage
- **Documentation**: Improve docs, add tutorials
- **Multi-Chain**: Add support for additional networks
- **NFT Features**: Implement royalties, metadata standards, or marketplace functionality
- **Security**: Audit contracts, implement access controls, or add emergency mechanisms

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-nft-feature`)
3. **Make your changes** following the guidelines below
4. **Write tests** for new functionality
5. **Update documentation** for any API or contract changes
6. **Commit your changes** (`git commit -m 'Add amazing NFT feature'`)
7. **Push to the branch** (`git push origin feature/amazing-nft-feature`)
8. **Open a Pull Request** with a clear description

### Development Guidelines

#### Smart Contracts (Solidity)
- Use OpenZeppelin contracts for security
- Add comprehensive NatSpec documentation
- Write Hardhat tests for all functions
- Optimize for gas efficiency
- Include proper error handling with custom errors
- Follow ERC-721 standards and best practices

#### Testing
- All contract functions must have unit tests
- Test edge cases and failure scenarios
- Include gas usage benchmarks
- Test on multiple networks when possible
- Use Hardhat's testing framework with Chai assertions

#### Deployment
- Test deployments on testnets first
- Verify contracts on block explorers
- Document deployment addresses and parameters
- Include migration scripts for upgrades
- Test contract interactions thoroughly

### Code Standards

- **Solidity**: Follow official Solidity style guide
- **JavaScript**: Use ESLint with configured rules
- **Documentation**: Include NatSpec comments for all public functions
- **Security**: Never store sensitive data on-chain
- **Gas Optimization**: Consider gas costs in all implementations

### Testing Requirements

- **Unit Tests**: All functions must have unit tests
- **Integration Tests**: Test contract deployments and interactions
- **Gas Tests**: Monitor gas usage and optimize expensive operations
- **Security Tests**: Test for common vulnerabilities (reentrancy, overflow, etc.)
- **Coverage**: Maintain >90% test coverage for critical functions

### Security Considerations

- **Reentrancy**: All functions must be protected against reentrancy attacks
- **Access Control**: Implement proper ownership and access controls
- **Input Validation**: Validate all inputs to prevent exploits
- **Overflow/Underflow**: Use SafeMath or Solidity 0.8+ built-in checks
- **Emergency**: Include circuit breaker mechanisms for emergencies

### Code of Conduct

- **Be Respectful**: Treat all contributors with respect and kindness
- **Inclusive**: Welcome contributors from all backgrounds and experience levels
- **Constructive**: Focus on constructive feedback and solutions
- **Helpful**: Assist newcomers in getting started with NFT development
- **Ethical**: Report security issues privately and responsibly

### Reporting Issues

- **Bug Reports**: Use the issue template with reproduction steps
- **Security Issues**: Report privately to security@nftminimint.network
- **Feature Requests**: Use the feature request template with detailed rationale
- **Performance Issues**: Include gas usage data and optimization suggestions

---

## 📄 License

MIT

---

Built with ❤️ for the NFT community on Ethereum-compatible blockchains.
