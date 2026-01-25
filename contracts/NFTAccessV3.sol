// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTAccessV3
 * @dev Tiered whitelist, time-based mint windows, and referral tracking
 * @author Adekunle Bamz
 * @notice DEPLOY THIRD - Access control with V3 features
 * 
 * V3 NEW FEATURES:
 *   - Tiered whitelist (VIP → Early → Public)
 *   - Time-based mint windows (opens/closes automatically)
 *   - Referral tracking and rewards
 *   - Per-tier mint limits
 */
contract NFTAccessV3 is Ownable {
    
    string public constant VERSION = "3.0.0";
    
    /// @dev Whitelist tiers
    enum Tier { NONE, PUBLIC, EARLY, VIP }
    
    /// @dev Mint window config
    struct MintWindow {
        uint256 startTime;
        uint256 endTime;
        bool active;
    }
    
    /// @dev Referral info
    struct ReferralInfo {
        address referrer;
        uint256 referralCount;
        uint256 rewardsEarned;
    }

    /// @dev Authorized callers
    mapping(address => bool) public authorizedCallers;
    
    /// @dev Wallet tier assignments
    mapping(address => Tier) public walletTiers;
    
    /// @dev Mint counts per wallet
    mapping(address => uint256) public mintCounts;
    
    /// @dev Referral tracking
    mapping(address => ReferralInfo) public referrals;
    
    /// @dev Referral codes: code => referrer
    mapping(bytes32 => address) public referralCodes;
    
    /// @dev Who referred who: referred => referrer
    mapping(address => address) public referredBy;

    /// @dev Mint limits per tier
    mapping(Tier => uint256) public tierMintLimits;
    
    /// @dev Mint windows per tier
    mapping(Tier => MintWindow) public mintWindows;
    
    /// @dev Global settings
    bool public paused;
    uint256 public maxMintsPerWallet = type(uint256).max;
    uint256 public referralRewardPercent = 5; // 5% of future rewards

    event TierAssigned(address indexed wallet, Tier tier);
    event MintRecorded(address indexed wallet, uint256 count);
    event Paused(bool status);
    event MintWindowSet(Tier tier, uint256 startTime, uint256 endTime);
    event ReferralCodeCreated(address indexed referrer, bytes32 code);
    event ReferralUsed(address indexed referred, address indexed referrer);
    event ReferralRewardEarned(address indexed referrer, uint256 amount);
    event CallerAuthorized(address indexed caller, bool status);

    error NotAuthorizedCaller();
    error MintingPaused();
    error NotInMintWindow();
    error ExceedsWalletLimit();
    error InsufficientTier();
    error InvalidReferralCode();

    constructor() Ownable(msg.sender) {
        // Set default tier limits
        tierMintLimits[Tier.VIP] = 10;
        tierMintLimits[Tier.EARLY] = 5;
        tierMintLimits[Tier.PUBLIC] = 3;
        
        // VIP window always open by default
        mintWindows[Tier.VIP] = MintWindow(0, type(uint256).max, true);
    }

    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert NotAuthorizedCaller();
        _;
    }

    // ============ TIER MANAGEMENT ============

    function setWalletTier(address wallet, Tier tier) external onlyOwner {
        walletTiers[wallet] = tier;
        emit TierAssigned(wallet, tier);
    }

    function batchSetTiers(address[] calldata wallets, Tier tier) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            walletTiers[wallets[i]] = tier;
            emit TierAssigned(wallets[i], tier);
        }
    }

    function setTierMintLimit(Tier tier, uint256 limit) external onlyOwner {
        tierMintLimits[tier] = limit;
    }

    // ============ MINT WINDOWS ============

    function setMintWindow(Tier tier, uint256 startTime, uint256 endTime) external onlyOwner {
        mintWindows[tier] = MintWindow(startTime, endTime, true);
        emit MintWindowSet(tier, startTime, endTime);
    }

    function closeMintWindow(Tier tier) external onlyOwner {
        mintWindows[tier].active = false;
    }

    function openMintWindow(Tier tier) external onlyOwner {
        mintWindows[tier].active = true;
    }

    function isWindowOpen(Tier tier) public view returns (bool) {
        MintWindow memory window = mintWindows[tier];
        if (!window.active) return false;
        return block.timestamp >= window.startTime && block.timestamp <= window.endTime;
    }

    // ============ REFERRAL SYSTEM ============

    function createReferralCode(string memory code) external returns (bytes32) {
        bytes32 codeHash = keccak256(abi.encodePacked(code, msg.sender));
        require(referralCodes[codeHash] == address(0), "NFTAccessV3: Code exists");
        
        referralCodes[codeHash] = msg.sender;
        emit ReferralCodeCreated(msg.sender, codeHash);
        return codeHash;
    }

    function useReferralCode(bytes32 codeHash) external {
        address referrer = referralCodes[codeHash];
        if (referrer == address(0)) revert InvalidReferralCode();
        require(referrer != msg.sender, "NFTAccessV3: Cannot refer self");
        require(referredBy[msg.sender] == address(0), "NFTAccessV3: Already referred");
        
        referredBy[msg.sender] = referrer;
        referrals[referrer].referralCount++;
        
        emit ReferralUsed(msg.sender, referrer);
    }

    function recordReferralReward(address referred, uint256 amount) external onlyAuthorized {
        address referrer = referredBy[referred];
        if (referrer != address(0)) {
            uint256 reward = (amount * referralRewardPercent) / 100;
            referrals[referrer].rewardsEarned += reward;
            emit ReferralRewardEarned(referrer, reward);
        }
    }

    // ============ MINT CONTROL ============

    function canMint(address account) external view returns (bool, string memory) {
        if (paused) return (false, "Minting paused");
        
        Tier tier = walletTiers[account];
        
        // Check if any window is open for this tier or lower
        bool windowOpen = false;
        if (tier >= Tier.VIP && isWindowOpen(Tier.VIP)) windowOpen = true;
        else if (tier >= Tier.EARLY && isWindowOpen(Tier.EARLY)) windowOpen = true;
        else if (isWindowOpen(Tier.PUBLIC)) windowOpen = true;
        
        if (!windowOpen) return (false, "Mint window closed");
        
        // Check limits
        uint256 limit = tierMintLimits[tier] > 0 ? tierMintLimits[tier] : maxMintsPerWallet;
        if (mintCounts[account] >= limit) return (false, "Wallet limit reached");
        
        return (true, "Can mint");
    }

    function recordMint(address wallet) external onlyAuthorized {
        mintCounts[wallet]++;
        emit MintRecorded(wallet, 1);
    }

    function recordMints(address wallet, uint256 count) external onlyAuthorized {
        mintCounts[wallet] += count;
        emit MintRecorded(wallet, count);
    }

    // ============ QUERIES ============

    function remainingMints(address wallet) external view returns (uint256) {
        Tier tier = walletTiers[wallet];
        uint256 limit = tierMintLimits[tier] > 0 ? tierMintLimits[tier] : maxMintsPerWallet;
        
        if (mintCounts[wallet] >= limit) return 0;
        return limit - mintCounts[wallet];
    }

    function getWalletInfo(address wallet) external view returns (
        Tier tier,
        uint256 minted,
        uint256 remaining,
        address referrer,
        uint256 referralCount
    ) {
        tier = walletTiers[wallet];
        minted = mintCounts[wallet];
        uint256 limit = tierMintLimits[tier] > 0 ? tierMintLimits[tier] : maxMintsPerWallet;
        remaining = minted >= limit ? 0 : limit - minted;
        referrer = referredBy[wallet];
        referralCount = referrals[wallet].referralCount;
    }

    // ============ ADMIN ============

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function setMaxMintsPerWallet(uint256 limit) external onlyOwner {
        maxMintsPerWallet = limit;
    }

    function setReferralRewardPercent(uint256 percent) external onlyOwner {
        require(percent <= 50, "NFTAccessV3: Max 50%");
        referralRewardPercent = percent;
    }

    function authorizeCaller(address caller, bool status) external onlyOwner {
        authorizedCallers[caller] = status;
        emit CallerAuthorized(caller, status);
    }

    // ============ CONVENIENCE (for backward compat) ============

    function publicMintOpen() external view returns (bool) {
        return isWindowOpen(Tier.PUBLIC);
    }

    function whitelistEnabled() external view returns (bool) {
        return isWindowOpen(Tier.EARLY) || isWindowOpen(Tier.VIP);
    }

    function setPublicMintOpen(bool open) external onlyOwner {
        if (open) {
            mintWindows[Tier.PUBLIC] = MintWindow(0, type(uint256).max, true);
        } else {
            mintWindows[Tier.PUBLIC].active = false;
        }
    }
}
