// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMetadataFreeze
 * @dev Extension to permanently freeze metadata updates.
 */
abstract contract NFTMetadataFreeze {
    bool private _metadataFrozen;

    event MetadataFrozen(address indexed by);

    function _freezeMetadata() internal {
        require(!_metadataFrozen, "Metadata already frozen");
        _metadataFrozen = true;
        emit MetadataFrozen(msg.sender);
    }

    function _requireMetadataNotFrozen() internal view {
        require(!_metadataFrozen, "Metadata frozen");
    }

    function isMetadataFrozen() public view returns (bool) {
        return _metadataFrozen;
    }
}
