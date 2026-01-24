// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockNFTMetadata
 * @dev Mock contract for testing metadata integration
 */
contract MockNFTMetadata {
    
    string private _contractURI;
    mapping(address => bool) private _authorizedCallers;
    mapping(uint256 => mapping(string => string)) private _attributes;
    mapping(uint256 => bool) private _frozen;
    mapping(uint256 => string[]) private _attributeKeys;
    
    event ContractURIUpdated(string newURI);
    event AttributeSet(uint256 indexed tokenId, string key, string value);
    event MetadataFrozen(uint256 indexed tokenId);
    
    function authorizeCaller(address caller) external {
        _authorizedCallers[caller] = true;
    }
    
    function setContractURI(string memory uri) external {
        _contractURI = uri;
        emit ContractURIUpdated(uri);
    }
    
    function setAttribute(uint256 tokenId, string memory key, string memory value) external {
        require(_authorizedCallers[msg.sender], "Not authorized");
        require(!_frozen[tokenId], "Metadata frozen");
        
        if (bytes(_attributes[tokenId][key]).length == 0) {
            _attributeKeys[tokenId].push(key);
        }
        
        _attributes[tokenId][key] = value;
        emit AttributeSet(tokenId, key, value);
    }
    
    function getAttribute(uint256 tokenId, string memory key) external view returns (string memory) {
        return _attributes[tokenId][key];
    }
    
    function freezeMetadata(uint256 tokenId) external {
        require(_authorizedCallers[msg.sender], "Not authorized");
        _frozen[tokenId] = true;
        emit MetadataFrozen(tokenId);
    }
    
    function isMetadataFrozen(uint256 tokenId) external view returns (bool) {
        return _frozen[tokenId];
    }
    
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
    
    function getAttributeKeys(uint256 tokenId) external view returns (string[] memory) {
        return _attributeKeys[tokenId];
    }
    
    function getAllAttributes(uint256 tokenId) external view returns (
        string[] memory keys,
        string[] memory values
    ) {
        string[] memory attrKeys = _attributeKeys[tokenId];
        string[] memory attrValues = new string[](attrKeys.length);
        
        for (uint256 i = 0; i < attrKeys.length; i++) {
            attrValues[i] = _attributes[tokenId][attrKeys[i]];
        }
        
        return (attrKeys, attrValues);
    }
}
