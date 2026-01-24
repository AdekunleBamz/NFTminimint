// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTWalletCap.sol";

/**
 * @title MockNFTWalletCap
 * @dev Mock contract to test NFTWalletCap extension
 */
contract MockNFTWalletCap is NFTWalletCap {
    mapping(address => uint256) public balanceOf;

    function setMaxPerWallet(uint256 maxPerWallet) external {
        _setMaxPerWallet(maxPerWallet);
    }

    function mint(address to, uint256 quantity) external {
        _checkWalletCap(balanceOf[to], quantity);
        balanceOf[to] += quantity;
    }
}
