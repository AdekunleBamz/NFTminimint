// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTBatchTransfer
 * @dev Extension for gas-efficient batch token transfers
 */
abstract contract NFTBatchTransfer {
    
    uint256 public constant MAX_BATCH_TRANSFER = 100;
    
    event BatchTransfer(address indexed from, address indexed to, uint256[] tokenIds);
    event BatchTransferToMany(address indexed from, address[] recipients, uint256[] tokenIds);
    
    /**
     * @dev Transfer multiple tokens to a single recipient
     */
    function _batchTransferTo(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) internal virtual {
        require(to != address(0), "Transfer to zero address");
        require(tokenIds.length > 0, "Empty token array");
        require(tokenIds.length <= MAX_BATCH_TRANSFER, "Exceeds batch limit");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _transferToken(from, to, tokenIds[i]);
        }
        
        emit BatchTransfer(from, to, tokenIds);
    }
    
    /**
     * @dev Transfer tokens to multiple recipients
     */
    function _batchTransferToMany(
        address from,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) internal virtual {
        require(recipients.length == tokenIds.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        require(recipients.length <= MAX_BATCH_TRANSFER, "Exceeds batch limit");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Transfer to zero address");
            _transferToken(from, recipients[i], tokenIds[i]);
        }
        
        emit BatchTransferToMany(from, recipients, tokenIds);
    }
    
    /**
     * @dev Internal transfer function - must be implemented by inheriting contract
     */
    function _transferToken(address from, address to, uint256 tokenId) internal virtual;
}
