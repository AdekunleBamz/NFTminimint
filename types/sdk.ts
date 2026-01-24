/**
 * @title NFTminimint SDK
 * @description JavaScript/TypeScript SDK for interacting with NFTminimint contracts
 */

import { ethers } from "ethers";
import { 
    NFTCoreABI, 
    NFTAccessABI, 
    NFTMetadataABI, 
    NFTCollectionABI, 
    NFTMinimintABI 
} from "./abis";
import type { 
    ContractAddresses, 
    MintParams, 
    BatchMintParams, 
    TokenMetadata,
    CollectionStats,
    TxResult 
} from "./index";

export class NFTminimintSDK {
    private provider: ethers.Provider;
    private signer?: ethers.Signer;
    private addresses: ContractAddresses;
    
    // Contract instances
    private nftCore: ethers.Contract;
    private nftAccess: ethers.Contract;
    private nftMetadata: ethers.Contract;
    private nftCollection: ethers.Contract;
    private nftMinimint: ethers.Contract;
    
    constructor(
        provider: ethers.Provider,
        addresses: ContractAddresses,
        signer?: ethers.Signer
    ) {
        this.provider = provider;
        this.signer = signer;
        this.addresses = addresses;
        
        const contractProvider = signer || provider;
        
        this.nftCore = new ethers.Contract(addresses.nftCore, NFTCoreABI, contractProvider);
        this.nftAccess = new ethers.Contract(addresses.nftAccess, NFTAccessABI, contractProvider);
        this.nftMetadata = new ethers.Contract(addresses.nftMetadata, NFTMetadataABI, contractProvider);
        this.nftCollection = new ethers.Contract(addresses.nftCollection, NFTCollectionABI, contractProvider);
        this.nftMinimint = new ethers.Contract(addresses.nftMinimint, NFTMinimintABI, contractProvider);
    }
    
    /**
     * Connect a signer for write operations
     */
    connect(signer: ethers.Signer): NFTminimintSDK {
        return new NFTminimintSDK(this.provider, this.addresses, signer);
    }
    
    // ===== READ OPERATIONS =====
    
    /**
     * Get collection info
     */
    async getCollectionInfo(): Promise<{ name: string; symbol: string }> {
        const [name, symbol] = await Promise.all([
            this.nftCore.name(),
            this.nftCore.symbol()
        ]);
        return { name, symbol };
    }
    
    /**
     * Get collection statistics
     */
    async getStats(): Promise<CollectionStats> {
        const [totalSupply, maxSupply, currentSupply] = await Promise.all([
            this.nftCore.totalSupply(),
            this.nftCollection.maxSupply(),
            this.nftCollection.currentSupply()
        ]);
        
        return {
            totalSupply: Number(totalSupply),
            maxSupply: Number(maxSupply),
            remainingSupply: Number(maxSupply) - Number(currentSupply),
            uniqueOwners: 0 // Would need to track separately
        };
    }
    
    /**
     * Get token metadata
     */
    async getToken(tokenId: number): Promise<TokenMetadata> {
        const exists = await this.nftCore.tokenExists(tokenId);
        if (!exists) {
            throw new Error("Token does not exist");
        }
        
        const [uri, owner, creator, frozen] = await Promise.all([
            this.nftCore.tokenURI(tokenId),
            this.nftCore.ownerOf(tokenId),
            this.nftCore.getCreator(tokenId),
            this.nftMetadata.isMetadataFrozen(tokenId)
        ]);
        
        return {
            tokenId,
            uri,
            owner,
            creator,
            attributes: {},
            frozen
        };
    }
    
    /**
     * Get tokens owned by address
     */
    async getBalance(address: string): Promise<number> {
        const balance = await this.nftCore.balanceOf(address);
        return Number(balance);
    }
    
    /**
     * Check if address can mint
     */
    async canMint(address: string, quantity: number = 1): Promise<boolean> {
        return this.nftAccess.canMint(address, quantity);
    }
    
    /**
     * Get minted count for wallet
     */
    async getMintedCount(address: string): Promise<number> {
        const count = await this.nftAccess.mintedPerWallet(address);
        return Number(count);
    }
    
    /**
     * Check whitelist status
     */
    async isWhitelisted(address: string): Promise<boolean> {
        return this.nftAccess.isWhitelisted(address);
    }
    
    /**
     * Get royalty info for token
     */
    async getRoyaltyInfo(tokenId: number, salePrice: bigint): Promise<{ receiver: string; amount: bigint }> {
        const [receiver, amount] = await this.nftCollection.royaltyInfo(tokenId, salePrice);
        return { receiver, amount };
    }
    
    // ===== WRITE OPERATIONS =====
    
    /**
     * Mint a single token
     */
    async mint(tokenURI: string): Promise<TxResult> {
        if (!this.signer) throw new Error("Signer required");
        
        const tx = await this.nftMinimint.mint(tokenURI);
        const receipt = await tx.wait();
        
        return this._formatReceipt(receipt);
    }
    
    /**
     * Batch mint tokens
     */
    async batchMint(tokenURIs: string[]): Promise<TxResult> {
        if (!this.signer) throw new Error("Signer required");
        
        const tx = await this.nftMinimint.batchMint(tokenURIs);
        const receipt = await tx.wait();
        
        return this._formatReceipt(receipt);
    }
    
    /**
     * Transfer a token
     */
    async transfer(to: string, tokenId: number): Promise<TxResult> {
        if (!this.signer) throw new Error("Signer required");
        
        const from = await this.signer.getAddress();
        const tx = await this.nftCore.transferFrom(from, to, tokenId);
        const receipt = await tx.wait();
        
        return this._formatReceipt(receipt);
    }
    
    // ===== HELPER METHODS =====
    
    private _formatReceipt(receipt: ethers.TransactionReceipt): TxResult {
        return {
            success: receipt.status === 1,
            txHash: receipt.hash,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed,
            events: []
        };
    }
    
    /**
     * Get contract addresses
     */
    getAddresses(): ContractAddresses {
        return { ...this.addresses };
    }
}

export default NFTminimintSDK;
