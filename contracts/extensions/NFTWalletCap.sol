// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTWalletCap
 * @dev Extension to cap maximum tokens per wallet.
 */
abstract contract NFTWalletCap {
    uint256 private _maxPerWallet;

    event MaxPerWalletUpdated(uint256 oldMax, uint256 newMax);

    function _setMaxPerWallet(uint256 maxPerWallet) internal {
        uint256 old = _maxPerWallet;
        _maxPerWallet = maxPerWallet;
        emit MaxPerWalletUpdated(old, maxPerWallet);
    }

    function _checkWalletCap(uint256 currentBalance, uint256 mintQuantity) internal view {
        uint256 maxPerWallet = _maxPerWallet;
        if (maxPerWallet == 0) return;
        require(currentBalance + mintQuantity <= maxPerWallet, "Wallet cap exceeded");
    }

    function getMaxPerWallet() public view returns (uint256) {
        return _maxPerWallet;
    }
}
