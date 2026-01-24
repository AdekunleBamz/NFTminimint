// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract NFTReferral {
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public referralRewards;
    
    event ReferralRecorded(address indexed referrer, address indexed referee);
    event ReferralRewardClaimed(address indexed referrer, uint256 amount);

    function _recordReferral(address referrer, address referee) internal {
        if (referrer != address(0) && referrer != referee) {
            referralCount[referrer]++;
            emit ReferralRecorded(referrer, referee);
        }
    }
    
    function _addReward(address referrer, uint256 amount) internal {
        if (referrer != address(0)) {
            referralRewards[referrer] += amount;
        }
    }
    
    function _claimReward(address referrer, uint256 amount) internal {
        require(referralRewards[referrer] >= amount, "Insufficient rewards");
        referralRewards[referrer] -= amount;
        emit ReferralRewardClaimed(referrer, amount);
    }
}
