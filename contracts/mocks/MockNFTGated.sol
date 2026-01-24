// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../extensions/NFTGated.sol";

/**
 * @title MockNFTGated
 * @dev Mock contract for testing NFTGated extension
 */
contract MockNFTGated is ERC721, NFTGated {
    
    uint256 private _tokenIdCounter;
    
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}
    
    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    function createFeature(
        string memory name,
        uint256 minTokens,
        uint256 startTime,
        uint256 endTime
    ) external returns (bytes32) {
        return _createFeature(name, minTokens, startTime, endTime);
    }
    
    function setFeatureActive(bytes32 featureId, bool active) external {
        _setFeatureActive(featureId, active);
    }
    
    function access(bytes32 featureId) external {
        require(_canAccessFeature(featureId, balanceOf(msg.sender)), "Access denied");
        _recordAccess(featureId, msg.sender);
    }
}
