// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTBlacklist.sol";

/**
 * @title MockNFTBlacklist
 * @dev Mock contract to test NFTBlacklist extension
 */
contract MockNFTBlacklist is ERC721, NFTBlacklist {
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256) {
        _checkNotBlacklisted(to);
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setBlacklisted(address account, bool blacklisted) external {
        _setBlacklisted(account, blacklisted);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkNotBlacklisted(to);
        }
        return super._update(to, tokenId, auth);
    }
}
