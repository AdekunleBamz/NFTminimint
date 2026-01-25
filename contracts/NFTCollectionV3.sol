// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NFTCollectionV3
 * @dev Dynamic royalties, revenue splitting, and collection management
 * @author Adekunle Bamz
 * @notice DEPLOY FOURTH - Collection management with V3 features
 * 
 * V3 NEW FEATURES:
 *   - Dynamic royalties (change % over time)
 *   - Revenue splitting (multiple recipients)
 *   - Per-token royalty overrides
 *   - Collection phases
 */
contract NFTCollectionV3 is Ownable, IERC2981 {
    
    string public constant VERSION = "3.0.0";
    
    /// @dev Revenue split recipient
    struct SplitRecipient {
        address wallet;
        uint256 sharePercent; // Basis points (100 = 1%)
    }
    
    /// @dev Royalty config
    struct RoyaltyConfig {
        address receiver;
        uint96 feePercent; // Basis points
    }

    /// @dev Collection stats
    uint256 public maxSupply = 10000;
    uint256 public totalMinted;
    
    /// @dev Authorized callers
    mapping(address => bool) public authorizedCallers;
    
    /// @dev Default royalty
    RoyaltyConfig public defaultRoyalty;
    
    /// @dev Per-token royalty overrides
    mapping(uint256 => RoyaltyConfig) public tokenRoyalties;
    mapping(uint256 => bool) public hasCustomRoyalty;
    
    /// @dev Revenue split recipients
    SplitRecipient[] public splitRecipients;
    
    /// @dev Dynamic royalty schedule: timestamp => new royalty percent
    mapping(uint256 => uint96) public royaltySchedule;
    uint256[] public royaltyScheduleTimes;
    
    /// @dev Collection phases
    enum Phase { PREMINT, WHITELIST, PUBLIC, REVEALED, COMPLETE }
    Phase public currentPhase;

    event SupplyIncremented(uint256 newTotal);
    event MaxSupplyUpdated(uint256 newMax);
    event RoyaltyUpdated(address receiver, uint96 feePercent);
    event TokenRoyaltySet(uint256 indexed tokenId, address receiver, uint96 feePercent);
    event RevenueSplitUpdated(uint256 recipientCount);
    event PhaseChanged(Phase newPhase);
    event RoyaltyScheduleSet(uint256 timestamp, uint96 feePercent);
    event CallerAuthorized(address indexed caller, bool status);

    error NotAuthorizedCaller();
    error ExceedsMaxSupply();
    error InvalidSplitTotal();

    constructor() Ownable(msg.sender) {
        defaultRoyalty = RoyaltyConfig(msg.sender, 500); // 5% default
    }

    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) revert NotAuthorizedCaller();
        _;
    }

    // ============ SUPPLY MANAGEMENT ============

    function incrementSupply() external onlyAuthorized {
        if (totalMinted >= maxSupply) revert ExceedsMaxSupply();
        totalMinted++;
        emit SupplyIncremented(totalMinted);
    }

    function incrementSupplyBy(uint256 amount) external onlyAuthorized {
        if (totalMinted + amount > maxSupply) revert ExceedsMaxSupply();
        totalMinted += amount;
        emit SupplyIncremented(totalMinted);
    }

    function setMaxSupply(uint256 newMax) external onlyOwner {
        require(newMax >= totalMinted, "NFTCollectionV3: Below minted");
        maxSupply = newMax;
        emit MaxSupplyUpdated(newMax);
    }

    function canMintQuantity(uint256 quantity) external view returns (bool) {
        return totalMinted + quantity <= maxSupply;
    }

    function isSoldOut() external view returns (bool) {
        return totalMinted >= maxSupply;
    }

    function getStats() external view returns (uint256, uint256, uint256) {
        return (totalMinted, maxSupply, maxSupply - totalMinted);
    }

    // ============ ROYALTIES (ERC-2981) ============

    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        override 
        returns (address, uint256) 
    {
        RoyaltyConfig memory config;
        
        if (hasCustomRoyalty[tokenId]) {
            config = tokenRoyalties[tokenId];
        } else {
            config = _getCurrentRoyalty();
        }
        
        uint256 royaltyAmount = (salePrice * config.feePercent) / 10000;
        return (config.receiver, royaltyAmount);
    }

    function _getCurrentRoyalty() internal view returns (RoyaltyConfig memory) {
        // Check dynamic schedule
        for (uint256 i = royaltyScheduleTimes.length; i > 0; i--) {
            uint256 scheduleTime = royaltyScheduleTimes[i - 1];
            if (block.timestamp >= scheduleTime) {
                return RoyaltyConfig(defaultRoyalty.receiver, royaltySchedule[scheduleTime]);
            }
        }
        return defaultRoyalty;
    }

    function setDefaultRoyalty(address receiver, uint96 feePercent) external onlyOwner {
        require(feePercent <= 2500, "NFTCollectionV3: Max 25%");
        defaultRoyalty = RoyaltyConfig(receiver, feePercent);
        emit RoyaltyUpdated(receiver, feePercent);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feePercent) external onlyOwner {
        require(feePercent <= 2500, "NFTCollectionV3: Max 25%");
        tokenRoyalties[tokenId] = RoyaltyConfig(receiver, feePercent);
        hasCustomRoyalty[tokenId] = true;
        emit TokenRoyaltySet(tokenId, receiver, feePercent);
    }

    function removeTokenRoyalty(uint256 tokenId) external onlyOwner {
        hasCustomRoyalty[tokenId] = false;
        delete tokenRoyalties[tokenId];
    }

    // ============ DYNAMIC ROYALTY SCHEDULE ============

    function scheduleRoyaltyChange(uint256 timestamp, uint96 feePercent) external onlyOwner {
        require(timestamp > block.timestamp, "NFTCollectionV3: Must be future");
        require(feePercent <= 2500, "NFTCollectionV3: Max 25%");
        
        royaltySchedule[timestamp] = feePercent;
        royaltyScheduleTimes.push(timestamp);
        emit RoyaltyScheduleSet(timestamp, feePercent);
    }

    function getCurrentRoyaltyPercent() external view returns (uint96) {
        return _getCurrentRoyalty().feePercent;
    }

    // ============ REVENUE SPLITTING ============

    function setRevenueSplit(address[] calldata wallets, uint256[] calldata shares) external onlyOwner {
        require(wallets.length == shares.length, "NFTCollectionV3: Length mismatch");
        
        // Clear existing
        delete splitRecipients;
        
        uint256 totalShares = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            require(wallets[i] != address(0), "NFTCollectionV3: Zero address");
            splitRecipients.push(SplitRecipient(wallets[i], shares[i]));
            totalShares += shares[i];
        }
        
        if (totalShares != 10000) revert InvalidSplitTotal(); // Must equal 100%
        
        emit RevenueSplitUpdated(wallets.length);
    }

    function getRevenueSplit() external view returns (SplitRecipient[] memory) {
        return splitRecipients;
    }

    function calculateSplit(uint256 amount) external view returns (
        address[] memory recipients,
        uint256[] memory amounts
    ) {
        recipients = new address[](splitRecipients.length);
        amounts = new uint256[](splitRecipients.length);
        
        for (uint256 i = 0; i < splitRecipients.length; i++) {
            recipients[i] = splitRecipients[i].wallet;
            amounts[i] = (amount * splitRecipients[i].sharePercent) / 10000;
        }
        
        return (recipients, amounts);
    }

    // ============ PHASES ============

    function setPhase(Phase phase) external onlyOwner {
        currentPhase = phase;
        emit PhaseChanged(phase);
    }

    function nextPhase() external onlyOwner {
        require(uint8(currentPhase) < uint8(Phase.COMPLETE), "NFTCollectionV3: Already complete");
        currentPhase = Phase(uint8(currentPhase) + 1);
        emit PhaseChanged(currentPhase);
    }

    // ============ ADMIN ============

    function authorizeCaller(address caller, bool status) external onlyOwner {
        authorizedCallers[caller] = status;
        emit CallerAuthorized(caller, status);
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
