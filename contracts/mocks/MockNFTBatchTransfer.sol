// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTBatchTransfer.sol";

/**
 * @title MockNFTBatchTransfer
 * @dev Mock contract for testing NFTBatchTransfer extension
 */
contract MockNFTBatchTransfer is ERC721, NFTBatchTransfer {
    
    uint256 private _tokenIdCounter;
    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}
    
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    function batchTransferTo(address to, uint256[] calldata tokenIds) external {
        _batchTransferTo(msg.sender, to, tokenIds);
    }
    
    function batchTransferToMany(address[] calldata recipients, uint256[] calldata tokenIds) external {
        _batchTransferToMany(msg.sender, recipients, tokenIds);
    }
    
    function _transferToken(address from, address to, uint256 tokenId) internal override {
        _transfer(from, to, tokenId);
    }
}
