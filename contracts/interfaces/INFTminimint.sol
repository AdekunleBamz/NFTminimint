// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTminimint
 * @dev Interface for NFTminimint main controller contract
 * @author Adekunle Bamz
 */
interface INFTminimint {
    /// @notice Mint NFT to caller
    function mint(string memory tokenURI) external returns (uint256);
    
    /// @notice Mint NFT to specific address
    function mintTo(address to, string memory tokenURI) external returns (uint256);
    
    /// @notice Batch mint to caller
    function batchMint(string[] memory tokenURIs) external returns (uint256);
    
    /// @notice Airdrop to multiple recipients
    function airdrop(address[] calldata recipients, string[] memory tokenURIs) external;
    
    /// @notice Get NFTCore contract address
    function nftCore() external view returns (address);
    
    /// @notice Get NFTMetadata contract address
    function nftMetadata() external view returns (address);
    
    /// @notice Get NFTAccess contract address
    function nftAccess() external view returns (address);
    
    /// @notice Get NFTCollection contract address
    function nftCollection() external view returns (address);
}
