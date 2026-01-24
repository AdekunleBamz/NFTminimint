// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTSupplyBuffer
 * @dev Extension to enforce a reserved supply buffer (e.g., keep N tokens unminted).
 */
abstract contract NFTSupplyBuffer {
    uint256 private _supplyBuffer;

    event SupplyBufferUpdated(uint256 oldBuffer, uint256 newBuffer);

    function _setSupplyBuffer(uint256 buffer) internal {
        uint256 old = _supplyBuffer;
        _supplyBuffer = buffer;
        emit SupplyBufferUpdated(old, buffer);
    }

    function _checkSupplyBuffer(uint256 currentSupply, uint256 maxSupply, uint256 mintQuantity) internal view {
        if (_supplyBuffer == 0) return;
        require(currentSupply + mintQuantity <= maxSupply - _supplyBuffer, "Supply buffer active");
    }

    function getSupplyBuffer() public view returns (uint256) {
        return _supplyBuffer;
    }
}
