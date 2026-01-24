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
        if (tokenId != 0 && _ownerOf(tokenId) != address(0)) { // Existing token
            // If minting (from=0), _ownerOf(tokenId) is usually 0 before update?
            // Actually _update handles mint/burn/transfer.
            // If transfer: from != 0, so _ownerOf is correct.
            // If mint: from == 0.
            // We only care if it's already staked.
            // If minting, it can't be staked yet.
            // If burning (to=0), maybe allow?
            // Usually can't burn staked tokens without unstaking.
            
            require(!isStaked(tokenId), "Token is staked");
        }
        return super._update(to, tokenId, auth);
    }
}
