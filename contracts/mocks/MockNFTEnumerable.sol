// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTEnumerable.sol";
import "../NFTCore.sol";

contract MockNFTEnumerable is NFTCore, NFTEnumerable {
    constructor() NFTCore("MockEnum", "MENUM") {}

    // Overrides required by Solidity

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function totalSupply() public view override(NFTCore, ERC721Enumerable) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    function tokenURI(uint256 tokenId) public view override(NFTCore, ERC721) returns (string memory) {
        return NFTCore.tokenURI(tokenId);
    }

    function _baseURI() internal view override(NFTCore, ERC721) returns (string memory) {
        return NFTCore._baseURI();
    }

    function supportsInterface(bytes4 interfaceId) public view override(NFTCore, ERC721Enumerable) returns (bool) {

        return super.supportsInterface(interfaceId);
    }
}
