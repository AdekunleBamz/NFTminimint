// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTMaxSupplyChange.sol";

/**
 * @title MockNFTMaxSupplyChange
 * @dev Mock contract to test NFTMaxSupplyChange extension
 */
contract MockNFTMaxSupplyChange is NFTMaxSupplyChange {
    uint256 public totalSupply;

    constructor(uint256 maxSupply_) {
        _initMaxSupply(maxSupply_);
    }

    function reduceMaxSupply(uint256 newMax) external {
        _reduceMaxSupply(newMax, totalSupply);
    }

    function mint(uint256 quantity) external {
        require(totalSupply + quantity <= maxSupply(), "Exceeds max supply");
        totalSupply += quantity;
    }
}
