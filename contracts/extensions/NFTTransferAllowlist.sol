// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTTransferAllowlist
 * @dev Extension to restrict transfers to approved recipient addresses.
 */
abstract contract NFTTransferAllowlist {
    bool private _transferAllowlistEnabled;
    mapping(address => bool) private _allowedRecipients;

    event TransferAllowlistStatusChanged(bool enabled);
    event TransferRecipientAllowed(address indexed account, bool allowed);

    function _setTransferAllowlistEnabled(bool enabled) internal {
        _transferAllowlistEnabled = enabled;
        emit TransferAllowlistStatusChanged(enabled);
    }

    function _setRecipientAllowed(address account, bool allowed) internal {
        _allowedRecipients[account] = allowed;
        emit TransferRecipientAllowed(account, allowed);
    }

    function _checkTransferRecipient(address to) internal view {
        if (!_transferAllowlistEnabled) return;
        require(_allowedRecipients[to], "Recipient not allowed");
    }

    function isTransferAllowlistEnabled() public view returns (bool) {
        return _transferAllowlistEnabled;
    }

    function isRecipientAllowed(address account) public view returns (bool) {
        return _allowedRecipients[account];
    }
}
