// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTTransferAllowlist.sol";

/**
 * @title MockNFTTransferAllowlist
 * @dev Mock contract to test NFTTransferAllowlist extension
 */
contract MockNFTTransferAllowlist is ERC721, NFTTransferAllowlist {
    uint256 private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function setAllowlistEnabled(bool enabled) external {
        _setTransferAllowlistEnabled(enabled);
    }

    function setRecipientAllowed(address account, bool allowed) external {
        _setRecipientAllowed(account, allowed);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            _checkTransferRecipient(to);
        }
        return super._update(to, tokenId, auth);
    }
}
