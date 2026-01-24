// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMaxSupplyChange
 * @dev Extension to allow reducing the maximum supply (e.g., closing mint early).
 */
abstract contract NFTMaxSupplyChange {
    uint256 private _maxSupply;

    event MaxSupplyUpdated(uint256 oldMax, uint256 newMax);

    function _initMaxSupply(uint256 maxSupply_) internal {
        _maxSupply = maxSupply_;
    }

    function _reduceMaxSupply(uint256 newMax, uint256 totalSupply) internal {
        require(newMax < _maxSupply, "Can only reduce max supply");
        require(newMax >= totalSupply, "New max < total supply");
        uint256 old = _maxSupply;
        _maxSupply = newMax;
        emit MaxSupplyUpdated(old, newMax);
    }

    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }
}
