// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTCollection
 * @dev Interface for NFTCollection contract
 * @author Adekunle Bamz
 */
interface INFTCollection {
    /// @notice Set max supply
    function setMaxSupply(uint256 newMaxSupply) external;
    
    /// @notice Get max supply
    function maxSupply() external view returns (uint256);
    
    /// @notice Check if can mint amount
    function canMintAmount(uint256 amount) external view returns (bool);
    
    /// @notice Get remaining supply
    function remainingSupply() external view returns (uint256);
    
    /// @notice Set default royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
    
    /// @notice Set token-specific royalty
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;
    
    /// @notice Delete default royalty
    function deleteDefaultRoyalty() external;
    
    /// @notice Delete token royalty
    function deleteTokenRoyalty(uint256 tokenId) external;
    
    /// @notice Get royalty info
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    
    /// @notice Get royalty info as struct
    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount);
}
