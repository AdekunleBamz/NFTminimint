// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTRentable.sol";

/**
 * @title MockNFTRentable
 * @dev Mock contract for testing NFTRentable extension
 */
contract MockNFTRentable is ERC721, NFTRentable {
    
    uint256 private _tokenIdCounter;
    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}
    
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    function setUser(uint256 tokenId, address user, uint64 expires) external {
        _setUser(tokenId, user, expires);
    }
    
    function clearUser(uint256 tokenId) external {
        _clearUser(tokenId);
    }
}
