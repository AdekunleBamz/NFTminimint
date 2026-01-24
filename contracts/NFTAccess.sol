// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title NFTAccess
 * @dev Access control contract - DEPLOY THIRD
 * @author Adekunle Bamz
 * @notice Manages whitelist, mint limits, and pause functionality
 * 
 * DEPLOYMENT ORDER: 3rd
 * CONSTRUCTOR ARGS: 1
 *   - nftCore_ (address): Address of deployed NFTCore contract
 */

interface INFTCoreAccess {
    function totalSupply() external view returns (uint256);
}

contract NFTAccess is Ownable, Pausable {
    
    /// @dev Reference to NFTCore contract
    INFTCoreAccess public nftCore;
    
    /// @dev Whitelist mapping
    mapping(address => bool) public whitelist;
    
    /// @dev Whitelist count
    uint256 public whitelistCount;
    
    /// @dev Is whitelist enabled
    bool public whitelistEnabled;
    
    /// @dev Max mints per wallet (0 = unlimited)
    uint256 public maxMintsPerWallet;
    
    /// @dev Mints per wallet tracking
    mapping(address => uint256) public mintsPerWallet;
    
    /// @dev Is public minting open
    bool public publicMintOpen;
    
    /// @dev Admin addresses
    mapping(address => bool) public admins;
    
    /// @dev Authorized caller addresses (other contracts)
    mapping(address => bool) public authorizedCallers;

    /// @dev Emitted when added to whitelist
    event AddedToWhitelist(address indexed account);
    
    /// @dev Emitted when removed from whitelist
    event RemovedFromWhitelist(address indexed account);
    
    /// @dev Emitted when whitelist status changes
    event WhitelistStatusChanged(bool enabled);
    
    /// @dev Emitted when mint limit changes
    event MintLimitChanged(uint256 newLimit);
    
    /// @dev Emitted when public mint status changes
    event PublicMintStatusChanged(bool open);
    
    /// @dev Emitted when admin status changes
    event AdminUpdated(address indexed admin, bool status);
    
    /// @dev Emitted when authorized caller changes
    event AuthorizedCallerUpdated(address indexed caller, bool status);
    
    /// @dev Emitted when NFTCore reference updates
    event NFTCoreUpdated(address indexed newCore);
    
    /// @dev Emitted when mint is recorded
    event MintRecorded(address indexed wallet, uint256 count);

    /**
     * @dev Constructor
     * @param nftCore_ Address of NFTCore contract
     */
    constructor(address nftCore_) Ownable(msg.sender) {
        require(nftCore_ != address(0), "NFTAccess: Zero address");
        nftCore = INFTCoreAccess(nftCore_);
        admins[msg.sender] = true;
    }

    // ============ MODIFIERS ============

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "NFTAccess: Not admin");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            authorizedCallers[msg.sender] || admins[msg.sender] || msg.sender == owner(),
            "NFTAccess: Not authorized"
        );
        _;
    }

    // ============ ADMIN MANAGEMENT ============

    /**
     * @notice Add admin
     * @param admin Address to add
     */
    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "NFTAccess: Zero address");
        admins[admin] = true;
        emit AdminUpdated(admin, true);
    }

    /**
     * @notice Remove admin
     * @param admin Address to remove
     */
    function removeAdmin(address admin) external onlyOwner {
        admins[admin] = false;
        emit AdminUpdated(admin, false);
    }
    
    /**
     * @notice Authorize a caller (e.g., NFTminimint contract)
     * @param caller Address to authorize
     */
    function authorizeCaller(address caller) external onlyOwner {
        require(caller != address(0), "NFTAccess: Zero address");
        authorizedCallers[caller] = true;
        emit AuthorizedCallerUpdated(caller, true);
    }
    
    /**
     * @notice Revoke caller authorization
     * @param caller Address to revoke
     */
    function revokeCaller(address caller) external onlyOwner {
        authorizedCallers[caller] = false;
        emit AuthorizedCallerUpdated(caller, false);
    }

    /**
     * @notice Update NFTCore reference
     * @param newCore New NFTCore address
     */
    function setNFTCore(address newCore) external onlyOwner {
        require(newCore != address(0), "NFTAccess: Zero address");
        nftCore = INFTCoreAccess(newCore);
        emit NFTCoreUpdated(newCore);
    }

    // ============ WHITELIST MANAGEMENT ============

    /**
     * @notice Add address to whitelist
     * @param account Address to add
     */
    function addToWhitelist(address account) external onlyAdmin {
        require(account != address(0), "NFTAccess: Zero address");
        if (!whitelist[account]) {
            whitelist[account] = true;
            whitelistCount++;
            emit AddedToWhitelist(account);
        }
    }

    /**
     * @notice Batch add to whitelist
     * @param accounts Addresses to add
     */
    function batchAddToWhitelist(address[] calldata accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0) && !whitelist[accounts[i]]) {
                whitelist[accounts[i]] = true;
                whitelistCount++;
                emit AddedToWhitelist(accounts[i]);
            }
        }
    }

    /**
     * @notice Remove from whitelist
     * @param account Address to remove
     */
    function removeFromWhitelist(address account) external onlyAdmin {
        if (whitelist[account]) {
            whitelist[account] = false;
            whitelistCount--;
            emit RemovedFromWhitelist(account);
        }
    }

    /**
     * @notice Batch remove from whitelist
     * @param accounts Addresses to remove
     */
    function batchRemoveFromWhitelist(address[] calldata accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (whitelist[accounts[i]]) {
                whitelist[accounts[i]] = false;
                whitelistCount--;
                emit RemovedFromWhitelist(accounts[i]);
            }
        }
    }

    /**
     * @notice Enable/disable whitelist
     * @param enabled New status
     */
    function setWhitelistEnabled(bool enabled) external onlyAdmin {
        whitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
    }

    // ============ MINT LIMIT MANAGEMENT ============

    /**
     * @notice Set max mints per wallet
     * @param limit New limit (0 = unlimited)
     */
    function setMaxMintsPerWallet(uint256 limit) external onlyAdmin {
        maxMintsPerWallet = limit;
        emit MintLimitChanged(limit);
    }

    /**
     * @notice Open/close public minting
     * @param open New status
     */
    function setPublicMintOpen(bool open) external onlyAdmin {
        publicMintOpen = open;
        emit PublicMintStatusChanged(open);
    }

    // ============ PAUSE FUNCTIONS ============

    /**
     * @notice Pause minting
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpause minting
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    // ============ MINT TRACKING ============

    /**
     * @notice Record a mint for a wallet
     * @param wallet Wallet that minted
     */
    function recordMint(address wallet) external onlyAuthorized {
        mintsPerWallet[wallet]++;
        emit MintRecorded(wallet, 1);
    }

    /**
     * @notice Record multiple mints
     * @param wallet Wallet that minted
     * @param count Number of mints
     */
    function recordMints(address wallet, uint256 count) external onlyAuthorized {
        mintsPerWallet[wallet] += count;
        emit MintRecorded(wallet, count);
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @notice Check if address can mint
     * @param account Address to check
     * @return canMint_ Whether can mint
     * @return reason Reason if cannot
     */
    function canMint(address account) external view returns (bool canMint_, string memory reason) {
        if (paused()) {
            return (false, "Minting paused");
        }
        
        if (whitelistEnabled && !whitelist[account]) {
            return (false, "Not whitelisted");
        }
        
        if (!whitelistEnabled && !publicMintOpen) {
            return (false, "Public mint not open");
        }
        
        if (maxMintsPerWallet > 0 && mintsPerWallet[account] >= maxMintsPerWallet) {
            return (false, "Wallet limit reached");
        }
        
        return (true, "");
    }

    /**
     * @notice Get remaining mints for wallet
     * @param wallet Address to check
     */
    function remainingMints(address wallet) external view returns (uint256) {
        if (maxMintsPerWallet == 0) {
            return type(uint256).max;
        }
        if (mintsPerWallet[wallet] >= maxMintsPerWallet) {
            return 0;
        }
        return maxMintsPerWallet - mintsPerWallet[wallet];
    }

    /**
     * @notice Check if address is whitelisted
     * @param account Address to check
     */
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /**
     * @notice Check if address is admin
     * @param account Address to check
     */
    function isAdmin(address account) external view returns (bool) {
        return admins[account];
    }

    /**
     * @notice Get mint statistics for a wallet
     * @param wallet Address to check
     */
    function getMintStats(address wallet) external view returns (
        uint256 minted,
        uint256 remaining,
        uint256 limit
    ) {
        minted = mintsPerWallet[wallet];
        limit = maxMintsPerWallet;
        if (limit == 0) {
            remaining = type(uint256).max;
        } else {
            remaining = minted >= limit ? 0 : limit - minted;
        }
    }

    /**
     * @notice Set wallet mint limit (alias for setMaxMintsPerWallet)
     * @param limit New limit
     */
    function setWalletMintLimit(uint256 limit) external onlyAdmin {
        maxMintsPerWallet = limit;
        emit WalletMintLimitUpdated(limit);
    }
    
    /// @dev Emitted when wallet mint limit changes
    event WalletMintLimitUpdated(uint256 newLimit);

    /**
     * @notice Get wallet mint limit
     */
    function walletMintLimit() external view returns (uint256) {
        return maxMintsPerWallet;
    }

    /**
     * @notice Record mint for a wallet (alias for recordMint)
     * @param wallet Address that minted
     * @param count Number of mints
     */
    function recordMint(address wallet, uint256 count) external onlyAuthorized {
        mintsPerWallet[wallet] += count;
        emit MintRecorded(wallet, count);
    }

    /**
     * @notice Get minted count per wallet
     * @param wallet Address to check
     */
    function mintedPerWallet(address wallet) external view returns (uint256) {
        return mintsPerWallet[wallet];
    }

    /**
     * @notice Set admin status
     * @param admin Address to update
     * @param status New status
     */
    function setAdmin(address admin, bool status) external onlyOwner {
        require(admin != address(0), "NFTAccess: Zero address");
        admins[admin] = status;
        emit AdminUpdated(admin, status);
    }
}
