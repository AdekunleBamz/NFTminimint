// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTTokenLockup
 * @dev Extension to lock individual tokens until a specific timestamp.
 */
abstract contract NFTTokenLockup {
    mapping(uint256 => uint256) private _lockedUntil;

    event TokenLocked(uint256 indexed tokenId, uint256 untilTimestamp);
    event TokenUnlocked(uint256 indexed tokenId);

    function _lockToken(uint256 tokenId, uint256 untilTimestamp) internal {
        require(untilTimestamp > block.timestamp, "Invalid lock time");
        _lockedUntil[tokenId] = untilTimestamp;
        emit TokenLocked(tokenId, untilTimestamp);
    }

    function _unlockToken(uint256 tokenId) internal {
        _lockedUntil[tokenId] = 0;
        emit TokenUnlocked(tokenId);
    }

    function _checkTokenLockup(uint256 tokenId) internal view {
        uint256 untilTimestamp = _lockedUntil[tokenId];
        if (untilTimestamp == 0) return;
        require(block.timestamp >= untilTimestamp, "Token locked");
    }

    function lockedUntil(uint256 tokenId) public view returns (uint256) {
        return _lockedUntil[tokenId];
    }
}
