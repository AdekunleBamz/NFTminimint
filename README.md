# NFTminimint

A minimal NFT minting platform built with Solidity and Hardhat.

## Features

- Simple ERC-721 NFT contract
- Mint NFTs with custom metadata
- Deploy to Ethereum-compatible networks

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

## Frontend (Preview)

Open the static frontend in your browser:

```bash
open frontend/index.html
```

The UI includes a live minting preview, gallery, and roadmap sections to help you
visualize a polished NFT minting experience.

## Contract Details

- **Standard**: ERC-721
- **Network**: Ethereum, Polygon, etc.
- **Minting Fee**: 0.01 ETH per NFT

## 🤝 Contributing

We welcome contributions to the NFTminimint project! Here's how you can help:

### Ways to Contribute

- **Smart Contracts**: Enhance the NFT contract with new features, improve gas efficiency, or add security mechanisms
- **Frontend Development**: Build a user interface for minting NFTs, create galleries, or add wallet integration
- **Testing**: Add comprehensive test coverage for contracts and deployment scripts
- **Documentation**: Improve docs, add tutorials, create developer guides for NFT development
- **Multi-Chain**: Add support for additional blockchain networks (Polygon, Arbitrum, Optimism)
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
