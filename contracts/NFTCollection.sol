// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTAccess.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NFTCollection
 * @dev Collection-level features including supply limits and royalties
 * @author Adekunle Bamz
 * @notice Manages collection metadata, max supply, and EIP-2981 royalties
 */
abstract contract NFTCollection is NFTAccess, IERC2981 {
    
    /// @dev Maximum supply of tokens (0 = unlimited)
    uint256 public maxSupply;
    
    /// @dev Collection name (for marketplace display)
    string public collectionName;
    
    /// @dev Collection description
    string public collectionDescription;
    
    /// @dev Collection image URI
    string public collectionImage;
    
    /// @dev Collection external link
    string public collectionExternalLink;
    
    /// @dev Default royalty recipient
    address public royaltyRecipient;
    
    /// @dev Default royalty percentage in basis points (e.g., 250 = 2.5%)
    uint96 public royaltyBps;
    
    /// @dev Per-token royalty overrides
    mapping(uint256 => address) internal _tokenRoyaltyRecipient;
    mapping(uint256 => uint96) internal _tokenRoyaltyBps;
    
    /// @dev Collection statistics
    uint256 public totalBurned;
    uint256 public totalTransfers;

    /**
     * @dev Emitted when max supply is set
     * @param oldSupply Previous max supply
     * @param newSupply New max supply
     */
    event MaxSupplySet(uint256 oldSupply, uint256 newSupply);

    /**
     * @dev Emitted when collection info is updated
     * @param name Collection name
     * @param description Collection description
     */
    event CollectionInfoUpdated(string name, string description);

    /**
     * @dev Emitted when default royalty is set
     * @param recipient Royalty recipient
     * @param bps Royalty basis points
     */
    event DefaultRoyaltySet(address indexed recipient, uint96 bps);

    /**
     * @dev Emitted when token royalty is set
     * @param tokenId Token ID
     * @param recipient Royalty recipient
     * @param bps Royalty basis points
     */
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed recipient, uint96 bps);

    /**
     * @dev Modifier to check supply limit
     */
    modifier withinSupply(uint256 quantity) {
        if (maxSupply > 0) {
            require(_tokenIdCounter + quantity <= maxSupply, "NFTCollection: Would exceed max supply");
        }
        _;
    }

    /**
     * @notice Get remaining mintable supply
     * @return Remaining supply (type(uint256).max if unlimited)
     */
    function remainingSupply() public view virtual returns (uint256) {
        if (maxSupply == 0) {
            return type(uint256).max;
        }
        if (_tokenIdCounter >= maxSupply) {
            return 0;
        }
        return maxSupply - _tokenIdCounter;
    }

    /**
     * @notice Check if collection is sold out
     * @return True if sold out
     */
    function isSoldOut() public view virtual returns (bool) {
        if (maxSupply == 0) {
            return false;
        }
        return _tokenIdCounter >= maxSupply;
    }

    /**
     * @notice Get collection statistics
     * @return minted Total minted
     * @return burned Total burned
     * @return transfers Total transfers
     * @return currentSupply Current active supply
     */
    function collectionStats() public view virtual returns (
        uint256 minted,
        uint256 burned,
        uint256 transfers,
        uint256 currentSupply
    ) {
        return (
            _tokenIdCounter,
            totalBurned,
            totalTransfers,
            _tokenIdCounter - totalBurned
        );
    }

    /**
     * @notice EIP-2981 royalty info
     * @param tokenId Token ID to query
     * @param salePrice Sale price to calculate royalty from
     * @return receiver Royalty recipient
     * @return royaltyAmount Royalty amount
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        public 
        view 
        virtual 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        // Check for token-specific royalty
        if (_tokenRoyaltyRecipient[tokenId] != address(0)) {
            receiver = _tokenRoyaltyRecipient[tokenId];
            royaltyAmount = (salePrice * _tokenRoyaltyBps[tokenId]) / 10000;
        } else if (royaltyRecipient != address(0)) {
            // Use default royalty
            receiver = royaltyRecipient;
            royaltyAmount = (salePrice * royaltyBps) / 10000;
        } else {
            receiver = address(0);
            royaltyAmount = 0;
        }
    }

    /**
     * @dev Internal function to set max supply
     * @param supply New max supply (0 = unlimited)
     */
    function _setMaxSupply(uint256 supply) internal virtual {
        require(supply == 0 || supply >= _tokenIdCounter, "NFTCollection: Supply less than minted");
        uint256 oldSupply = maxSupply;
        maxSupply = supply;
        emit MaxSupplySet(oldSupply, supply);
    }

    /**
     * @dev Internal function to set collection info
     * @param name Collection name
     * @param description Collection description
     * @param image Collection image URI
     * @param externalLink Collection external link
     */
    function _setCollectionInfo(
        string memory name,
        string memory description,
        string memory image,
        string memory externalLink
    ) internal virtual {
        collectionName = name;
        collectionDescription = description;
        collectionImage = image;
        collectionExternalLink = externalLink;
        emit CollectionInfoUpdated(name, description);
    }

    /**
     * @dev Internal function to set default royalty
     * @param recipient Royalty recipient
     * @param bps Royalty basis points (max 10000 = 100%)
     */
    function _setDefaultRoyalty(address recipient, uint96 bps) internal virtual {
        require(bps <= 10000, "NFTCollection: Royalty too high");
        royaltyRecipient = recipient;
        royaltyBps = bps;
        emit DefaultRoyaltySet(recipient, bps);
    }

    /**
     * @dev Internal function to set token-specific royalty
     * @param tokenId Token ID
     * @param recipient Royalty recipient
     * @param bps Royalty basis points
     */
    function _setTokenRoyalty(uint256 tokenId, address recipient, uint96 bps) internal virtual {
        require(exists(tokenId), "NFTCollection: Token does not exist");
        require(bps <= 10000, "NFTCollection: Royalty too high");
        _tokenRoyaltyRecipient[tokenId] = recipient;
        _tokenRoyaltyBps[tokenId] = bps;
        emit TokenRoyaltySet(tokenId, recipient, bps);
    }

    /**
     * @dev Internal function to delete token royalty (revert to default)
     * @param tokenId Token ID
     */
    function _deleteTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyRecipient[tokenId];
        delete _tokenRoyaltyBps[tokenId];
    }

    /**
     * @dev Override burn to track statistics
     */
    function _burnToken(uint256 tokenId) internal virtual override {
        super._burnToken(tokenId);
        totalBurned++;
        // Clean up token royalty
        _deleteTokenRoyalty(tokenId);
    }

    /**
     * @dev Override transfer to track statistics
     */
    function _update(address to, uint256 tokenId, address auth) 
        internal 
        virtual 
        override 
        returns (address) 
    {
        address from = super._update(to, tokenId, auth);
        
        // Track transfers (not mints or burns)
        if (from != address(0) && to != address(0)) {
            totalTransfers++;
        }
        
        return from;
    }

    // ============ Required Overrides ============

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(NFTAccess, IERC165) 
        returns (bool) 
    {
        return 
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
