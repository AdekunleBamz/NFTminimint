// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTTransferCooldown.sol";

/**
 * @title MockNFTTransferCooldown
 * @dev Mock contract to test NFTTransferCooldown extension
 */
contract MockNFTTransferCooldown is ERC721, NFTTransferCooldown {
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setCooldown(uint256 cooldownSeconds) external {
        _setTransferCooldown(cooldownSeconds);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Only enforce on transfers (not mint/burn)
        if (from != address(0) && to != address(0)) {
            _checkTransferCooldown(tokenId);
        }

        address previousOwner = super._update(to, tokenId, auth);

        if (from != address(0) && to != address(0)) {
            _recordTransfer(tokenId);
        }

        return previousOwner;
    }
}
