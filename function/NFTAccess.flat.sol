

// Sources flattened with hardhat v2.28.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/Pausable.sol@v5.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/NFTAccess.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;


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
