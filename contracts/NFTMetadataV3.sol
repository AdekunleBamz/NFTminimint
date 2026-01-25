// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTMetadataV3
 * @dev On-chain traits, dynamic metadata, and freeze functionality
 * @author Adekunle Bamz
 * @notice DEPLOY SECOND - Metadata management with V3 features
 * 
 * V3 NEW FEATURES:
 *   - On-chain traits storage (fully on-chain, not just URI)
 *   - Dynamic/evolving traits (level up, experience, etc.)
 *   - Metadata freeze (permanently lock metadata)
 *   - Trait categories and rarity
 */
contract NFTMetadataV3 is Ownable {
    
    string public constant VERSION = "3.0.0";
    
    string public baseURI;
    
    /// @dev Authorized callers
    mapping(address => bool) public authorizedCallers;
    
    /// @dev Token attributes: tokenId => key => value
    mapping(uint256 => mapping(string => string)) public tokenAttributes;
    
    /// @dev Dynamic numeric traits: tokenId => traitName => value
    mapping(uint256 => mapping(string => uint256)) public numericTraits;
    
    /// @dev Frozen metadata (cannot be changed)
    mapping(uint256 => bool) public frozenMetadata;
    
    /// @dev All trait keys for a token
    mapping(uint256 => string[]) public tokenTraitKeys;
    
    /// @dev Trait categories
    mapping(string => string) public traitCategories; // traitName => category
    
    /// @dev Rarity scores
    mapping(uint256 => uint256) public rarityScores;

    event AttributeSet(uint256 indexed tokenId, string key, string value);
    event NumericTraitSet(uint256 indexed tokenId, string traitName, uint256 value);
    event NumericTraitIncreased(uint256 indexed tokenId, string traitName, uint256 oldValue, uint256 newValue);
    event MetadataFrozen(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event RarityScoreSet(uint256 indexed tokenId, uint256 score);
    event CallerAuthorized(address indexed caller, bool status);

    error MetadataIsFrozen(uint256 tokenId);
    error NotAuthorizedCaller();

    constructor() Ownable(msg.sender) {}

    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert NotAuthorizedCaller();
        _;
    }

    modifier notFrozen(uint256 tokenId) {
        if (frozenMetadata[tokenId]) revert MetadataIsFrozen(tokenId);
        _;
    }

    // ============ STRING ATTRIBUTES ============

    function setAttribute(uint256 tokenId, string memory key, string memory value) 
        external 
        onlyAuthorized 
        notFrozen(tokenId) 
    {
        tokenAttributes[tokenId][key] = value;
        
        // Track keys if new
        bool exists = false;
        for (uint256 i = 0; i < tokenTraitKeys[tokenId].length; i++) {
            if (keccak256(bytes(tokenTraitKeys[tokenId][i])) == keccak256(bytes(key))) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            tokenTraitKeys[tokenId].push(key);
        }
        
        emit AttributeSet(tokenId, key, value);
    }

    function setAttributes(uint256 tokenId, string[] memory keys, string[] memory values) 
        external 
        onlyAuthorized 
        notFrozen(tokenId) 
    {
        require(keys.length == values.length, "NFTMetadataV3: Length mismatch");
        
        for (uint256 i = 0; i < keys.length; i++) {
            tokenAttributes[tokenId][keys[i]] = values[i];
            emit AttributeSet(tokenId, keys[i], values[i]);
        }
    }

    function getAttribute(uint256 tokenId, string memory key) external view returns (string memory) {
        return tokenAttributes[tokenId][key];
    }

    // ============ NUMERIC TRAITS (DYNAMIC) ============

    function setNumericTrait(uint256 tokenId, string memory traitName, uint256 value) 
        external 
        onlyAuthorized 
        notFrozen(tokenId) 
    {
        numericTraits[tokenId][traitName] = value;
        emit NumericTraitSet(tokenId, traitName, value);
    }

    function increaseNumericTrait(uint256 tokenId, string memory traitName, uint256 amount) 
        external 
        onlyAuthorized 
        notFrozen(tokenId) 
    {
        uint256 oldValue = numericTraits[tokenId][traitName];
        uint256 newValue = oldValue + amount;
        numericTraits[tokenId][traitName] = newValue;
        emit NumericTraitIncreased(tokenId, traitName, oldValue, newValue);
    }

    function decreaseNumericTrait(uint256 tokenId, string memory traitName, uint256 amount) 
        external 
        onlyAuthorized 
        notFrozen(tokenId) 
    {
        uint256 oldValue = numericTraits[tokenId][traitName];
        require(oldValue >= amount, "NFTMetadataV3: Underflow");
        uint256 newValue = oldValue - amount;
        numericTraits[tokenId][traitName] = newValue;
        emit NumericTraitIncreased(tokenId, traitName, oldValue, newValue);
    }

    function getNumericTrait(uint256 tokenId, string memory traitName) external view returns (uint256) {
        return numericTraits[tokenId][traitName];
    }

    // ============ BATCH NUMERIC OPERATIONS ============

    function batchSetNumericTraits(
        uint256 tokenId, 
        string[] memory traitNames, 
        uint256[] memory values
    ) external onlyAuthorized notFrozen(tokenId) {
        require(traitNames.length == values.length, "NFTMetadataV3: Length mismatch");
        
        for (uint256 i = 0; i < traitNames.length; i++) {
            numericTraits[tokenId][traitNames[i]] = values[i];
            emit NumericTraitSet(tokenId, traitNames[i], values[i]);
        }
    }

    // ============ RARITY ============

    function setRarityScore(uint256 tokenId, uint256 score) external onlyAuthorized notFrozen(tokenId) {
        rarityScores[tokenId] = score;
        emit RarityScoreSet(tokenId, score);
    }

    function setTraitCategory(string memory traitName, string memory category) external onlyOwner {
        traitCategories[traitName] = category;
    }

    // ============ FREEZE ============

    function freezeMetadata(uint256 tokenId) external onlyAuthorized {
        require(!frozenMetadata[tokenId], "NFTMetadataV3: Already frozen");
        frozenMetadata[tokenId] = true;
        emit MetadataFrozen(tokenId);
    }

    function batchFreezeMetadata(uint256[] calldata tokenIds) external onlyAuthorized {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!frozenMetadata[tokenIds[i]]) {
                frozenMetadata[tokenIds[i]] = true;
                emit MetadataFrozen(tokenIds[i]);
            }
        }
    }

    // ============ BASE URI ============

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // ============ ADMIN ============

    function authorizeCaller(address caller, bool status) external onlyOwner {
        authorizedCallers[caller] = status;
        emit CallerAuthorized(caller, status);
    }

    // ============ VIEW FUNCTIONS ============

    function getAllTraitKeys(uint256 tokenId) external view returns (string[] memory) {
        return tokenTraitKeys[tokenId];
    }

    function getFullMetadata(uint256 tokenId) external view returns (
        string[] memory keys,
        string[] memory values,
        uint256 rarity,
        bool frozen
    ) {
        keys = tokenTraitKeys[tokenId];
        values = new string[](keys.length);
        
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = tokenAttributes[tokenId][keys[i]];
        }
        
        return (keys, values, rarityScores[tokenId], frozenMetadata[tokenId]);
    }
}
