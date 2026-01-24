// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTRefundable
 * @dev Extension for refundable mints with time window
 */
abstract contract NFTRefundable {
    
    struct RefundInfo {
        uint256 price;
        uint256 deadline;
        bool refunded;
    }
    
    mapping(uint256 => RefundInfo) private _refunds;
    uint256 private _refundPeriod = 7 days;
    
    event RefundPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
    event RefundRecorded(uint256 indexed tokenId, uint256 price, uint256 deadline);
    event RefundClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    
    /**
     * @dev Set refund period duration
     */
    function _setRefundPeriod(uint256 period) internal {
        uint256 oldPeriod = _refundPeriod;
        _refundPeriod = period;
        emit RefundPeriodUpdated(oldPeriod, period);
    }
    
    /**
     * @dev Record refund info for a token
     */
    function _recordRefund(uint256 tokenId, uint256 price) internal {
        uint256 deadline = block.timestamp + _refundPeriod;
        _refunds[tokenId] = RefundInfo({
            price: price,
            deadline: deadline,
            refunded: false
        });
        emit RefundRecorded(tokenId, price, deadline);
    }
    
    /**
     * @dev Check if token is refundable
     */
    function isRefundable(uint256 tokenId) public view returns (bool) {
        RefundInfo memory info = _refunds[tokenId];
        return info.price > 0 && 
               !info.refunded && 
               block.timestamp <= info.deadline;
    }
    
    /**
     * @dev Get refund info for a token
     */
    function getRefundInfo(uint256 tokenId) public view returns (
        uint256 price,
        uint256 deadline,
        bool refunded
    ) {
        RefundInfo memory info = _refunds[tokenId];
        return (info.price, info.deadline, info.refunded);
    }
    
    /**
     * @dev Process refund (must be overridden to handle actual transfer)
     */
    function _processRefund(uint256 tokenId, address owner) internal returns (uint256) {
        require(isRefundable(tokenId), "Not refundable");
        
        RefundInfo storage info = _refunds[tokenId];
        uint256 amount = info.price;
        info.refunded = true;
        
        emit RefundClaimed(tokenId, owner, amount);
        return amount;
    }
    
    /**
     * @dev Get current refund period
     */
    function getRefundPeriod() public view returns (uint256) {
        return _refundPeriod;
    }
    
    /**
     * @dev Time remaining for refund
     */
    function refundTimeRemaining(uint256 tokenId) public view returns (uint256) {
        RefundInfo memory info = _refunds[tokenId];
        if (info.deadline <= block.timestamp) {
            return 0;
        }
        return info.deadline - block.timestamp;
    }
}
