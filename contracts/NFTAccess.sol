// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTMetadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title NFTAccess
 * @dev Role-based access control and security features
 * @author Adekunle Bamz
 * @notice Manages roles, whitelist, mint limits, and pausability
 */
abstract contract NFTAccess is NFTMetadata, AccessControl, Pausable {
    
    /// @dev Role for administrators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /// @dev Role for minters (can mint without whitelist)
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @dev Role for pausers (can pause/unpause)
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    /// @dev Whitelist mapping
    mapping(address => bool) internal _whitelist;
    
    /// @dev Number of whitelisted addresses
    uint256 public whitelistCount;
    
    /// @dev Whether whitelist is enabled
    bool public whitelistEnabled;
    
    /// @dev Maximum mints per wallet (0 = unlimited)
    uint256 public maxMintsPerWallet;
    
    /// @dev Mapping of mints per wallet
    mapping(address => uint256) internal _mintsPerWallet;
    
    /// @dev Whether public minting is open
    bool public publicMintOpen;

    /**
     * @dev Emitted when address is added to whitelist
     * @param account The whitelisted address
     */
    event AddedToWhitelist(address indexed account);

    /**
     * @dev Emitted when address is removed from whitelist
     * @param account The removed address
     */
    event RemovedFromWhitelist(address indexed account);

    /**
     * @dev Emitted when whitelist is enabled/disabled
     * @param enabled New whitelist status
     */
    event WhitelistStatusChanged(bool enabled);

    /**
     * @dev Emitted when max mints per wallet changes
     * @param oldLimit Previous limit
     * @param newLimit New limit
     */
    event MaxMintsPerWalletChanged(uint256 oldLimit, uint256 newLimit);

    /**
     * @dev Emitted when public mint status changes
     * @param open Whether public mint is open
     */
    event PublicMintStatusChanged(bool open);

    /**
     * @dev Modifier to check if address can mint
     */
    modifier canMint(address to) {
        require(!paused(), "NFTAccess: Minting is paused");
        
        // Check if caller has minter role (bypass whitelist)
        if (!hasRole(MINTER_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)) {
            // If whitelist is enabled, check whitelist
            if (whitelistEnabled) {
                require(_whitelist[to], "NFTAccess: Address not whitelisted");
            } else {
                // If whitelist disabled, require public mint to be open
                require(publicMintOpen, "NFTAccess: Public minting not open");
            }
        }
        
        // Check mint limit per wallet
        if (maxMintsPerWallet > 0) {
            require(_mintsPerWallet[to] < maxMintsPerWallet, "NFTAccess: Wallet mint limit reached");
        }
        _;
    }

    /**
     * @notice Check if an address is whitelisted
     * @param account Address to check
     * @return True if whitelisted
     */
    function isWhitelisted(address account) public view virtual returns (bool) {
        return _whitelist[account];
    }

    /**
     * @notice Get number of mints by a wallet
     * @param wallet Address to check
     * @return Number of mints
     */
    function mintsOf(address wallet) public view virtual returns (uint256) {
        return _mintsPerWallet[wallet];
    }

    /**
     * @notice Get remaining mints for a wallet
     * @param wallet Address to check
     * @return Remaining mints (type(uint256).max if unlimited)
     */
    function remainingMints(address wallet) public view virtual returns (uint256) {
        if (maxMintsPerWallet == 0) {
            return type(uint256).max;
        }
        uint256 minted = _mintsPerWallet[wallet];
        if (minted >= maxMintsPerWallet) {
            return 0;
        }
        return maxMintsPerWallet - minted;
    }

    /**
     * @dev Internal function to add address to whitelist
     * @param account Address to whitelist
     */
    function _addToWhitelist(address account) internal virtual {
        require(account != address(0), "NFTAccess: Cannot whitelist zero address");
        if (!_whitelist[account]) {
            _whitelist[account] = true;
            whitelistCount++;
            emit AddedToWhitelist(account);
        }
    }

    /**
     * @dev Internal function to remove address from whitelist
     * @param account Address to remove
     */
    function _removeFromWhitelist(address account) internal virtual {
        if (_whitelist[account]) {
            _whitelist[account] = false;
            whitelistCount--;
            emit RemovedFromWhitelist(account);
        }
    }

    /**
     * @dev Internal function to batch add to whitelist
     * @param accounts Array of addresses to whitelist
     */
    function _batchAddToWhitelist(address[] memory accounts) internal virtual {
        for (uint256 i = 0; i < accounts.length; i++) {
            _addToWhitelist(accounts[i]);
        }
    }

    /**
     * @dev Internal function to batch remove from whitelist
     * @param accounts Array of addresses to remove
     */
    function _batchRemoveFromWhitelist(address[] memory accounts) internal virtual {
        for (uint256 i = 0; i < accounts.length; i++) {
            _removeFromWhitelist(accounts[i]);
        }
    }

    /**
     * @dev Internal function to set whitelist status
     * @param enabled Whether whitelist should be enabled
     */
    function _setWhitelistEnabled(bool enabled) internal virtual {
        whitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
    }

    /**
     * @dev Internal function to set max mints per wallet
     * @param limit New mint limit (0 = unlimited)
     */
    function _setMaxMintsPerWallet(uint256 limit) internal virtual {
        uint256 oldLimit = maxMintsPerWallet;
        maxMintsPerWallet = limit;
        emit MaxMintsPerWalletChanged(oldLimit, limit);
    }

    /**
     * @dev Internal function to set public mint status
     * @param open Whether public minting is open
     */
    function _setPublicMintOpen(bool open) internal virtual {
        publicMintOpen = open;
        emit PublicMintStatusChanged(open);
    }

    /**
     * @dev Internal function to increment wallet mint count
     * @param wallet Address that minted
     */
    function _incrementMintCount(address wallet) internal virtual {
        _mintsPerWallet[wallet]++;
    }

    /**
     * @dev Internal function to increment mint count by amount
     * @param wallet Address that minted
     * @param amount Number of mints
     */
    function _incrementMintCountBy(address wallet, uint256 amount) internal virtual {
        _mintsPerWallet[wallet] += amount;
    }

    // ============ Required Overrides ============

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(NFTCore, AccessControl) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
