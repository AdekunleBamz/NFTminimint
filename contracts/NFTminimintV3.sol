// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTminimintV3
 * @dev Main controller contract - DEPLOY LAST
 * @author Adekunle Bamz
 * @notice Main minting interface with V3 features - FREE MINTING!
 * 
 * DEPLOYMENT ORDER: 7th (Last)
 * CONSTRUCTOR ARGS: 6
 *   - nftCore_ (address): Address of deployed NFTCoreV3 contract
 *   - nftMetadata_ (address): Address of deployed NFTMetadataV3 contract
 *   - nftAccess_ (address): Address of deployed NFTAccessV3 contract
 *   - nftCollection_ (address): Address of deployed NFTCollectionV3 contract
 *   - marketplace_ (address): Address of deployed NFTMarketplaceV3 contract
 *   - staking_ (address): Address of deployed NFTStakingV3 contract
 * 
 * AFTER DEPLOYMENT - LINKING STEPS:
 *   1. Call NFTCoreV3.authorizeMinter(NFTminimintV3 address)
 *   2. Call NFTCoreV3.authorizeLocker(NFTStakingV3 address, true)
 *   3. Call NFTAccessV3.authorizeCaller(NFTminimintV3 address, true)
 *   4. Call NFTMetadataV3.authorizeCaller(NFTminimintV3 address, true)
 *   5. Call NFTCollectionV3.authorizeCaller(NFTminimintV3 address, true)
 *   6. Call NFTMarketplaceV3.setRoyaltyContract(NFTCollectionV3 address)
 */

interface INFTCoreV3 {
    function mint(address to, string memory uri) external returns (uint256);
    function mintSoulBound(address to, string memory uri) external returns (uint256);
    function batchMint(address to, string[] memory uris) external returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function exists(uint256 tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function creators(uint256 tokenId) external view returns (address);
    function mintTimestamps(uint256 tokenId) external view returns (uint256);
    function isTransferable(uint256 tokenId) external view returns (bool);
    function getTokenInfo(uint256 tokenId) external view returns (address, address, uint256, bool, bool, string memory);
}

interface INFTAccessV3 {
    function canMint(address account) external view returns (bool, string memory);
    function recordMint(address wallet) external;
    function recordMints(address wallet, uint256 count) external;
    function remainingMints(address wallet) external view returns (uint256);
    function getWalletInfo(address wallet) external view returns (uint8, uint256, uint256, address, uint256);
}

interface INFTCollectionV3 {
    function canMintQuantity(uint256 quantity) external view returns (bool);
    function isSoldOut() external view returns (bool);
    function getStats() external view returns (uint256, uint256, uint256);
    function incrementSupply() external;
    function incrementSupplyBy(uint256 amount) external;
    function currentPhase() external view returns (uint8);
}

interface INFTMetadataV3 {
    function setAttribute(uint256 tokenId, string memory key, string memory value) external;
    function setNumericTrait(uint256 tokenId, string memory traitName, uint256 value) external;
    function increaseNumericTrait(uint256 tokenId, string memory traitName, uint256 amount) external;
    function getAttribute(uint256 tokenId, string memory key) external view returns (string memory);
    function getNumericTrait(uint256 tokenId, string memory traitName) external view returns (uint256);
}

contract NFTminimintV3 is Ownable, ReentrancyGuard {
    
    string public constant VERSION = "3.0.0";
    
    INFTCoreV3 public nftCore;
    INFTMetadataV3 public nftMetadata;
    INFTAccessV3 public nftAccess;
    INFTCollectionV3 public nftCollection;
    address public marketplace;
    address public staking;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri);
    event SoulBoundMinted(address indexed to, uint256 indexed tokenId);
    event BatchMinted(address indexed to, uint256 startTokenId, uint256 quantity);
    event Airdropped(uint256 recipients, uint256 totalTokens);
    event TraitUpdated(uint256 indexed tokenId, string key, string value);
    event NumericTraitUpdated(uint256 indexed tokenId, string traitName, uint256 value);
    event ContractsUpdated(address core, address metadata, address access, address collection, address marketplace, address staking);

    constructor(
        address nftCore_,
        address nftMetadata_,
        address nftAccess_,
        address nftCollection_,
        address marketplace_,
        address staking_
    ) Ownable(msg.sender) {
        require(nftCore_ != address(0), "NFTminimintV3: Zero core address");
        require(nftMetadata_ != address(0), "NFTminimintV3: Zero metadata address");
        require(nftAccess_ != address(0), "NFTminimintV3: Zero access address");
        require(nftCollection_ != address(0), "NFTminimintV3: Zero collection address");
        
        nftCore = INFTCoreV3(nftCore_);
        nftMetadata = INFTMetadataV3(nftMetadata_);
        nftAccess = INFTAccessV3(nftAccess_);
        nftCollection = INFTCollectionV3(nftCollection_);
        marketplace = marketplace_;
        staking = staking_;
    }

