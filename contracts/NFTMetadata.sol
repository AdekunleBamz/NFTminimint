// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTMetadataV2
 * @dev Metadata management contract - DEPLOY SECOND
 * @author Adekunle Bamz
 * @notice Manages metadata attributes, freezing, and contract URI
 * 
 * DEPLOYMENT ORDER: 2nd
 * CONSTRUCTOR ARGS: 1
 *   - nftCore_ (address): Address of deployed NFTCoreV2 contract
 */

interface INFTCore {
    function exists(uint256 tokenId) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract NFTMetadataV2 is Ownable {
    
    /// @dev Reference to NFTCore contract
    INFTCore public nftCore;
    
    /// @dev Contract-level metadata URI (for OpenSea)
    string public contractURI;
    
    /// @dev Global metadata freeze flag
    bool public metadataFrozen;
    
    /// @dev Per-token metadata freeze
    mapping(uint256 => bool) public tokenMetadataFrozen;
    
    /// @dev Token attributes storage
    mapping(uint256 => mapping(string => string)) private _attributes;
    
    /// @dev Attribute keys per token
    mapping(uint256 => string[]) private _attributeKeys;

    /// @dev Emitted when contract URI is set
    event ContractURIUpdated(string newURI);
    
    /// @dev Emitted when metadata is frozen globally
    event MetadataFrozen();
    
    /// @dev Emitted when token metadata is frozen
    event TokenMetadataFrozen(uint256 indexed tokenId);
    
    /// @dev Emitted when attribute is set
    event AttributeSet(uint256 indexed tokenId, string key, string value);
    
    /// @dev Emitted when NFTCore reference is updated
    event NFTCoreUpdated(address indexed newCore);
    
    /// @dev Emitted when attribute is removed
    event AttributeRemoved(uint256 indexed tokenId, string key);

    /**
     * @dev Constructor
     * @param nftCore_ Address of NFTCore contract
     */
    constructor(address nftCore_) Ownable(msg.sender) {
        require(nftCore_ != address(0), "NFTMetadataV2: Zero address");
        nftCore = INFTCore(nftCore_);
    }

    // ============ MODIFIERS ============

    modifier whenNotFrozen() {
        require(!metadataFrozen, "NFTMetadataV2: Metadata frozen");
        _;
    }

    modifier whenTokenNotFrozen(uint256 tokenId) {
        require(!metadataFrozen, "NFTMetadataV2: Metadata frozen");
        require(!tokenMetadataFrozen[tokenId], "NFTMetadataV2: Token frozen");
        _;
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Update NFTCore reference
     * @param newCore New NFTCore address
     */
    function setNFTCore(address newCore) external onlyOwner {
        require(newCore != address(0), "NFTMetadataV2: Zero address");
        nftCore = INFTCore(newCore);
        emit NFTCoreUpdated(newCore);
    }

    /**
     * @notice Set contract URI (OpenSea collection metadata)
     * @param uri Contract metadata URI
     */
    function setContractURI(string memory uri) external onlyOwner whenNotFrozen {
        contractURI = uri;
        emit ContractURIUpdated(uri);
    }

    /**
     * @notice Freeze all metadata permanently
     */
    function freezeMetadata() external onlyOwner whenNotFrozen {
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    /**
     * @notice Freeze specific token metadata
     * @param tokenId Token to freeze
     */
    function freezeTokenMetadata(uint256 tokenId) external onlyOwner whenTokenNotFrozen(tokenId) {
        require(nftCore.exists(tokenId), "NFTMetadataV2: Token doesn't exist");
        tokenMetadataFrozen[tokenId] = true;
        emit TokenMetadataFrozen(tokenId);
    }

    // ============ ATTRIBUTE MANAGEMENT ============

    /**
     * @notice Set token attribute
     * @param tokenId Token ID
     * @param key Attribute key
     * @param value Attribute value
     */
    function setAttribute(uint256 tokenId, string memory key, string memory value) 
        external 
        onlyOwner 
        whenTokenNotFrozen(tokenId) 
    {
        require(nftCore.exists(tokenId), "NFTMetadataV2: Token doesn't exist");
        require(bytes(key).length > 0, "NFTMetadataV2: Empty key");
        
        // Check if key exists
        bool keyExists = false;
        for (uint256 i = 0; i < _attributeKeys[tokenId].length; i++) {
            if (keccak256(bytes(_attributeKeys[tokenId][i])) == keccak256(bytes(key))) {
                keyExists = true;
                break;
            }
        }
        
        if (!keyExists) {
            _attributeKeys[tokenId].push(key);
        }
        
        _attributes[tokenId][key] = value;
        emit AttributeSet(tokenId, key, value);
    }

    /**
     * @notice Batch set attributes for a token
     * @param tokenId Token ID
     * @param keys Attribute keys
     * @param values Attribute values
     */
    function batchSetAttributes(
        uint256 tokenId, 
        string[] memory keys, 
        string[] memory values
    ) external onlyOwner whenTokenNotFrozen(tokenId) {
        require(nftCore.exists(tokenId), "NFTMetadataV2: Token doesn't exist");
        require(keys.length == values.length, "NFTMetadataV2: Length mismatch");
        
        for (uint256 i = 0; i < keys.length; i++) {
            require(bytes(keys[i]).length > 0, "NFTMetadataV2: Empty key");
            
            bool keyExists = false;
            for (uint256 j = 0; j < _attributeKeys[tokenId].length; j++) {
                if (keccak256(bytes(_attributeKeys[tokenId][j])) == keccak256(bytes(keys[i]))) {
                    keyExists = true;
                    break;
                }
            }
            
            if (!keyExists) {
                _attributeKeys[tokenId].push(keys[i]);
            }
            
            _attributes[tokenId][keys[i]] = values[i];
            emit AttributeSet(tokenId, keys[i], values[i]);
        }
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Get attribute value
     * @param tokenId Token ID
     * @param key Attribute key
     */
    function getAttribute(uint256 tokenId, string memory key) external view returns (string memory) {
        return _attributes[tokenId][key];
    }

    /**
     * @notice Get all attribute keys for a token
     * @param tokenId Token ID
     */
    function getAttributeKeys(uint256 tokenId) external view returns (string[] memory) {
        return _attributeKeys[tokenId];
    }

    /**
     * @notice Get all attributes for a token
     * @param tokenId Token ID
     */
    function getAllAttributes(uint256 tokenId) external view returns (
        string[] memory keys,
        string[] memory values
    ) {
        keys = _attributeKeys[tokenId];
        values = new string[](keys.length);
        
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _attributes[tokenId][keys[i]];
        }
    }

    /**
     * @notice Check if token metadata is frozen
     * @param tokenId Token to check
     */
    function isTokenFrozen(uint256 tokenId) external view returns (bool) {
        return metadataFrozen || tokenMetadataFrozen[tokenId];
    }

    /**
     * @notice Remove an attribute from a token
     * @param tokenId Token ID
     * @param key Attribute key to remove
     */
    function removeAttribute(uint256 tokenId, string memory key) 
        external 
        onlyOwner 
        whenTokenNotFrozen(tokenId) 
    {
        require(nftCore.exists(tokenId), "NFTMetadataV2: Token doesn't exist");
        delete _attributes[tokenId][key];
        emit AttributeRemoved(tokenId, key);
    }
}
