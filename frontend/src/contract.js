// NFTminimint Smart Contract Configuration
// This file contains the ABI and addresses for interacting with the contract

export const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3'

// Network-specific addresses
export const NETWORK_ADDRESSES = {
  // Localhost (Hardhat)
  31337: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
  // Sepolia Testnet
  11155111: import.meta.env.VITE_SEPOLIA_CONTRACT_ADDRESS || '',
  // Goerli Testnet (deprecated but included)
  5: import.meta.env.VITE_GOERLI_CONTRACT_ADDRESS || '',
  // Ethereum Mainnet
  1: import.meta.env.VITE_MAINNET_CONTRACT_ADDRESS || '',
  // Polygon Mainnet
  137: import.meta.env.VITE_POLYGON_CONTRACT_ADDRESS || '',
  // Polygon Mumbai
  80001: import.meta.env.VITE_MUMBAI_CONTRACT_ADDRESS || ''
}

// Get contract address for current network
export function getContractAddress(chainId) {
  return NETWORK_ADDRESSES[chainId] || CONTRACT_ADDRESS
}

// Complete ABI for NFTminimint contract
export const NFT_ABI = [
  // ERC721 Standard Functions
  {
    "inputs": [{"name": "owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "tokenId", "type": "uint256"}],
    "name": "ownerOf",
    "outputs": [{"name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "name",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "symbol",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "tokenId", "type": "uint256"}],
    "name": "tokenURI",
    "outputs": [{"name": "", "type": "string"}],
    "stateMutability": "view",
    "type": "function"
  },
  
  // NFTminimint Custom Functions
  {
    "inputs": [],
    "name": "totalSupply",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "mintFee",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "maxSupply",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "maxPerWallet",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "wallet", "type": "address"}],
    "name": "mintedByWallet",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "paused",
    "outputs": [{"name": "", "type": "bool"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [{"name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  
  // Mint function
  {
    "inputs": [
      {"name": "to", "type": "address"},
      {"name": "tokenURI", "type": "string"}
    ],
    "name": "mintNFT",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  
  // Events
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "name": "from", "type": "address"},
      {"indexed": true, "name": "to", "type": "address"},
      {"indexed": true, "name": "tokenId", "type": "uint256"}
    ],
    "name": "Transfer",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {"indexed": true, "name": "to", "type": "address"},
      {"indexed": true, "name": "tokenId", "type": "uint256"},
      {"indexed": false, "name": "tokenURI", "type": "string"}
    ],
    "name": "NFTMinted",
    "type": "event"
  }
]

// Simplified human-readable ABI for ethers.js
export const NFT_ABI_HUMAN = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function tokenURI(uint256 tokenId) view returns (string)',
  'function balanceOf(address owner) view returns (uint256)',
  'function ownerOf(uint256 tokenId) view returns (address)',
  'function totalSupply() view returns (uint256)',
  'function mintFee() view returns (uint256)',
  'function maxSupply() view returns (uint256)',
  'function maxPerWallet() view returns (uint256)',
  'function mintedByWallet(address) view returns (uint256)',
  'function paused() view returns (bool)',
  'function owner() view returns (address)',
  'function mintNFT(address to, string tokenURI) payable',
  'event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)',
  'event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI)'
]

// Chain configuration
export const CHAIN_CONFIG = {
  1: {
    name: 'Ethereum Mainnet',
    currency: 'ETH',
    explorer: 'https://etherscan.io',
    rpc: 'https://mainnet.infura.io/v3/'
  },
  5: {
    name: 'Goerli Testnet',
    currency: 'ETH',
    explorer: 'https://goerli.etherscan.io',
    rpc: 'https://goerli.infura.io/v3/'
  },
  11155111: {
    name: 'Sepolia Testnet',
    currency: 'ETH',
    explorer: 'https://sepolia.etherscan.io',
    rpc: 'https://sepolia.infura.io/v3/'
  },
  31337: {
    name: 'Localhost',
    currency: 'ETH',
    explorer: '',
    rpc: 'http://127.0.0.1:8545'
  },
  137: {
    name: 'Polygon Mainnet',
    currency: 'MATIC',
    explorer: 'https://polygonscan.com',
    rpc: 'https://polygon-rpc.com'
  },
  80001: {
    name: 'Polygon Mumbai',
    currency: 'MATIC',
    explorer: 'https://mumbai.polygonscan.com',
    rpc: 'https://rpc-mumbai.maticvigil.com'
  }
}

export function getExplorerUrl(chainId, type, hash) {
  const config = CHAIN_CONFIG[chainId]
  if (!config || !config.explorer) return null
  
  switch (type) {
    case 'tx':
      return `${config.explorer}/tx/${hash}`
    case 'address':
      return `${config.explorer}/address/${hash}`
    case 'token':
      return `${config.explorer}/token/${hash}`
    default:
      return config.explorer
  }
}
