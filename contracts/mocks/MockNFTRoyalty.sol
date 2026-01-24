// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTRoyalty.sol";
import "../NFTCore.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MockNFTRoyalty is NFTCore, NFTRoyalty {
    constructor() NFTCore("MockRoyalty", "MR") {}

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function mint(address to) external {
        _mint(to, 1);
    }

    function supportsInterface(bytes4 interfaceId) public view override(NFTCore, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
