// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTStakingV3
 * @dev Stake NFTs to earn rewards with lock periods and multipliers
 * @author Adekunle Bamz
 * @notice NEW V3 CONTRACT - Stake NFTs and earn rewards
 * 
 * FEATURES:
 *   - Stake single or multiple NFTs
 *   - Lock periods with bonus multipliers
 *   - Claim rewards anytime
 *   - Compound staking
 *   - Emergency unstake (with penalty)
 */
contract NFTStakingV3 is Ownable, ReentrancyGuard {
    
    string public constant VERSION = "3.0.0";
    
    /// @dev Staking info per token
    struct StakeInfo {
        address owner;
        uint256 stakedAt;
        uint256 lockEndTime;
        uint256 lockDuration;
        uint256 lastClaimTime;
        uint256 accumulatedRewards;
    }
    
    /// @dev Lock tier config
    struct LockTier {
        uint256 duration;      // Lock duration in seconds
        uint256 multiplier;    // Reward multiplier (100 = 1x, 150 = 1.5x)
        string name;
    }

    /// @dev NFT contract
    IERC721 public nftContract;
    
    /// @dev NFT Core for locking
    address public nftCoreContract;
    
    /// @dev Base reward per day per NFT (in wei)
    uint256 public baseRewardPerDay = 0.001 ether;
    
    /// @dev Early unstake penalty (basis points, 1000 = 10%)
    uint256 public earlyUnstakePenalty = 1000;
    
    /// @dev Staking enabled
    bool public stakingEnabled = true;
    
    /// @dev Stakes: tokenId => StakeInfo
    mapping(uint256 => StakeInfo) public stakes;
    
    /// @dev User staked tokens
    mapping(address => uint256[]) public userStakedTokens;
    
    /// @dev Lock tiers
    LockTier[] public lockTiers;
    
    /// @dev Total staked count
    uint256 public totalStaked;
    
    /// @dev Total rewards distributed
    uint256 public totalRewardsDistributed;

    event Staked(address indexed user, uint256 indexed tokenId, uint256 lockDuration, uint256 lockEndTime);
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 rewards);
    event RewardsClaimed(address indexed user, uint256 amount);
    event EmergencyUnstake(address indexed user, uint256 indexed tokenId, uint256 penalty);
    event StakingToggled(bool enabled);
    event BaseRewardUpdated(uint256 newReward);
    event LockTierAdded(uint256 duration, uint256 multiplier, string name);

    error StakingDisabled();
    error NotTokenOwner();
    error TokenNotStaked();
    error TokenAlreadyStaked();
    error StillLocked();
    error InvalidLockTier();
    error InsufficientRewardBalance();

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
        
        // Default lock tiers
        lockTiers.push(LockTier(0, 100, "Flexible"));           // No lock, 1x
        lockTiers.push(LockTier(7 days, 125, "7 Days"));        // 7 days, 1.25x
        lockTiers.push(LockTier(30 days, 150, "30 Days"));      // 30 days, 1.5x
        lockTiers.push(LockTier(90 days, 200, "90 Days"));      // 90 days, 2x
    }

    // ============ STAKING ============

    function stake(uint256 tokenId, uint256 lockTierIndex) external nonReentrant {
        if (!stakingEnabled) revert StakingDisabled();
        if (nftContract.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (stakes[tokenId].owner != address(0)) revert TokenAlreadyStaked();
        if (lockTierIndex >= lockTiers.length) revert InvalidLockTier();
        
        LockTier memory tier = lockTiers[lockTierIndex];
        
        // Transfer NFT to staking contract
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        
        // Lock token in NFTCore if set
        if (nftCoreContract != address(0)) {
            INFTCoreLock(nftCoreContract).lockToken(tokenId);
        }
        
        uint256 lockEndTime = tier.duration > 0 ? block.timestamp + tier.duration : 0;
        
        stakes[tokenId] = StakeInfo({
            owner: msg.sender,
            stakedAt: block.timestamp,
            lockEndTime: lockEndTime,
            lockDuration: tier.duration,
            lastClaimTime: block.timestamp,
            accumulatedRewards: 0
        });
        
        userStakedTokens[msg.sender].push(tokenId);
        totalStaked++;
        
        emit Staked(msg.sender, tokenId, tier.duration, lockEndTime);
    }

    function batchStake(uint256[] calldata tokenIds, uint256 lockTierIndex) external nonReentrant {
        if (!stakingEnabled) revert StakingDisabled();
        if (lockTierIndex >= lockTiers.length) revert InvalidLockTier();
        
        LockTier memory tier = lockTiers[lockTierIndex];
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            if (nftContract.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
            if (stakes[tokenId].owner != address(0)) revert TokenAlreadyStaked();
            
            nftContract.transferFrom(msg.sender, address(this), tokenId);
            
            if (nftCoreContract != address(0)) {
                INFTCoreLock(nftCoreContract).lockToken(tokenId);
            }
            
            uint256 lockEndTime = tier.duration > 0 ? block.timestamp + tier.duration : 0;
            
            stakes[tokenId] = StakeInfo({
                owner: msg.sender,
                stakedAt: block.timestamp,
                lockEndTime: lockEndTime,
                lockDuration: tier.duration,
                lastClaimTime: block.timestamp,
                accumulatedRewards: 0
            });
            
            userStakedTokens[msg.sender].push(tokenId);
            totalStaked++;
            
            emit Staked(msg.sender, tokenId, tier.duration, lockEndTime);
        }
    }

    function unstake(uint256 tokenId) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[tokenId];
        if (stakeInfo.owner != msg.sender) revert NotTokenOwner();
        if (stakeInfo.lockEndTime > 0 && block.timestamp < stakeInfo.lockEndTime) revert StillLocked();
        
        uint256 rewards = _calculateRewards(tokenId);
        
        // Unlock token in NFTCore if set
        if (nftCoreContract != address(0)) {
            INFTCoreLock(nftCoreContract).unlockToken(tokenId);
        }
        
        // Transfer NFT back
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        
        // Clear stake
        _removeStake(msg.sender, tokenId);
        delete stakes[tokenId];
        totalStaked--;
        
        // Pay rewards
        if (rewards > 0) {
            _payRewards(msg.sender, rewards);
        }
        
        emit Unstaked(msg.sender, tokenId, rewards);
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[tokenId];
        if (stakeInfo.owner != msg.sender) revert NotTokenOwner();
        
        uint256 rewards = _calculateRewards(tokenId);
        uint256 penalty = 0;
        
        // Apply penalty if still locked
        if (stakeInfo.lockEndTime > 0 && block.timestamp < stakeInfo.lockEndTime) {
            penalty = (rewards * earlyUnstakePenalty) / 10000;
            rewards -= penalty;
        }
        
        // Unlock token
        if (nftCoreContract != address(0)) {
            INFTCoreLock(nftCoreContract).unlockToken(tokenId);
        }
        
        // Transfer NFT back
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        
        // Clear stake
        _removeStake(msg.sender, tokenId);
        delete stakes[tokenId];
        totalStaked--;
        
        // Pay reduced rewards
        if (rewards > 0) {
            _payRewards(msg.sender, rewards);
        }
        
        emit EmergencyUnstake(msg.sender, tokenId, penalty);
    }

    // ============ REWARDS ============

    function claimRewards(uint256 tokenId) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[tokenId];
        if (stakeInfo.owner != msg.sender) revert NotTokenOwner();
        
        uint256 rewards = _calculateRewards(tokenId);
        require(rewards > 0, "NFTStakingV3: No rewards");
        
        stakeInfo.lastClaimTime = block.timestamp;
        stakeInfo.accumulatedRewards = 0;
        
        _payRewards(msg.sender, rewards);
        
        emit RewardsClaimed(msg.sender, rewards);
    }

    function claimAllRewards() external nonReentrant {
        uint256[] memory stakedTokens = userStakedTokens[msg.sender];
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            uint256 tokenId = stakedTokens[i];
            StakeInfo storage stakeInfo = stakes[tokenId];
            
            if (stakeInfo.owner == msg.sender) {
                uint256 rewards = _calculateRewards(tokenId);
                totalRewards += rewards;
                stakeInfo.lastClaimTime = block.timestamp;
                stakeInfo.accumulatedRewards = 0;
            }
        }
        
        require(totalRewards > 0, "NFTStakingV3: No rewards");
        
        _payRewards(msg.sender, totalRewards);
        
        emit RewardsClaimed(msg.sender, totalRewards);
    }

    // ============ INTERNAL ============

    function _calculateRewards(uint256 tokenId) internal view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[tokenId];
        if (stakeInfo.owner == address(0)) return 0;
        
        uint256 stakingDuration = block.timestamp - stakeInfo.lastClaimTime;
        uint256 multiplier = _getMultiplier(stakeInfo.lockDuration);
        
        uint256 baseRewards = (stakingDuration * baseRewardPerDay * multiplier) / (1 days * 100);
        
        return baseRewards + stakeInfo.accumulatedRewards;
    }

    function _getMultiplier(uint256 lockDuration) internal view returns (uint256) {
        for (uint256 i = 0; i < lockTiers.length; i++) {
            if (lockTiers[i].duration == lockDuration) {
                return lockTiers[i].multiplier;
            }
        }
        return 100; // Default 1x
    }

    function _payRewards(address user, uint256 amount) internal {
        if (address(this).balance < amount) revert InsufficientRewardBalance();
        
        totalRewardsDistributed += amount;
        payable(user).transfer(amount);
    }

    function _removeStake(address user, uint256 tokenId) internal {
        uint256[] storage tokens = userStakedTokens[user];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    // ============ VIEW ============

    function pendingRewards(uint256 tokenId) external view returns (uint256) {
        return _calculateRewards(tokenId);
    }

    function userPendingRewards(address user) external view returns (uint256 total) {
        uint256[] memory tokens = userStakedTokens[user];
        for (uint256 i = 0; i < tokens.length; i++) {
            total += _calculateRewards(tokens[i]);
        }
    }

    function getUserStakedTokens(address user) external view returns (uint256[] memory) {
        return userStakedTokens[user];
    }

    function getStakeInfo(uint256 tokenId) external view returns (StakeInfo memory) {
        return stakes[tokenId];
    }

    function getLockTiers() external view returns (LockTier[] memory) {
        return lockTiers;
    }

    function isStaked(uint256 tokenId) external view returns (bool) {
        return stakes[tokenId].owner != address(0);
    }

    // ============ ADMIN ============

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = IERC721(_nftContract);
    }

    function setNFTCoreContract(address _nftCoreContract) external onlyOwner {
        nftCoreContract = _nftCoreContract;
    }

    function setBaseRewardPerDay(uint256 _reward) external onlyOwner {
        baseRewardPerDay = _reward;
        emit BaseRewardUpdated(_reward);
    }

    function setEarlyUnstakePenalty(uint256 _penalty) external onlyOwner {
        require(_penalty <= 5000, "NFTStakingV3: Max 50%");
        earlyUnstakePenalty = _penalty;
    }

    function toggleStaking(bool _enabled) external onlyOwner {
        stakingEnabled = _enabled;
        emit StakingToggled(_enabled);
    }

    function addLockTier(uint256 duration, uint256 multiplier, string memory name) external onlyOwner {
        lockTiers.push(LockTier(duration, multiplier, name));
        emit LockTierAdded(duration, multiplier, name);
    }

    function depositRewards() external payable onlyOwner {}

    function withdrawExcessRewards(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}

interface INFTCoreLock {
    function lockToken(uint256 tokenId) external;
    function unlockToken(uint256 tokenId) external;
}
