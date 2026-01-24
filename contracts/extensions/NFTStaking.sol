// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTStaking
 * @dev Token staking functionality for NFTs
 * @author Adekunle Bamz
 * @notice Lock tokens for staking rewards
 */
abstract contract NFTStaking {
    
    /// @dev Staking info per token
    struct StakeInfo {
        address staker;
        uint256 stakedAt;
        uint256 duration;
    }
    
    /// @dev Mapping of staked tokens
    mapping(uint256 => StakeInfo) public stakes;
    
    /// @dev Total staked count
    uint256 public totalStaked;
    
    /// @dev Whether staking is enabled
    bool public stakingEnabled;
    
    /// @dev Emitted when token is staked
    event TokenStaked(uint256 indexed tokenId, address indexed staker, uint256 duration);
    
    /// @dev Emitted when token is unstaked
    event TokenUnstaked(uint256 indexed tokenId, address indexed staker, uint256 stakedDuration);
    
    /// @dev Emitted when staking status changes
    event StakingStatusChanged(bool enabled);
    
    /**
     * @notice Check if token is staked
     * @param tokenId Token to check
     * @return bool True if staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return stakes[tokenId].stakedAt > 0;
    }
    
    /**
     * @notice Get staking duration for token
     * @param tokenId Token to check
     * @return uint256 Duration staked (0 if not staked)
     */
    function getStakingDuration(uint256 tokenId) public view returns (uint256) {
        StakeInfo memory info = stakes[tokenId];
        if (info.stakedAt == 0) {
            return 0;
        }
        return block.timestamp - info.stakedAt;
    }
    
    /**
     * @notice Get stake info for token
     * @param tokenId Token to query
     */
    function getStakeInfo(uint256 tokenId) external view returns (
        address staker,
        uint256 stakedAt,
        uint256 currentDuration
    ) {
        StakeInfo memory info = stakes[tokenId];
        return (info.staker, info.stakedAt, getStakingDuration(tokenId));
    }
    
    /**
     * @dev Internal function to stake token
     */
    function _stake(uint256 tokenId, address staker) internal {
        require(stakingEnabled, "Staking disabled");
        require(!isStaked(tokenId), "Already staked");
        
        stakes[tokenId] = StakeInfo({
            staker: staker,
            stakedAt: block.timestamp,
            duration: 0
        });
        
        totalStaked++;
        emit TokenStaked(tokenId, staker, 0);
    }
    
    /**
     * @dev Internal function to unstake token
     */
    function _unstake(uint256 tokenId) internal returns (uint256) {
        require(isStaked(tokenId), "Not staked");
        
        StakeInfo memory info = stakes[tokenId];
        uint256 stakedDuration = block.timestamp - info.stakedAt;
        
        delete stakes[tokenId];
        totalStaked--;
        
        emit TokenUnstaked(tokenId, info.staker, stakedDuration);
        return stakedDuration;
    }
    
    /**
     * @dev Internal function to enable/disable staking
     */
    function _setStakingEnabled(bool enabled) internal {
        stakingEnabled = enabled;
        emit StakingStatusChanged(enabled);
    }
}
