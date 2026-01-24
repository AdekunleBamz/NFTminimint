// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTRandomMint.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockNFTRandomMint is ERC721, NFTRandomMint, Ownable {
    constructor() ERC721("MockRandom", "MRND") Ownable(msg.sender) {}

    function initializeRandomMint(uint256 maxSupply) external onlyOwner {
        _initializeRandomMint(maxSupply);
    }

    function randomMint(address to, uint256 nonce) external onlyOwner returns (uint256) {
        uint256 tokenId = _getRandomTokenId(nonce);
        _safeMint(to, tokenId);
        return tokenId;
    }
}
