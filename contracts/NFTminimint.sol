// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTminimintV2
 * @dev Main controller contract - DEPLOY FIFTH (LAST)
 * @author Adekunle Bamz
 * @notice Main minting interface that connects all contracts - FREE MINTING!
 * 
 * DEPLOYMENT ORDER: 5th (Last)
 * CONSTRUCTOR ARGS: 4
 *   - nftCore_ (address): Address of deployed NFTCoreV2 contract
 *   - nftMetadata_ (address): Address of deployed NFTMetadataV2 contract
 *   - nftAccess_ (address): Address of deployed NFTAccessV2 contract
 *   - nftCollection_ (address): Address of deployed NFTCollectionV2 contract
 * 
 * AFTER DEPLOYMENT - LINKING STEPS:
 *   1. Call NFTCoreV2.authorizeMinter(NFTminimintV2 address)
 *   2. Call NFTAccessV2.authorizeCaller(NFTminimintV2 address)
 */

interface INFTCoreMain {
    function mint(address to, string memory uri) external returns (uint256);
    function batchMint(address to, string[] memory uris) external returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function exists(uint256 tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function creators(uint256 tokenId) external view returns (address);
    function mintTimestamps(uint256 tokenId) external view returns (uint256);
}

interface INFTAccessMain {
    function canMint(address account) external view returns (bool, string memory);
    function recordMint(address wallet) external;
    function recordMints(address wallet, uint256 count) external;
    function remainingMints(address wallet) external view returns (uint256);
    function publicMintOpen() external view returns (bool);
    function whitelistEnabled() external view returns (bool);
    function paused() external view returns (bool);
}

interface INFTCollectionMain {
    function canMintQuantity(uint256 quantity) external view returns (bool);
    function isSoldOut() external view returns (bool);
    function getStats() external view returns (uint256, uint256, uint256);
}

contract NFTminimintV2 is Ownable, ReentrancyGuard {
    
    /// @dev Version
    string public constant VERSION = "2.0.0";
    
    /// @dev Reference to NFTCore
    INFTCoreMain public nftCore;
    
    /// @dev Reference to NFTMetadata (stored but accessed directly)
    address public nftMetadata;
    
    /// @dev Reference to NFTAccess
    INFTAccessMain public nftAccess;
    
    /// @dev Reference to NFTCollection
    INFTCollectionMain public nftCollection;

    /// @dev Emitted when NFT is minted
    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri);
    
    /// @dev Emitted when batch mint occurs
    event BatchMinted(address indexed to, uint256 startTokenId, uint256 quantity);
    
    /// @dev Emitted when airdrop occurs
    event Airdropped(uint256 recipients, uint256 totalTokens);
    
    /// @dev Emitted when contract references are updated
    event ContractsUpdated(address core, address metadata, address access, address collection);

    /**
     * @dev Constructor
     * @param nftCore_ Address of NFTCore contract
     * @param nftMetadata_ Address of NFTMetadata contract
     * @param nftAccess_ Address of NFTAccess contract
     * @param nftCollection_ Address of NFTCollection contract
     */
    constructor(
        address nftCore_,
        address nftMetadata_,
        address nftAccess_,
        address nftCollection_
    ) Ownable(msg.sender) {
        require(nftCore_ != address(0), "NFTminimintV2: Zero core address");
        require(nftMetadata_ != address(0), "NFTminimintV2: Zero metadata address");
        require(nftAccess_ != address(0), "NFTminimintV2: Zero access address");
        require(nftCollection_ != address(0), "NFTminimintV2: Zero collection address");
        
        nftCore = INFTCoreMain(nftCore_);
        nftMetadata = nftMetadata_;
        nftAccess = INFTAccessMain(nftAccess_);
        nftCollection = INFTCollectionMain(nftCollection_);
    }

    // ============ MODIFIERS ============

    modifier canMint(address to) {
        (bool allowed, string memory reason) = nftAccess.canMint(to);
        require(allowed, reason);
        _;
    }

    modifier withinSupply(uint256 quantity) {
        require(nftCollection.canMintQuantity(quantity), "NFTminimintV2: Exceeds max supply");
        _;
    }

    // ============ PUBLIC MINTING (FREE!) ============

    /**
     * @notice Mint NFT to yourself - FREE!
     * @param uri Metadata URI
     * @return tokenId Minted token ID
     */
    function mint(string memory uri) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(1) 
        returns (uint256) 
    {
        uint256 tokenId = nftCore.mint(msg.sender, uri);
        nftAccess.recordMint(msg.sender);
        
        emit NFTMinted(msg.sender, tokenId, uri);
        return tokenId;
    }

    /**
     * @notice Mint NFT to specific address - FREE!
     * @param to Recipient
     * @param uri Metadata URI
     * @return tokenId Minted token ID
     */
    function mintTo(address to, string memory uri) 
        external 
        nonReentrant 
        canMint(to) 
        withinSupply(1) 
        returns (uint256) 
    {
        uint256 tokenId = nftCore.mint(to, uri);
        nftAccess.recordMint(to);
        
        emit NFTMinted(to, tokenId, uri);
        return tokenId;
    }

