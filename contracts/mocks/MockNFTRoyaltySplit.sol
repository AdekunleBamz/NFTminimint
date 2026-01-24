// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTRoyaltySplit.sol";

/**
 * @title MockNFTRoyaltySplit
 * @dev Mock contract for testing NFTRoyaltySplit extension
 */
contract MockNFTRoyaltySplit is NFTRoyaltySplit {
    
    function addRecipient(address recipient, uint256 share) external {
        _addRoyaltyRecipient(recipient, share);
    }
    
    function setSplit(address[] memory recipients, uint256[] memory shares) external {
        _setRoyaltySplit(recipients, shares);
    }
    
    function calculate(uint256 totalRoyalty) external view returns (address[] memory, uint256[] memory) {
        return _calculateRoyaltySplit(totalRoyalty);
    }
}
