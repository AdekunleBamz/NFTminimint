/**
 * @title TypeScript Types
 * @description TypeScript type definitions for NFTminimint contracts
 */

import { ethers } from "ethers";

// Contract Addresses Type
export interface ContractAddresses {
    nftCore: string;
    nftMetadata: string;
    nftAccess: string;
    nftCollection: string;
    nftMinimint: string;
}

// Deployment Config
export interface DeploymentConfig {
    network: string;
    addresses: ContractAddresses;
    deployedAt: number;
    deployer: string;
    txHashes: {
        nftCore: string;
        nftMetadata: string;
        nftAccess: string;
        nftCollection: string;
        nftMinimint: string;
    };
}

// Mint Parameters
export interface MintParams {
    to: string;
    tokenURI: string;
}

// Batch Mint Parameters
export interface BatchMintParams {
    to: string;
    tokenURIs: string[];
}

// Airdrop Recipient
export interface AirdropRecipient {
    recipient: string;
    tokenURI: string;
}

// Token Metadata
export interface TokenMetadata {
    tokenId: number;
    uri: string;
    owner: string;
    creator: string;
    attributes: Record<string, string>;
    frozen: boolean;
}

// Collection Stats
export interface CollectionStats {
    totalSupply: number;
    maxSupply: number;
    remainingSupply: number;
    uniqueOwners: number;
}

// Royalty Info
export interface RoyaltyInfo {
    receiver: string;
    bps: number; // Basis points
}

// Access Control
export interface AccessInfo {
    publicMintOpen: boolean;
    whitelistEnabled: boolean;
    paused: boolean;
    walletMintLimit: number;
}

// Whitelist Entry
export interface WhitelistEntry {
    address: string;
    isWhitelisted: boolean;
    mintedCount: number;
}

// Transaction Result
export interface TxResult {
    success: boolean;
    txHash: string;
    blockNumber: number;
    gasUsed: bigint;
    events: EventLog[];
}

// Event Log
export interface EventLog {
    name: string;
    args: Record<string, unknown>;
}

// Contract Events
export interface NFTMintedEvent {
    tokenId: bigint;
    to: string;
    creator: string;
    tokenURI: string;
}

export interface BatchMintedEvent {
    to: string;
    startTokenId: bigint;
    quantity: bigint;
}

export interface TransferEvent {
    from: string;
    to: string;
    tokenId: bigint;
}

export interface ApprovalEvent {
    owner: string;
    approved: string;
    tokenId: bigint;
}

// Contract Interfaces (for ethers.js)
export interface INFTCore {
    name(): Promise<string>;
    symbol(): Promise<string>;
    totalSupply(): Promise<bigint>;
    ownerOf(tokenId: bigint): Promise<string>;
    balanceOf(owner: string): Promise<bigint>;
    tokenURI(tokenId: bigint): Promise<string>;
    mintTo(to: string, tokenURI: string): Promise<ethers.ContractTransaction>;
    batchMintTo(to: string, tokenURIs: string[]): Promise<ethers.ContractTransaction>;
}

export interface INFTAccess {
    isPublicMintOpen(): Promise<boolean>;
    isPaused(): Promise<boolean>;
    isWhitelisted(account: string): Promise<boolean>;
    getWalletMintLimit(): Promise<bigint>;
    mintedPerWallet(wallet: string): Promise<bigint>;
    canMint(minter: string, quantity: bigint): Promise<boolean>;
    setPublicMintOpen(isOpen: boolean): Promise<ethers.ContractTransaction>;
    addToWhitelist(account: string): Promise<ethers.ContractTransaction>;
    removeFromWhitelist(account: string): Promise<ethers.ContractTransaction>;
}

export interface INFTMetadata {
    contractURI(): Promise<string>;
    getAttribute(tokenId: bigint, key: string): Promise<string>;
    isMetadataFrozen(tokenId: bigint): Promise<boolean>;
    setContractURI(uri: string): Promise<ethers.ContractTransaction>;
    setAttribute(tokenId: bigint, key: string, value: string): Promise<ethers.ContractTransaction>;
    freezeMetadata(tokenId: bigint): Promise<ethers.ContractTransaction>;
}

export interface INFTCollection {
    maxSupply(): Promise<bigint>;
    currentSupply(): Promise<bigint>;
    remainingSupply(): Promise<bigint>;
    royaltyInfo(tokenId: bigint, salePrice: bigint): Promise<[string, bigint]>;
    setDefaultRoyalty(receiver: string, bps: bigint): Promise<ethers.ContractTransaction>;
}

export interface INFTMinimint {
    mint(tokenURI: string): Promise<ethers.ContractTransaction>;
    batchMint(tokenURIs: string[]): Promise<ethers.ContractTransaction>;
    airdrop(recipients: string[], tokenURIs: string[]): Promise<ethers.ContractTransaction>;
}

// Error Types
export type ContractError = 
    | "NotAuthorized"
    | "ZeroAddress"
    | "TokenNotExists"
    | "MintPaused"
    | "NotWhitelisted"
    | "ExceedsMintLimit"
    | "ExceedsMaxSupply"
    | "MetadataFrozen"
    | "ExceedsBatchLimit";

// Network Config
export interface NetworkConfig {
    name: string;
    chainId: number;
    rpcUrl: string;
    blockExplorer: string;
}

export const NETWORKS: Record<string, NetworkConfig> = {
    mainnet: {
        name: "Ethereum Mainnet",
        chainId: 1,
        rpcUrl: "https://mainnet.infura.io/v3/YOUR_KEY",
        blockExplorer: "https://etherscan.io"
    },
    sepolia: {
        name: "Sepolia Testnet",
        chainId: 11155111,
        rpcUrl: "https://sepolia.infura.io/v3/YOUR_KEY",
        blockExplorer: "https://sepolia.etherscan.io"
    },
    hardhat: {
        name: "Hardhat Local",
        chainId: 31337,
        rpcUrl: "http://127.0.0.1:8545",
        blockExplorer: ""
    }
};
