// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTProvenance.sol";
import "../NFTCore.sol";

contract MockNFTProvenance is NFTCore, NFTProvenance {
    constructor() NFTCore("MockProvenance", "MPROV") {
        authorizedMinters[address(this)] = true;
    }

    function mintWithProvenance(address to, string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = this.mint(to, uri);
        _recordMint(tokenId, to);
        return tokenId;
    }

    function recordTransfer(uint256 tokenId, address from, address to) external onlyOwner {
        _recordTransfer(tokenId, from, to);
    }

    function recordSale(uint256 tokenId, address from, address to, uint256 price) external onlyOwner {
        _recordSale(tokenId, from, to, price);
    }
}
