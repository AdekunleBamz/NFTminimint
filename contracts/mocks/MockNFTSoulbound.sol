// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTSoulbound.sol";

/**
 * @title MockNFTSoulbound
 * @dev Mock contract to test NFTSoulbound extension
 */
contract MockNFTSoulbound is ERC721, NFTSoulbound {
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setGlobalSoulbound(bool enabled) external {
        if (enabled) {
            _enableSoulbound();
        } else {
            _disableSoulbound();
        }
    }

    function setTokenSoulbound(uint256 tokenId, bool enabled) external {
        _setSoulbound(tokenId, enabled);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkSoulbound(tokenId);
        }
        return super._update(to, tokenId, auth);
    }
}
