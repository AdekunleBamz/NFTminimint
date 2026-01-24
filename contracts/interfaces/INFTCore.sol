// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTCore
 * @dev Interface for NFTCore contract
 * @author Adekunle Bamz
 */
interface INFTCore {
    /// @notice Mint a new token
    function mint(address to, string memory uri) external returns (uint256);
    
    /// @notice Batch mint tokens
    function batchMint(address to, string[] memory uris) external returns (uint256);
    
    /// @notice Get total minted tokens
    function totalMinted() external view returns (uint256);
    
    /// @notice Get total supply
    function totalSupply() external view returns (uint256);
    
    /// @notice Check if token exists
    function exists(uint256 tokenId) external view returns (bool);
    
    /// @notice Get token owner
    function ownerOf(uint256 tokenId) external view returns (address);
    
    /// @notice Get token URI
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    /// @notice Get token creation info
    function getTokenCreationInfo(uint256 tokenId) external view returns (address creator, uint256 timestamp);
    
    /// @notice Get tokens owned by address
    function tokensOfOwner(address owner_) external view returns (uint256[] memory);
    
    /// @notice Check if minter is authorized
    function isMinterAuthorized(address minter) external view returns (bool);
    
    /// @notice Get circulating supply
    function circulatingSupply() external view returns (uint256);
    
    /// @notice Get total burned
    function totalBurned() external view returns (uint256);
}
