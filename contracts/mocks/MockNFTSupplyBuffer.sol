// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTSupplyBuffer.sol";

/**
 * @title MockNFTSupplyBuffer
 * @dev Mock contract to test NFTSupplyBuffer extension
 */
contract MockNFTSupplyBuffer is NFTSupplyBuffer {
    uint256 public totalSupply;
    uint256 public maxSupply;

    constructor(uint256 maxSupply_) {
        maxSupply = maxSupply_;
    }

    function setBuffer(uint256 buffer) external {
        _setSupplyBuffer(buffer);
    }

    function mint(uint256 quantity) external {
        _checkSupplyBuffer(totalSupply, maxSupply, quantity);
        totalSupply += quantity;
    }
}
