// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTBurnable
 * @dev Enhanced burning functionality for NFTs
 * @author Adekunle Bamz
 * @notice Implements additional burn tracking and controls
 */
abstract contract NFTBurnable {
    
    /// @dev Mapping of burned token IDs
    mapping(uint256 => bool) private _burnedTokens;
    
    /// @dev Total tokens burned
    uint256 private _totalBurned;
    
    /// @dev Whether burning is enabled
    bool public burningEnabled = true;
    
    /// @dev Emitted when token is burned
    event TokenBurnedExtended(uint256 indexed tokenId, address indexed burner, uint256 timestamp);
    
    /// @dev Emitted when burning status changes
    event BurningStatusChanged(bool enabled);
    
    /**
     * @notice Check if a token was burned
     * @param tokenId Token to check
     * @return bool True if burned
     */
    function wasBurned(uint256 tokenId) external view returns (bool) {
        return _burnedTokens[tokenId];
    }
    
    /**
     * @notice Get total burned count
     * @return uint256 Total burned
     */
    function getTotalBurned() external view returns (uint256) {
        return _totalBurned;
    }
    
    /**
     * @dev Internal function to record a burn
     */
    function _recordBurn(uint256 tokenId, address burner) internal {
        require(burningEnabled, "Burning disabled");
        _burnedTokens[tokenId] = true;
        _totalBurned++;
        emit TokenBurnedExtended(tokenId, burner, block.timestamp);
    }
    
    /**
     * @dev Internal function to enable/disable burning
     */
    function _setBurningEnabled(bool enabled) internal {
        burningEnabled = enabled;
        emit BurningStatusChanged(enabled);
    }
}
