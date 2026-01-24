// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTRefundable.sol";

/**
 * @title MockNFTRefundable
 * @dev Mock contract for testing NFTRefundable extension
 */
contract MockNFTRefundable is NFTRefundable {
    
    function setRefundPeriod(uint256 period) external {
        _setRefundPeriod(period);
    }
    
    function record(uint256 tokenId, uint256 price) external {
        _recordRefund(tokenId, price);
    }
    
    function process(uint256 tokenId, address owner) external returns (uint256) {
        return _processRefund(tokenId, owner);
    }
}
