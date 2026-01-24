// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTMetadata
 * @dev Interface for NFTMetadata contract
 * @author Adekunle Bamz
 */
interface INFTMetadata {
    /// @notice Set token attribute
    function setAttribute(uint256 tokenId, string memory key, string memory value) external;
    
    /// @notice Get token attribute
    function getAttribute(uint256 tokenId, string memory key) external view returns (string memory);
    
    /// @notice Get all attribute keys for a token
    function getAttributeKeys(uint256 tokenId) external view returns (string[] memory);
    
    /// @notice Remove token attribute
    function removeAttribute(uint256 tokenId, string memory key) external;
    
    /// @notice Freeze all metadata
    function freezeMetadata() external;
    
    /// @notice Freeze individual token metadata
    function freezeTokenMetadata(uint256 tokenId) external;
    
    /// @notice Check if metadata is frozen
    function metadataFrozen() external view returns (bool);
    
    /// @notice Check if token metadata is frozen
    function tokenMetadataFrozen(uint256 tokenId) external view returns (bool);
    
    /// @notice Set contract URI
    function setContractURI(string memory uri) external;
    
    /// @notice Get contract URI
    function contractURI() external view returns (string memory);
}
