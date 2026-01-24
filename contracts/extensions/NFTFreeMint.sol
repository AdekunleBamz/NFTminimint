// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract NFTFreeMint is Ownable {
    mapping(address => uint256) private _freeMintsClaimed;
    mapping(address => bool) private _freeMintAllowlist;
    uint256 public constant MAX_FREE_MINTS = 1;
    bool public freeMintEnabled;

    event FreeMintClaimed(address indexed to, uint256 amount);
    event FreeMintAccessSet(address indexed account, bool allowed);

    function _setFreeMintAccess(address account, bool allowed) internal {
        _freeMintAllowlist[account] = allowed;
        emit FreeMintAccessSet(account, allowed);
    }

    function _setFreeMintEnabled(bool enabled) internal {
        freeMintEnabled = enabled;
    }

    function _checkFreeMintEligibility(address account, uint256 amount) internal view {
        require(freeMintEnabled, "Free minting disabled");
        require(_freeMintAllowlist[account], "Not eligible for free mint");
        require(_freeMintsClaimed[account] + amount <= MAX_FREE_MINTS, "Free mint limit exceeded");
    }

    function _recordFreeMint(address account, uint256 amount) internal {
        _freeMintsClaimed[account] += amount;
        emit FreeMintClaimed(account, amount);
    }
}
