// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTMintCooldown.sol";

/**
 * @title MockNFTMintCooldown
 * @dev Mock contract to test NFTMintCooldown extension
 */
contract MockNFTMintCooldown is NFTMintCooldown {
    uint256 public totalMinted;

    function setCooldown(uint256 cooldownSeconds) external {
        _setMintCooldown(cooldownSeconds);
    }

    function mint() external {
        _checkMintCooldown(msg.sender);
        totalMinted += 1;
        _recordMintCooldown(msg.sender);
    }
}
