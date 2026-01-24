// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTTimeLock
 * @dev Time-based restrictions for NFT operations
 * @author Adekunle Bamz
 * @notice Implements time windows for minting
 */
abstract contract NFTTimeLock {
    
    /// @dev Mint start timestamp
    uint256 public mintStartTime;
    
    /// @dev Mint end timestamp (0 = no end)
    uint256 public mintEndTime;
    
    /// @dev Emitted when mint window is set
    event MintWindowSet(uint256 startTime, uint256 endTime);
    
    /**
     * @notice Check if minting is currently open based on time
     * @return bool True if within mint window
     */
    function isMintWindowOpen() public view returns (bool) {
        if (mintStartTime == 0) {
            return true; // No start time set
        }
        
        if (block.timestamp < mintStartTime) {
            return false; // Not started yet
        }
        
        if (mintEndTime > 0 && block.timestamp > mintEndTime) {
            return false; // Ended
        }
        
        return true;
    }
    
    /**
     * @notice Get time until mint starts
     * @return uint256 Seconds until start (0 if started)
     */
    function timeUntilMintStart() external view returns (uint256) {
        if (mintStartTime == 0 || block.timestamp >= mintStartTime) {
            return 0;
        }
        return mintStartTime - block.timestamp;
    }
    
    /**
     * @notice Get time until mint ends
     * @return uint256 Seconds until end (max if no end)
     */
    function timeUntilMintEnd() external view returns (uint256) {
        if (mintEndTime == 0) {
            return type(uint256).max;
        }
        if (block.timestamp >= mintEndTime) {
            return 0;
        }
        return mintEndTime - block.timestamp;
    }
    
    /**
     * @dev Internal function to set mint window
     */
    function _setMintWindow(uint256 startTime, uint256 endTime) internal {
        require(endTime == 0 || endTime > startTime, "Invalid window");
        mintStartTime = startTime;
        mintEndTime = endTime;
        emit MintWindowSet(startTime, endTime);
    }
}
