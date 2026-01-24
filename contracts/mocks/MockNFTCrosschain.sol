// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTCrosschain.sol";
import "../NFTCore.sol";

contract MockNFTCrosschain is NFTCore, NFTCrosschain {
    constructor() NFTCore("MockCrosschain", "MCX") {
        authorizedMinters[address(this)] = true;
        _setBridgeOperator(msg.sender);
    }

    function setBridgeOperator(address operator) external onlyOwner {
        _setBridgeOperator(operator);
    }

    function setSupportedChain(uint256 chainId, bool supported) external onlyOwner {
        _setSupportedChain(chainId, supported);
    }

    function mintToken(address to, string memory uri) external onlyOwner returns (uint256) {
        return this.mint(to, uri);
    }

    function createBridgeRequest(uint256 tokenId, uint256 destinationChainId) external returns (bytes32) {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        return _createBridgeRequest(tokenId, msg.sender, destinationChainId);
    }

    function processBridgeRequest(bytes32 requestId, bool success) external {
        _processBridgeRequest(requestId, success);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_ownerOf(tokenId) != address(0)) {
            require(!isTokenLocked(tokenId), "Token locked for bridging");
        }
        return super._update(to, tokenId, auth);
    }
}
