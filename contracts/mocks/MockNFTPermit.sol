// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTPermit.sol";

/**
 * @title MockNFTPermit
 * @dev Mock contract to test NFTPermit extension
 */
contract MockNFTPermit is ERC721, NFTPermit {
    
    uint256 private _tokenIdCounter;
    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _initPermit(name_);
    }
    
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    function _ownerOfPermit(uint256 tokenId) internal view override returns (address) {
        return _ownerOf(tokenId);
    }
    
    function _approvePermit(address spender, uint256 tokenId) internal override {
        _approve(spender, tokenId, _ownerOf(tokenId));
    }
}
