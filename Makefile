# NFTminimint Development Makefile
# This Makefile provides convenient commands for smart contract development, testing, and deployment

.PHONY: help install build compile test clean deploy deploy-local deploy-testnet deploy-mainnet verify verify-local verify-testnet verify-mainnet node node-fork flatten size coverage gas-report format lint setup setup-contract env-setup info quick-start

# Default target
help: ## Show this help message
	@echo "NFTminimint Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation commands
install: ## Install dependencies
	npm install

# Build commands
build: compile ## Build all contracts

compile: ## Compile smart contracts
	npx hardhat compile

# Test commands
test: ## Run all tests
	npx hardhat test

test-verbose: ## Run tests with verbose output
	npx hardhat test --verbose

test-gas: ## Run tests with gas reporting
	npx hardhat test --gas

# Clean commands
clean: ## Clean build artifacts
	npx hardhat clean

# Deployment commands
deploy: deploy-local ## Deploy to local network (default)

deploy-local: ## Deploy contracts to local Hardhat network
	npx hardhat run scripts/deploy.js --network localhost

deploy-testnet: ## Deploy contracts to testnet (configure network in hardhat.config.js)
	npx hardhat run scripts/deploy.js --network goerli

deploy-mainnet: ## Deploy contracts to mainnet (configure network in hardhat.config.js)
	npx hardhat run scripts/deploy.js --network mainnet

# Verification commands
verify: verify-local ## Verify contracts on local network

verify-local: ## Verify contracts on local network
	@echo "Verification not applicable for local network"

verify-testnet: ## Verify contracts on Etherscan (testnet)
	npx hardhat verify --network goerli <CONTRACT_ADDRESS>

verify-mainnet: ## Verify contracts on Etherscan (mainnet)
	npx hardhat verify --network mainnet <CONTRACT_ADDRESS>

# Development network
node: ## Start local Hardhat development network
	npx hardhat node

node-fork: ## Start local Hardhat network forked from mainnet
	npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY

# Analysis commands
flatten: ## Flatten contracts for deployment
	npx hardhat flatten contracts/NFTminimint.sol > flattened/NFTminimint.sol

size: ## Show contract sizes
	npx hardhat size-contracts

coverage: ## Run test coverage
	npx hardhat coverage

gas-report: ## Generate gas usage report
	npx hardhat test --gas-reporter

# Code quality commands
format: ## Format Solidity code
	npx prettier --write "contracts/**/*.sol" "test/**/*.js" "scripts/**/*.js"

lint: ## Lint Solidity code
	npx solhint "contracts/**/*.sol"

lint-fix: ## Fix linting issues
	npx solhint --fix "contracts/**/*.sol"

# Setup commands
setup: setup-contract ## Setup development environment

setup-contract: ## Setup contract development environment
	npm install
	@echo "Contract setup complete. Run 'make compile' to compile contracts."

# Environment setup
env-setup: ## Setup environment variables template
	@echo "Creating .env file..."
	@cp .env.example .env 2>/dev/null || echo "# NFTminimint Environment Variables" > .env
	@echo "PRIVATE_KEY=your-private-key-here" >> .env
	@echo "INFURA_API_KEY=your-infura-api-key" >> .env
	@echo "ETHERSCAN_API_KEY=your-etherscan-api-key" >> .env
	@echo "ALCHEMY_API_KEY=your-alchemy-api-key" >> .env

# Docker commands
docker-build: ## Build Docker container
	docker build -t nftminimint .

docker-run: ## Run Docker container
	docker run -it --rm nftminimint

docker-compose-up: ## Start services with Docker Compose
	docker-compose up -d

docker-compose-down: ## Stop Docker Compose services
	docker-compose down

# Utility commands
update-deps: ## Update all dependencies
	npm update

check-security: ## Run security checks
	npx hardhat run scripts/security-check.js

docs: ## Generate contract documentation
	npx hardhat docgen

# Project information
info: ## Show project information
	@echo "NFTminimint - Minimal NFT Minting Platform"
	@echo "Solidity: $$(grep 'solidity:' hardhat.config.js | sed 's/.*solidity: "\([^"]*\)".*/\1/')"
	@echo "Framework: Hardhat"
	@echo "Libraries: OpenZeppelin Contracts"

# Quick start
quick-start: setup env-setup compile test ## Quick start development environment
	@echo "NFTminimint development environment is ready!"
	@echo "Run 'make node' to start local network"
	@echo "Run 'make deploy-local' to deploy contracts locally"