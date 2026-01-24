// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTTransferCooldown
 * @dev Extension that enforces a minimum time between transfers for the same token.
 *      Intended to be called from the ERC721 transfer hook in the inheriting contract.
 */
abstract contract NFTTransferCooldown {
    uint256 private _transferCooldownSeconds;
    mapping(uint256 => uint256) private _lastTransferAt;

    event TransferCooldownUpdated(uint256 oldCooldownSeconds, uint256 newCooldownSeconds);
    event TransferCooldownRecorded(uint256 indexed tokenId, uint256 timestamp);

    function _setTransferCooldown(uint256 cooldownSeconds) internal {
        uint256 old = _transferCooldownSeconds;
        _transferCooldownSeconds = cooldownSeconds;
        emit TransferCooldownUpdated(old, cooldownSeconds);
    }

    function _checkTransferCooldown(uint256 tokenId) internal view {
        uint256 cooldown = _transferCooldownSeconds;
        if (cooldown == 0) return;

        uint256 lastAt = _lastTransferAt[tokenId];
        require(block.timestamp >= lastAt + cooldown, "Cooldown active");
    }

    function _recordTransfer(uint256 tokenId) internal {
        _lastTransferAt[tokenId] = block.timestamp;
        emit TransferCooldownRecorded(tokenId, block.timestamp);
    }

    function getTransferCooldown() public view returns (uint256) {
        return _transferCooldownSeconds;
    }

    function lastTransferAt(uint256 tokenId) public view returns (uint256) {
        return _lastTransferAt[tokenId];
    }
}
