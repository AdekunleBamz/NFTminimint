// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTDynamicPricing
 * @dev Extension for dynamic mint pricing based on supply
 */
abstract contract NFTDynamicPricing {
    
    struct PriceTier {
        uint256 maxSupply;
        uint256 price;
    }
    
    PriceTier[] private _priceTiers;
    bool private _dynamicPricingEnabled;
    uint256 private _basePrice;
    
    event PriceTierAdded(uint256 maxSupply, uint256 price);
    event PriceTiersCleared();
    event BasePriceUpdated(uint256 oldPrice, uint256 newPrice);
    event DynamicPricingToggled(bool enabled);
    
    /**
     * @dev Set base price (used when no tiers or disabled)
     */
    function _setBasePrice(uint256 price) internal {
        uint256 oldPrice = _basePrice;
        _basePrice = price;
        emit BasePriceUpdated(oldPrice, price);
    }
    
    /**
     * @dev Add a price tier
     */
    function _addPriceTier(uint256 maxSupply, uint256 price) internal {
        if (_priceTiers.length > 0) {
            require(
                maxSupply > _priceTiers[_priceTiers.length - 1].maxSupply,
                "Tier must be greater than previous"
            );
        }
        
        _priceTiers.push(PriceTier({
            maxSupply: maxSupply,
            price: price
        }));
        
        emit PriceTierAdded(maxSupply, price);
    }
    
    /**
     * @dev Clear all price tiers
     */
    function _clearPriceTiers() internal {
        delete _priceTiers;
        emit PriceTiersCleared();
    }
    
    /**
     * @dev Enable or disable dynamic pricing
     */
    function _setDynamicPricingEnabled(bool enabled) internal {
        _dynamicPricingEnabled = enabled;
        emit DynamicPricingToggled(enabled);
    }
    
    /**
     * @dev Get current price based on supply
     */
    function _getCurrentPrice(uint256 currentSupply) internal view returns (uint256) {
        if (!_dynamicPricingEnabled || _priceTiers.length == 0) {
            return _basePrice;
        }
        
        for (uint256 i = 0; i < _priceTiers.length; i++) {
            if (currentSupply < _priceTiers[i].maxSupply) {
                return _priceTiers[i].price;
            }
        }
        
        // Return last tier price if supply exceeds all tiers
        return _priceTiers[_priceTiers.length - 1].price;
    }
    
    /**
     * @dev Get price tier info
     */
    function getPriceTier(uint256 index) public view returns (uint256 maxSupply, uint256 price) {
        require(index < _priceTiers.length, "Invalid tier index");
        PriceTier memory tier = _priceTiers[index];
        return (tier.maxSupply, tier.price);
    }
    
    /**
     * @dev Get number of price tiers
     */
    function getPriceTierCount() public view returns (uint256) {
        return _priceTiers.length;
    }
    
    /**
     * @dev Check if dynamic pricing is enabled
     */
    function isDynamicPricingEnabled() public view returns (bool) {
        return _dynamicPricingEnabled;
    }
    
    /**
     * @dev Get base price
     */
    function getBasePrice() public view returns (uint256) {
        return _basePrice;
    }
}
