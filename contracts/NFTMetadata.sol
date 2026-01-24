// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTCore.sol";

/**
 * @title NFTMetadata
 * @dev Manages NFT metadata with advanced features
 * @author Adekunle Bamz
 * @notice Handles dynamic metadata, batch updates, and metadata freezing
 */
abstract contract NFTMetadata is NFTCore {
    
    /// @dev Flag indicating if metadata is permanently frozen
    bool public metadataFrozen;
    
    /// @dev Mapping for individual token metadata freeze status
    mapping(uint256 => bool) internal _tokenMetadataFrozen;
    
    /// @dev Contract-level metadata URI (for OpenSea collection info)
    string public contractURI;
    
    /// @dev Mapping for token-specific attributes
    mapping(uint256 => mapping(string => string)) internal _tokenAttributes;
    
    /// @dev List of attribute keys for each token
    mapping(uint256 => string[]) internal _tokenAttributeKeys;

    /**
     * @dev Emitted when metadata is permanently frozen
     */
    event MetadataFrozen();

    /**
     * @dev Emitted when a specific token's metadata is frozen
     * @param tokenId The frozen token ID
     */
    event TokenMetadataFrozen(uint256 indexed tokenId);

    /**
     * @dev Emitted when contract URI is updated
     * @param newContractURI The new contract URI
     */
    event ContractURIUpdated(string newContractURI);

    /**
     * @dev Emitted when a token's URI is updated
     * @param tokenId The token ID
     * @param newURI The new metadata URI
     */
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);

    /**
     * @dev Emitted when batch metadata update occurs
     * @param startTokenId First token in the range
     * @param endTokenId Last token in the range
     * @param baseURI New base URI applied
     */
    event BatchMetadataUpdate(uint256 indexed startTokenId, uint256 indexed endTokenId, string baseURI);

    /**
     * @dev Emitted when token attribute is set
     * @param tokenId The token ID
     * @param key Attribute key
     * @param value Attribute value
     */
    event TokenAttributeSet(uint256 indexed tokenId, string key, string value);

    /**
     * @dev Modifier to check if metadata can be modified
     */
    modifier whenMetadataNotFrozen() {
        require(!metadataFrozen, "NFTMetadata: Metadata is frozen");
        _;
    }

    /**
     * @dev Modifier to check if specific token metadata can be modified
     */
    modifier whenTokenMetadataNotFrozen(uint256 tokenId) {
        require(!_tokenMetadataFrozen[tokenId], "NFTMetadata: Token metadata is frozen");
        require(!metadataFrozen, "NFTMetadata: All metadata is frozen");
        _;
    }

    /**
     * @notice Check if a token's metadata is frozen
     * @param tokenId Token ID to check
     * @return True if frozen
     */
    function isTokenMetadataFrozen(uint256 tokenId) public view virtual returns (bool) {
        return _tokenMetadataFrozen[tokenId] || metadataFrozen;
    }

    /**
     * @notice Get a specific attribute of a token
     * @param tokenId Token ID to query
     * @param key Attribute key
     * @return The attribute value
     */
    function getTokenAttribute(uint256 tokenId, string memory key) public view virtual returns (string memory) {
        require(exists(tokenId), "NFTMetadata: Token does not exist");
        return _tokenAttributes[tokenId][key];
    }

    /**
     * @notice Get all attribute keys for a token
     * @param tokenId Token ID to query
     * @return Array of attribute keys
     */
    function getTokenAttributeKeys(uint256 tokenId) public view virtual returns (string[] memory) {
        require(exists(tokenId), "NFTMetadata: Token does not exist");
        return _tokenAttributeKeys[tokenId];
    }

    /**
     * @dev Internal function to update a token's URI
     * @param tokenId Token to update
     * @param newURI New metadata URI
     */
    function _updateTokenURI(uint256 tokenId, string memory newURI) 
        internal 
        virtual 
        whenTokenMetadataNotFrozen(tokenId) 
    {
        require(exists(tokenId), "NFTMetadata: Token does not exist");
        _setTokenURI(tokenId, newURI);
        emit TokenURIUpdated(tokenId, newURI);
    }

    /**
     * @dev Internal function to set contract-level URI
     * @param newContractURI New contract metadata URI
     */
    function _setContractURI(string memory newContractURI) internal virtual whenMetadataNotFrozen {
        contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    /**
     * @dev Internal function to freeze all metadata permanently
     */
    function _freezeMetadata() internal virtual whenMetadataNotFrozen {
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    /**
     * @dev Internal function to freeze specific token metadata
     * @param tokenId Token ID to freeze
     */
    function _freezeTokenMetadata(uint256 tokenId) internal virtual whenTokenMetadataNotFrozen(tokenId) {
        require(exists(tokenId), "NFTMetadata: Token does not exist");
        _tokenMetadataFrozen[tokenId] = true;
        emit TokenMetadataFrozen(tokenId);
    }

    /**
     * @dev Internal function to set token attribute
     * @param tokenId Token ID
     * @param key Attribute key
     * @param value Attribute value
     */
    function _setTokenAttribute(uint256 tokenId, string memory key, string memory value) 
        internal 
        virtual 
        whenTokenMetadataNotFrozen(tokenId) 
    {
        require(exists(tokenId), "NFTMetadata: Token does not exist");
        
        // Check if key already exists
        bool keyExists = false;
        for (uint256 i = 0; i < _tokenAttributeKeys[tokenId].length; i++) {
            if (keccak256(bytes(_tokenAttributeKeys[tokenId][i])) == keccak256(bytes(key))) {
                keyExists = true;
                break;
            }
        }
        
        if (!keyExists) {
            _tokenAttributeKeys[tokenId].push(key);
        }
        
        _tokenAttributes[tokenId][key] = value;
        emit TokenAttributeSet(tokenId, key, value);
    }

    /**
     * @dev Internal function for batch URI update
     * @param startTokenId Starting token ID
     * @param endTokenId Ending token ID (inclusive)
     * @param baseURI Base URI to apply
     */
    function _batchUpdateMetadata(uint256 startTokenId, uint256 endTokenId, string memory baseURI) 
        internal 
        virtual 
        whenMetadataNotFrozen 
    {
        require(startTokenId <= endTokenId, "NFTMetadata: Invalid range");
        require(endTokenId < _tokenIdCounter, "NFTMetadata: End token does not exist");
        
        _setBaseURI(baseURI);
        emit BatchMetadataUpdate(startTokenId, endTokenId, baseURI);
    }
}
