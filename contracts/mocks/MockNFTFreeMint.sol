// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTFreeMint.sol";
import "../NFTCore.sol";

contract MockNFTFreeMint is NFTCore, NFTFreeMint {
    constructor() NFTCore("MockNFT", "MNFT") {}

    function setFreeMintAccess(address account, bool allowed) external onlyOwner {
        _setFreeMintAccess(account, allowed);
    }

    function setFreeMintEnabled(bool enabled) external onlyOwner {
        _setFreeMintEnabled(enabled);
    }

    function freeMint(uint256 quantity) external {
        _checkFreeMintEligibility(msg.sender, quantity);
        _recordFreeMint(msg.sender, quantity);
        _mint(msg.sender, quantity);
    }
}
