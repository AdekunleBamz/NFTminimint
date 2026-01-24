// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTBlacklist
 * @dev Extension to block transfers or mints to specific addresses.
 */
abstract contract NFTBlacklist {
    mapping(address => bool) private _blacklisted;

    event BlacklistUpdated(address indexed account, bool blacklisted);

    function _setBlacklisted(address account, bool blacklisted) internal {
        _blacklisted[account] = blacklisted;
        emit BlacklistUpdated(account, blacklisted);
    }

    function _checkNotBlacklisted(address account) internal view {
        require(!_blacklisted[account], "Address blacklisted");
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }
}
