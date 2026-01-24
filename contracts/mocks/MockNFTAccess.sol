// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockNFTAccess
 * @dev Mock contract for testing access control integration
 */
contract MockNFTAccess {
    
    bool private _publicMintOpen;
    bool private _whitelistEnabled;
    bool private _paused;
    
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _mintedPerWallet;
    mapping(address => bool) private _authorizedCallers;
    
    uint256 private _walletMintLimit = 10;
    
    event WhitelistUpdated(address indexed account, bool status);
    event PublicMintStatusChanged(bool isOpen);
    event PauseStatusChanged(bool isPaused);
    
    function authorizeCaller(address caller) external {
        _authorizedCallers[caller] = true;
    }
    
    function setPublicMintOpen(bool isOpen) external {
        _publicMintOpen = isOpen;
        emit PublicMintStatusChanged(isOpen);
    }
    
    function setWhitelistEnabled(bool enabled) external {
        _whitelistEnabled = enabled;
    }
    
    function addToWhitelist(address account) external {
        _whitelist[account] = true;
        emit WhitelistUpdated(account, true);
    }
    
    function removeFromWhitelist(address account) external {
        _whitelist[account] = false;
        emit WhitelistUpdated(account, false);
    }
    
    function setWalletMintLimit(uint256 limit) external {
        _walletMintLimit = limit;
    }
    
    function recordMint(address minter, uint256 quantity) external {
        require(_authorizedCallers[msg.sender], "Not authorized");
        _mintedPerWallet[minter] += quantity;
    }
    
    function canMint(address minter, uint256 quantity) external view returns (bool) {
        if (_paused) return false;
        if (!_publicMintOpen && _whitelistEnabled && !_whitelist[minter]) return false;
        if (_mintedPerWallet[minter] + quantity > _walletMintLimit) return false;
        return true;
    }
    
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelist[account];
    }
    
    function mintedPerWallet(address wallet) external view returns (uint256) {
        return _mintedPerWallet[wallet];
    }
    
    function isPublicMintOpen() external view returns (bool) {
        return _publicMintOpen;
    }
    
    function isPaused() external view returns (bool) {
        return _paused;
    }
    
    function setPaused(bool paused) external {
        _paused = paused;
        emit PauseStatusChanged(paused);
    }
    
    function getWalletMintLimit() external view returns (uint256) {
        return _walletMintLimit;
    }
}
