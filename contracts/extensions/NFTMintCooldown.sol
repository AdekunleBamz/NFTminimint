// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMintCooldown
 * @dev Enforces a minimum time between mints per wallet.
 */
abstract contract NFTMintCooldown {
    uint256 private _mintCooldownSeconds;
    mapping(address => uint256) private _lastMintAt;

    event MintCooldownUpdated(uint256 oldCooldownSeconds, uint256 newCooldownSeconds);
    event MintCooldownRecorded(address indexed account, uint256 timestamp);

    function _setMintCooldown(uint256 cooldownSeconds) internal {
        uint256 old = _mintCooldownSeconds;
        _mintCooldownSeconds = cooldownSeconds;
        emit MintCooldownUpdated(old, cooldownSeconds);
    }

    function _checkMintCooldown(address account) internal view {
        uint256 cooldown = _mintCooldownSeconds;
        if (cooldown == 0) return;
        uint256 lastAt = _lastMintAt[account];
        require(block.timestamp >= lastAt + cooldown, "Mint cooldown active");
    }

    function _recordMintCooldown(address account) internal {
        _lastMintAt[account] = block.timestamp;
        emit MintCooldownRecorded(account, block.timestamp);
    }

    function getMintCooldown() public view returns (uint256) {
        return _mintCooldownSeconds;
    }

    function lastMintAt(address account) public view returns (uint256) {
        return _lastMintAt[account];
    }
}
