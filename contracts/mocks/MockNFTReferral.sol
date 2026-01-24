// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTReferral.sol";
import "../NFTCore.sol";

contract MockNFTReferral is NFTCore, NFTReferral {
    constructor() NFTCore("MockReferral", "MREF") {
        authorizedMinters[address(this)] = true;
    }

    function mintWithReferral(address to, string memory uri, address referrer) external onlyOwner {
        this.mint(to, uri);
        if (referrer != address(0) && referrer != to) {
            _recordReferral(referrer, to);
            _addReward(referrer, 10); // 10 points per referral
        }
    }
    
    function claimReward(uint256 amount) external {
        _claimReward(msg.sender, amount);
    }
}
