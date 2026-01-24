// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTMetadataFreeze.sol";

/**
 * @title MockNFTMetadataFreeze
 * @dev Mock contract to test NFTMetadataFreeze extension
 */
contract MockNFTMetadataFreeze is NFTMetadataFreeze {
    string private _baseURI;

    function setBaseURI(string memory newBaseURI) external {
        _requireMetadataNotFrozen();
        _baseURI = newBaseURI;
    }

    function freeze() external {
        _freezeMetadata();
    }

    function baseURI() external view returns (string memory) {
        return _baseURI;
    }
}