    // ============ MODIFIERS ============

    modifier canMint(address to) {
        (bool allowed, string memory reason) = nftAccess.canMint(to);
        require(allowed, reason);
        _;
    }

    modifier withinSupply(uint256 quantity) {
        require(nftCollection.canMintQuantity(quantity), "NFTminimintV3: Exceeds max supply");
        _;
    }

    // ============ PUBLIC MINTING ============

    function mint(string memory uri) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(1) 
        returns (uint256) 
    {
        uint256 tokenId = nftCore.mint(msg.sender, uri);
        nftAccess.recordMint(msg.sender);
        nftCollection.incrementSupply();
        
        emit NFTMinted(msg.sender, tokenId, uri);
        return tokenId;
    }

    function mintTo(address to, string memory uri) 
        external 
        nonReentrant 
        canMint(to) 
        withinSupply(1) 
        returns (uint256) 
    {
        uint256 tokenId = nftCore.mint(to, uri);
        nftAccess.recordMint(to);
        nftCollection.incrementSupply();
        
        emit NFTMinted(to, tokenId, uri);
        return tokenId;
    }

    function mintSoulBound(string memory uri) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(1) 
        returns (uint256) 
    {
        uint256 tokenId = nftCore.mintSoulBound(msg.sender, uri);
        nftAccess.recordMint(msg.sender);
        nftCollection.incrementSupply();
        
        emit SoulBoundMinted(msg.sender, tokenId);
        return tokenId;
    }

    function batchMint(string[] memory uris) 
        external 
        nonReentrant 
        canMint(msg.sender) 
        withinSupply(uris.length) 
        returns (uint256) 
    {
        require(uris.length > 0, "NFTminimintV3: Empty URIs");
        require(uris.length <= 50, "NFTminimintV3: Max 50 per batch");
        
        uint256 remaining = nftAccess.remainingMints(msg.sender);
        require(uris.length <= remaining, "NFTminimintV3: Exceeds wallet limit");
        
        uint256 startTokenId = nftCore.batchMint(msg.sender, uris);
        nftAccess.recordMints(msg.sender, uris.length);
        nftCollection.incrementSupplyBy(uris.length);
        
        emit BatchMinted(msg.sender, startTokenId, uris.length);
        return startTokenId;
    }

    // ============ MINT WITH TRAITS ============

    function mintWithTraits(
        string memory uri,
        string[] memory traitKeys,
        string[] memory traitValues
    ) external nonReentrant canMint(msg.sender) withinSupply(1) returns (uint256) {
        require(traitKeys.length == traitValues.length, "NFTminimintV3: Length mismatch");
        
        uint256 tokenId = nftCore.mint(msg.sender, uri);
        nftAccess.recordMint(msg.sender);
        nftCollection.incrementSupply();
        
        // Set traits
        for (uint256 i = 0; i < traitKeys.length; i++) {
            nftMetadata.setAttribute(tokenId, traitKeys[i], traitValues[i]);
            emit TraitUpdated(tokenId, traitKeys[i], traitValues[i]);
        }
        
        emit NFTMinted(msg.sender, tokenId, uri);
        return tokenId;
    }

    function mintWithNumericTraits(
        string memory uri,
        string[] memory traitNames,
        uint256[] memory traitValues
    ) external nonReentrant canMint(msg.sender) withinSupply(1) returns (uint256) {
        require(traitNames.length == traitValues.length, "NFTminimintV3: Length mismatch");
        
        uint256 tokenId = nftCore.mint(msg.sender, uri);
        nftAccess.recordMint(msg.sender);
        nftCollection.incrementSupply();
        
        // Set numeric traits
        for (uint256 i = 0; i < traitNames.length; i++) {
            nftMetadata.setNumericTrait(tokenId, traitNames[i], traitValues[i]);
        }
        
        emit NFTMinted(msg.sender, tokenId, uri);
        return tokenId;
    }

    // ============ TRAIT MANAGEMENT ============

    function updateTrait(uint256 tokenId, string memory key, string memory value) external {
        require(nftCore.ownerOf(tokenId) == msg.sender, "NFTminimintV3: Not owner");
        nftMetadata.setAttribute(tokenId, key, value);
        emit TraitUpdated(tokenId, key, value);
    }

