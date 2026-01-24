// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTStaking.sol";
import "../NFTCore.sol";

contract MockNFTStaking is NFTCore, NFTStaking {
    constructor() NFTCore("MockStaking", "MSTAKE") {}

    function setStakingEnabled(bool enabled) external onlyOwner {
        _setStakingEnabled(enabled);
    }

    function stake(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _stake(tokenId, msg.sender); // Checks enabled and not already staked
    }

    function unstake(uint256 tokenId) external {
        require(stakes[tokenId].staker == msg.sender, "Not staker");
        _unstake(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        // Check if token exists (not minting) and is staked
        if (_ownerOf(tokenId) != address(0)) { 
            require(!isStaked(tokenId), "Token is staked");
        }
        return super._update(to, tokenId, auth);
    }
}