    /**
     * @notice Batch mint multiple NFTs - FREE!
     * @param uris Array of metadata URIs
     * @return startTokenId First minted token ID
     */
    function batchMint(string[] memory uris) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(uris.length) 
        returns (uint256) 
    {
        require(uris.length > 0, "NFTminimintV2: Empty URIs");
        require(uris.length <= 50, "NFTminimintV2: Max 50 per batch");
        
        // Check wallet limit
        uint256 remaining = nftAccess.remainingMints(msg.sender);
        require(uris.length <= remaining, "NFTminimintV2: Exceeds wallet limit");
        
        uint256 startTokenId = nftCore.batchMint(msg.sender, uris);
        nftAccess.recordMints(msg.sender, uris.length);
        
        emit BatchMinted(msg.sender, startTokenId, uris.length);
        return startTokenId;
    }

    // ============ ADMIN MINTING ============

    /**
     * @notice Airdrop to multiple addresses
     * @param recipients Array of recipients
     * @param uri Metadata URI for all
     */
    function airdrop(address[] memory recipients, string memory uri) 
        external 
        onlyOwner 
        withinSupply(recipients.length) 
    {
        require(recipients.length > 0, "NFTminimintV2: No recipients");
        require(recipients.length <= 100, "NFTminimintV2: Max 100 per airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "NFTminimintV2: Zero address");
            nftCore.mint(recipients[i], uri);
        }
        
        emit Airdropped(recipients.length, recipients.length);
    }

    /**
     * @notice Airdrop with unique URIs
     * @param recipients Array of recipients
     * @param uris Array of URIs (1 per recipient)
     */
    function airdropWithURIs(address[] memory recipients, string[] memory uris) 
        external 
        onlyOwner 
        withinSupply(recipients.length) 
    {
        require(recipients.length > 0, "NFTminimintV2: No recipients");
        require(recipients.length == uris.length, "NFTminimintV2: Length mismatch");
        require(recipients.length <= 100, "NFTminimintV2: Max 100 per airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "NFTminimintV2: Zero address");
            nftCore.mint(recipients[i], uris[i]);
        }
        
        emit Airdropped(recipients.length, recipients.length);
    }

    // ============ CONTRACT MANAGEMENT ============

    /**
     * @notice Update all contract references
     * @param nftCore_ New NFTCore address
     * @param nftMetadata_ New NFTMetadata address
     * @param nftAccess_ New NFTAccess address
     * @param nftCollection_ New NFTCollection address
     */
    function updateContracts(
        address nftCore_,
        address nftMetadata_,
        address nftAccess_,
        address nftCollection_
    ) external onlyOwner {
        require(nftCore_ != address(0), "NFTminimintV2: Zero core address");
        require(nftMetadata_ != address(0), "NFTminimintV2: Zero metadata address");
        require(nftAccess_ != address(0), "NFTminimintV2: Zero access address");
        require(nftCollection_ != address(0), "NFTminimintV2: Zero collection address");
        
        nftCore = INFTCoreMain(nftCore_);
        nftMetadata = nftMetadata_;
        nftAccess = INFTAccessMain(nftAccess_);
        nftCollection = INFTCollectionMain(nftCollection_);
        
        emit ContractsUpdated(nftCore_, nftMetadata_, nftAccess_, nftCollection_);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get all contract addresses
     */
    function getContracts() external view returns (
        address core,
        address metadata,
        address access,
        address collection
    ) {
        return (
            address(nftCore),
            nftMetadata,
            address(nftAccess),
            address(nftCollection)
        );
    }

    /**
     * @notice Check if address can mint
     * @param account Address to check
     */
    function canAddressMint(address account) external view returns (
        bool canMint_,
        string memory reason
    ) {
        // Check access control
        (bool accessOk, string memory accessReason) = nftAccess.canMint(account);
        if (!accessOk) {
            return (false, accessReason);
        }
        
        // Check supply
        if (nftCollection.isSoldOut()) {
            return (false, "Sold out");
        }
        
        return (true, "Can mint");
    }

    /**
     * @notice Get full collection info
     */
    function getCollectionInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 totalMinted,
        uint256 maxSupply,
        uint256 remaining,
        bool publicMintOpen,
        bool whitelistEnabled,
        bool paused
    ) {
        name = nftCore.name();
        symbol = nftCore.symbol();
        (totalMinted, maxSupply, remaining) = nftCollection.getStats();
        publicMintOpen = nftAccess.publicMintOpen();
        whitelistEnabled = nftAccess.whitelistEnabled();
        paused = nftAccess.paused();
    }

    /**
     * @notice Get token info
     * @param tokenId Token to query
     */
    function getTokenInfo(uint256 tokenId) external view returns (
        address owner_,
        string memory uri,
        address creator,
        uint256 mintTime
    ) {
        require(nftCore.exists(tokenId), "NFTminimintV2: Token doesn't exist");
        
        owner_ = nftCore.ownerOf(tokenId);
        uri = nftCore.tokenURI(tokenId);
        creator = nftCore.creators(tokenId);
        mintTime = nftCore.mintTimestamps(tokenId);
    }
}
