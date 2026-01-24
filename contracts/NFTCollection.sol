// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NFTCollection
 * @dev Collection management contract - DEPLOY FOURTH
 * @author Adekunle Bamz
 * @notice Manages supply limits, royalties, and collection info
 * 
 * DEPLOYMENT ORDER: 4th
 * CONSTRUCTOR ARGS: 2
 *   - nftCore_ (address): Address of deployed NFTCore contract
 *   - maxSupply_ (uint256): Maximum supply (0 = unlimited)
 */

interface INFTCoreCollection {
    function totalSupply() external view returns (uint256);
    function exists(uint256 tokenId) external view returns (bool);
}

contract NFTCollection is Ownable, IERC2981 {
    
    /// @dev Reference to NFTCore contract
    INFTCoreCollection public nftCore;
    
    /// @dev Maximum supply (0 = unlimited)
    uint256 public maxSupply;
    
    /// @dev Collection name for display
    string public collectionName;
    
    /// @dev Collection description
    string public collectionDescription;
    
    /// @dev Collection image URI
    string public collectionImage;
    
    /// @dev Collection external link
    string public externalLink;
    
    /// @dev Default royalty recipient
    address public royaltyRecipient;
    
    /// @dev Default royalty basis points (250 = 2.5%)
    uint96 public royaltyBps;
    
    /// @dev Per-token royalty recipient
    mapping(uint256 => address) public tokenRoyaltyRecipient;
    
    /// @dev Per-token royalty bps
    mapping(uint256 => uint96) public tokenRoyaltyBps;
    
    /// @dev Has token-specific royalty
    mapping(uint256 => bool) public hasTokenRoyalty;

    /// @dev Emitted when max supply is set
    event MaxSupplySet(uint256 newMaxSupply);
    
    /// @dev Emitted when collection info is updated
    event CollectionInfoUpdated(string name, string description);
    
    /// @dev Emitted when default royalty is set
    event DefaultRoyaltySet(address indexed recipient, uint96 bps);
    
    /// @dev Emitted when token royalty is set
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed recipient, uint96 bps);
    
    /// @dev Emitted when NFTCore reference updates
    event NFTCoreUpdated(address indexed newCore);
    
    /// @dev Emitted when token royalty is deleted
    event TokenRoyaltyDeleted(uint256 indexed tokenId);

    /**
     * @dev Constructor
     * @param nftCore_ Address of NFTCore contract
     * @param maxSupply_ Maximum supply (0 = unlimited)
     */
    constructor(address nftCore_, uint256 maxSupply_) Ownable(msg.sender) {
        require(nftCore_ != address(0), "NFTCollection: Zero address");
        nftCore = INFTCoreCollection(nftCore_);
        maxSupply = maxSupply_;
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Update NFTCore reference
     * @param newCore New NFTCore address
     */
    function setNFTCore(address newCore) external onlyOwner {
        require(newCore != address(0), "NFTCollection: Zero address");
        nftCore = INFTCoreCollection(newCore);
        emit NFTCoreUpdated(newCore);
    }

    /**
     * @notice Set maximum supply
     * @param newMaxSupply New max supply (0 = unlimited)
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(
            newMaxSupply == 0 || newMaxSupply >= nftCore.totalSupply(),
            "NFTCollection: Below current supply"
        );
        maxSupply = newMaxSupply;
        emit MaxSupplySet(newMaxSupply);
    }

    /**
     * @notice Set collection info
     * @param name_ Collection name
     * @param description_ Collection description
     * @param image_ Collection image URI
     * @param link_ External link
     */
    function setCollectionInfo(
        string memory name_,
        string memory description_,
        string memory image_,
        string memory link_
    ) external onlyOwner {
        collectionName = name_;
        collectionDescription = description_;
        collectionImage = image_;
        externalLink = link_;
        emit CollectionInfoUpdated(name_, description_);
    }

    // ============ ROYALTY FUNCTIONS ============

    /**
     * @notice Set default royalty
     * @param recipient Royalty recipient
     * @param bps Basis points (e.g., 250 = 2.5%)
     */
    function setDefaultRoyalty(address recipient, uint96 bps) external onlyOwner {
        require(bps <= 10000, "NFTCollection: Royalty too high");
        royaltyRecipient = recipient;
        royaltyBps = bps;
        emit DefaultRoyaltySet(recipient, bps);
    }

    /**
     * @notice Set token-specific royalty
     * @param tokenId Token ID
     * @param recipient Royalty recipient
     * @param bps Basis points
     */
    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 bps) external onlyOwner {
        require(nftCore.exists(tokenId), "NFTCollection: Token doesn't exist");
        require(bps <= 10000, "NFTCollection: Royalty too high");
        
        tokenRoyaltyRecipient[tokenId] = recipient;
        tokenRoyaltyBps[tokenId] = bps;
        hasTokenRoyalty[tokenId] = true;
        
        emit TokenRoyaltySet(tokenId, recipient, bps);
    }

    /**
     * @notice Remove token-specific royalty (use default)
     * @param tokenId Token ID
     */
    function deleteTokenRoyalty(uint256 tokenId) external onlyOwner {
        delete tokenRoyaltyRecipient[tokenId];
        delete tokenRoyaltyBps[tokenId];
        hasTokenRoyalty[tokenId] = false;
        emit TokenRoyaltyDeleted(tokenId);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice EIP-2981 royalty info
     * @param tokenId Token ID
     * @param salePrice Sale price
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        if (hasTokenRoyalty[tokenId]) {
            receiver = tokenRoyaltyRecipient[tokenId];
            royaltyAmount = (salePrice * tokenRoyaltyBps[tokenId]) / 10000;
        } else {
            receiver = royaltyRecipient;
            royaltyAmount = (salePrice * royaltyBps) / 10000;
        }
    }

    /**
     * @notice Get remaining supply
     */
    function remainingSupply() external view returns (uint256) {
        if (maxSupply == 0) {
            return type(uint256).max;
        }
        uint256 minted = nftCore.totalSupply();
        if (minted >= maxSupply) {
            return 0;
        }
        return maxSupply - minted;
    }

    /**
     * @notice Check if sold out
     */
    function isSoldOut() external view returns (bool) {
        if (maxSupply == 0) {
            return false;
        }
        return nftCore.totalSupply() >= maxSupply;
    }

    /**
     * @notice Check if can mint quantity
     * @param quantity Number to mint
     */
    function canMintQuantity(uint256 quantity) external view returns (bool) {
        if (maxSupply == 0) {
            return true;
        }
        return nftCore.totalSupply() + quantity <= maxSupply;
    }

    /**
     * @notice Get collection stats
     */
    function getStats() external view returns (
        uint256 totalMinted,
        uint256 maxSupply_,
        uint256 remaining
    ) {
        totalMinted = nftCore.totalSupply();
        maxSupply_ = maxSupply;
        if (maxSupply == 0) {
            remaining = type(uint256).max;
        } else {
            remaining = maxSupply > totalMinted ? maxSupply - totalMinted : 0;
        }
    }

    // ============ ERC165 ============

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
