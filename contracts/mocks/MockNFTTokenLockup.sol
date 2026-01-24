// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTTokenLockup.sol";

/**
 * @title MockNFTTokenLockup
 * @dev Mock contract to test NFTTokenLockup extension
 */
contract MockNFTTokenLockup is ERC721, NFTTokenLockup {
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function lockToken(uint256 tokenId, uint256 untilTimestamp) external {
        _lockToken(tokenId, untilTimestamp);
    }

    function unlockToken(uint256 tokenId) external {
        _unlockToken(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkTokenLockup(tokenId);
        }
        return super._update(to, tokenId, auth);
    }
}
