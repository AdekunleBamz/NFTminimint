// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTDynamicPricing.sol";

/**
 * @title MockNFTDynamicPricing
 * @dev Mock contract for testing NFTDynamicPricing extension
 */
contract MockNFTDynamicPricing is NFTDynamicPricing {
    
    function setBasePrice(uint256 price) external {
        _setBasePrice(price);
    }
    
    function addTier(uint256 maxSupply, uint256 price) external {
        _addPriceTier(maxSupply, price);
    }
    
    function clearTiers() external {
        _clearPriceTiers();
    }
    
    function setEnabled(bool enabled) external {
        _setDynamicPricingEnabled(enabled);
    }
    
    function getPrice(uint256 currentSupply) external view returns (uint256) {
        return _getCurrentPrice(currentSupply);
    }
}
