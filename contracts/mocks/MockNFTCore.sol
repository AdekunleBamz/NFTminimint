// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title MockNFTCore
 * @dev Mock contract for testing NFTminimint integration
 */
contract MockNFTCore is IERC721 {
    
    string public name;
    string public symbol;
    
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;
    
    uint256 private _currentTokenId;
    address private _authorizedMinter;
    
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }
    
    function authorizeMinter(address minter) external {
        _authorizedMinter = minter;
    }
    
    function mintTo(address to, string memory tokenURI) external returns (uint256) {
        require(msg.sender == _authorizedMinter, "Not authorized");
        
        uint256 tokenId = ++_currentTokenId;
        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = tokenURI;
        
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }
    
    function totalSupply() external view returns (uint256) {
        return _currentTokenId;
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenURIs[tokenId];
    }
    
    function balanceOf(address owner) external view override returns (uint256) {
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) external view override returns (address) {
        return _owners[tokenId];
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory) external override {
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        _transfer(from, to, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external override {
        _transfer(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) external override {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function getApproved(uint256 tokenId) external view override returns (address) {
        return _tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "Not owner");
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        
        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }
}
