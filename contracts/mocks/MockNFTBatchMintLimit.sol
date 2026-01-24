// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTBatchMintLimit.sol";

/**
 * @title MockNFTBatchMintLimit
 * @dev Mock contract to test NFTBatchMintLimit extension
 */
contract MockNFTBatchMintLimit is NFTBatchMintLimit {
    uint256 public totalMinted;

    function setMaxBatch(uint256 maxBatch) external {
        _setMaxBatchMint(maxBatch);
    }

    function batchMint(uint256 quantity) external {
        _checkBatchMint(quantity);
        totalMinted += quantity;
    }
}
