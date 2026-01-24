// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTBatchMintLimit
 * @dev Extension to enforce a maximum batch mint size.
 */
abstract contract NFTBatchMintLimit {
    uint256 private _maxBatchMint;

    event MaxBatchMintUpdated(uint256 oldMax, uint256 newMax);

    function _setMaxBatchMint(uint256 maxBatchMint) internal {
        uint256 old = _maxBatchMint;
        _maxBatchMint = maxBatchMint;
        emit MaxBatchMintUpdated(old, maxBatchMint);
    }

    function _checkBatchMint(uint256 quantity) internal view {
        uint256 maxBatch = _maxBatchMint;
        if (maxBatch == 0) return;
        require(quantity <= maxBatch, "Batch limit exceeded");
    }

    function getMaxBatchMint() public view returns (uint256) {
        return _maxBatchMint;
    }
}
