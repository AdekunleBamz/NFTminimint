// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTAccess
 * @dev Interface for NFTAccess contract
 * @author Adekunle Bamz
 */
interface INFTAccess {
    /// @notice Add to whitelist
    function addToWhitelist(address account) external;
    
    /// @notice Remove from whitelist
    function removeFromWhitelist(address account) external;
    
    /// @notice Batch add to whitelist
    function batchAddToWhitelist(address[] calldata accounts) external;
    
    /// @notice Set whitelist enabled status
    function setWhitelistEnabled(bool enabled) external;
    
    /// @notice Set public mint status
    function setPublicMintOpen(bool open) external;
    
    /// @notice Set wallet mint limit
    function setWalletMintLimit(uint256 limit) external;
    
    /// @notice Record a mint
    function recordMint(address wallet, uint256 count) external;
    
    /// @notice Check if can mint
    function canMint(address account) external view returns (bool canMint_, string memory reason);
    
    /// @notice Check if whitelisted
    function isWhitelisted(address account) external view returns (bool);
    
    /// @notice Check if admin
    function isAdmin(address account) external view returns (bool);
    
    /// @notice Get whitelist count
    function whitelistCount() external view returns (uint256);
    
    /// @notice Get public mint status
    function publicMintOpen() external view returns (bool);
    
    /// @notice Get whitelist enabled status
    function whitelistEnabled() external view returns (bool);
    
    /// @notice Get wallet mint limit
    function walletMintLimit() external view returns (uint256);
    
    /// @notice Get minted per wallet
    function mintedPerWallet(address wallet) external view returns (uint256);
}
