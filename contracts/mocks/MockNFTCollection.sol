// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title MockNFTCollection
 * @dev Mock contract for testing collection and royalty integration
 */
contract MockNFTCollection is IERC2981 {
    
    uint256 private _maxSupply;
    uint256 private _currentSupply;
    
    address private _royaltyReceiver;
    uint96 private _royaltyBps;
    
    mapping(uint256 => address) private _tokenRoyaltyReceiver;
    mapping(uint256 => uint96) private _tokenRoyaltyBps;
    mapping(address => bool) private _authorizedCallers;
    
    event MaxSupplyUpdated(uint256 oldSupply, uint256 newSupply);
    event DefaultRoyaltySet(address receiver, uint96 bps);
    event TokenRoyaltySet(uint256 indexed tokenId, address receiver, uint96 bps);
    
    constructor(uint256 maxSupply_) {
        _maxSupply = maxSupply_;
    }
    
    function authorizeCaller(address caller) external {
        _authorizedCallers[caller] = true;
    }
    
    function incrementSupply(uint256 quantity) external {
        require(_authorizedCallers[msg.sender], "Not authorized");
        require(_currentSupply + quantity <= _maxSupply, "Exceeds max supply");
        _currentSupply += quantity;
    }
    
    function setMaxSupply(uint256 newMaxSupply) external {
        require(newMaxSupply >= _currentSupply, "Below current supply");
        uint256 oldSupply = _maxSupply;
        _maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(oldSupply, newMaxSupply);
    }
    
    function setDefaultRoyalty(address receiver, uint96 bps) external {
        require(bps <= 1000, "Royalty too high");
        _royaltyReceiver = receiver;
        _royaltyBps = bps;
        emit DefaultRoyaltySet(receiver, bps);
    }
    
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 bps) external {
        require(bps <= 1000, "Royalty too high");
        _tokenRoyaltyReceiver[tokenId] = receiver;
        _tokenRoyaltyBps[tokenId] = bps;
        emit TokenRoyaltySet(tokenId, receiver, bps);
    }
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        address receiver = _tokenRoyaltyReceiver[tokenId];
        uint96 bps = _tokenRoyaltyBps[tokenId];
        
        if (receiver == address(0)) {
            receiver = _royaltyReceiver;
            bps = _royaltyBps;
        }
        
        uint256 royaltyAmount = (salePrice * bps) / 10000;
        return (receiver, royaltyAmount);
    }
    
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }
    
    function currentSupply() external view returns (uint256) {
        return _currentSupply;
    }
    
    function remainingSupply() external view returns (uint256) {
        return _maxSupply - _currentSupply;
    }
    
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
