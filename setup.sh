#!/bin/bash

# NFTminimint Setup Script
# This script sets up the development environment for NFTminimint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    print_status "Starting NFTminimint development environment setup..."

    # Check prerequisites
    print_status "Checking prerequisites..."

    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 16+ first."
        exit 1
    fi

    if ! command_exists npm; then
        print_error "npm is not installed. Please install npm first."
        exit 1
    fi

    if ! command_exists npx; then
        print_warning "npx is not available. Some commands may not work."
    fi

    print_success "Prerequisites check complete."

    # Setup contracts
    print_status "Setting up smart contracts..."
    npm install
    print_success "Dependencies installed."

    # Compile contracts
    print_status "Compiling contracts..."
    if command_exists npx; then
        npx hardhat compile
        print_success "Contracts compiled."
    else
        print_warning "npx not available. Please run 'npx hardhat compile' manually."
    fi

    # Create environment files
    print_status "Setting up environment files..."

    if [ ! -f ".env" ]; then
        cat > .env << EOF
# NFTminimint Environment Variables
PRIVATE_KEY=your-private-key-here
INFURA_API_KEY=your-infura-api-key
ETHERSCAN_API_KEY=your-etherscan-api-key
ALCHEMY_API_KEY=your-alchemy-api-key

# Network URLs (add as needed)
GOERLI_RPC_URL=https://goerli.infura.io/v3/YOUR_INFURA_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
EOF
        print_success ".env file created."
    else
        print_status ".env file already exists."
    fi

    # Setup Docker environment (optional)
    if command_exists docker && command_exists docker-compose; then
        print_status "Docker environment ready for use."
    else
        print_warning "Docker not available. Docker commands will not work."
    fi

    print_success "NFTminimint setup complete!"
    echo ""
    print_status "Next steps:"
    echo "  1. Update the PRIVATE_KEY and API keys in .env file"
    echo "  2. Run 'make test' to run contract tests"
    echo "  3. Run 'make node' to start local development network"
    echo "  4. Run 'make deploy-local' to deploy contracts locally"
    echo ""
    print_status "Available commands:"
    echo "  make help          - Show all available commands"
    echo "  make compile       - Compile smart contracts"
    echo "  make test          - Run all tests"
    echo "  make node          - Start local Hardhat network"
    echo "  make deploy-local  - Deploy to local network"
    echo "  make coverage      - Run test coverage"
    echo "  make gas-report    - Generate gas usage report"
}

# Run main function
main "$@"