    function levelUp(uint256 tokenId) external {
        require(nftCore.ownerOf(tokenId) == msg.sender, "NFTminimintV3: Not owner");
        nftMetadata.increaseNumericTrait(tokenId, "level", 1);
        
        uint256 newLevel = nftMetadata.getNumericTrait(tokenId, "level");
        emit NumericTraitUpdated(tokenId, "level", newLevel);
    }

    function addExperience(uint256 tokenId, uint256 amount) external onlyOwner {
        nftMetadata.increaseNumericTrait(tokenId, "experience", amount);
        
        uint256 newXP = nftMetadata.getNumericTrait(tokenId, "experience");
        emit NumericTraitUpdated(tokenId, "experience", newXP);
    }

    // ============ ADMIN MINTING ============

    function airdrop(address[] memory recipients, string memory uri) 
        external 
        onlyOwner 
        withinSupply(recipients.length) 
    {
        require(recipients.length > 0, "NFTminimintV3: No recipients");
        require(recipients.length <= 100, "NFTminimintV3: Max 100 per airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "NFTminimintV3: Zero address");
            nftCore.mint(recipients[i], uri);
        }
        
        nftCollection.incrementSupplyBy(recipients.length);
        emit Airdropped(recipients.length, recipients.length);
    }

    function airdropSoulBound(address[] memory recipients, string memory uri) 
        external 
        onlyOwner 
        withinSupply(recipients.length) 
    {
        require(recipients.length > 0, "NFTminimintV3: No recipients");
        require(recipients.length <= 100, "NFTminimintV3: Max 100 per airdrop");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "NFTminimintV3: Zero address");
            nftCore.mintSoulBound(recipients[i], uri);
        }
        
        nftCollection.incrementSupplyBy(recipients.length);
        emit Airdropped(recipients.length, recipients.length);
    }

    // ============ CONTRACT MANAGEMENT ============

    function updateContracts(
        address nftCore_,
        address nftMetadata_,
        address nftAccess_,
        address nftCollection_,
        address marketplace_,
        address staking_
    ) external onlyOwner {
        require(nftCore_ != address(0), "NFTminimintV3: Zero core address");
        
        nftCore = INFTCoreV3(nftCore_);
        nftMetadata = INFTMetadataV3(nftMetadata_);
        nftAccess = INFTAccessV3(nftAccess_);
        nftCollection = INFTCollectionV3(nftCollection_);
        marketplace = marketplace_;
        staking = staking_;
        
        emit ContractsUpdated(nftCore_, nftMetadata_, nftAccess_, nftCollection_, marketplace_, staking_);
    }

    // ============ VIEW FUNCTIONS ============

    function getContracts() external view returns (
        address core,
        address metadata,
        address access,
        address collection,
        address marketplace_,
        address staking_
    ) {
        return (
            address(nftCore),
            address(nftMetadata),
            address(nftAccess),
            address(nftCollection),
            marketplace,
            staking
        );
    }

    function canAddressMint(address account) external view returns (bool canMint_, string memory reason) {
        (bool accessOk, string memory accessReason) = nftAccess.canMint(account);
        if (!accessOk) return (false, accessReason);
        if (nftCollection.isSoldOut()) return (false, "Sold out");
        return (true, "Can mint");
    }

    function getCollectionInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 totalMinted,
        uint256 maxSupply,
        uint256 remaining,
        uint8 phase
    ) {
        name = nftCore.name();
        symbol = nftCore.symbol();
        (totalMinted, maxSupply, remaining) = nftCollection.getStats();
        phase = nftCollection.currentPhase();
    }

    function getTokenInfo(uint256 tokenId) external view returns (
        address owner_,
        address creator,
        uint256 mintTime,
        bool locked,
        bool soulBound,
        string memory uri
    ) {
        require(nftCore.exists(tokenId), "NFTminimintV3: Token doesn't exist");
        return nftCore.getTokenInfo(tokenId);
    }

    function getTokenTraits(uint256 tokenId, string[] memory keys) external view returns (string[] memory values) {
        values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = nftMetadata.getAttribute(tokenId, keys[i]);
        }
    }

    function getTokenNumericTraits(uint256 tokenId, string[] memory traitNames) external view returns (uint256[] memory values) {
        values = new uint256[](traitNames.length);
        for (uint256 i = 0; i < traitNames.length; i++) {
            values[i] = nftMetadata.getNumericTrait(tokenId, traitNames[i]);
        }
    }
}
