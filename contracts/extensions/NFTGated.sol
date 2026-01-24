// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTGated
 * @dev Extension for token-gated access and benefits
 */
abstract contract NFTGated {
    
    struct GatedFeature {
        string name;
        uint256 minTokens;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }
    
    mapping(bytes32 => GatedFeature) private _features;
    bytes32[] private _featureIds;
    
    event FeatureCreated(bytes32 indexed featureId, string name, uint256 minTokens);
    event FeatureStatusChanged(bytes32 indexed featureId, bool active);
    event FeatureAccessed(bytes32 indexed featureId, address indexed user);
    
    /**
     * @dev Create a gated feature
     */
    function _createFeature(
        string memory name,
        uint256 minTokens,
        uint256 startTime,
        uint256 endTime
    ) internal returns (bytes32) {
        bytes32 featureId = keccak256(abi.encodePacked(name, block.timestamp));
        
        _features[featureId] = GatedFeature({
            name: name,
            minTokens: minTokens,
            startTime: startTime,
            endTime: endTime,
            active: true
        });
        
        _featureIds.push(featureId);
        emit FeatureCreated(featureId, name, minTokens);
        
        return featureId;
    }
    
    /**
     * @dev Toggle feature status
     */
    function _setFeatureActive(bytes32 featureId, bool active) internal {
        _features[featureId].active = active;
        emit FeatureStatusChanged(featureId, active);
    }
    
    /**
     * @dev Check if user can access feature
     */
    function _canAccessFeature(
        bytes32 featureId,
        uint256 userTokenBalance
    ) internal view returns (bool) {
        GatedFeature memory feature = _features[featureId];
        
        if (!feature.active) return false;
        if (block.timestamp < feature.startTime) return false;
        if (feature.endTime > 0 && block.timestamp > feature.endTime) return false;
        if (userTokenBalance < feature.minTokens) return false;
        
        return true;
    }
    
    /**
     * @dev Record feature access
     */
    function _recordAccess(bytes32 featureId, address user) internal {
        emit FeatureAccessed(featureId, user);
    }
    
    /**
     * @dev Get feature details
     */
    function getFeature(bytes32 featureId) public view returns (
        string memory name,
        uint256 minTokens,
        uint256 startTime,
        uint256 endTime,
        bool active
    ) {
        GatedFeature memory feature = _features[featureId];
        return (feature.name, feature.minTokens, feature.startTime, feature.endTime, feature.active);
    }
    
    /**
     * @dev Get all feature IDs
     */
    function getFeatureIds() public view returns (bytes32[] memory) {
        return _featureIds;
    }
    
    /**
     * @dev Modifier for gated access
     */
    modifier gatedAccess(bytes32 featureId, uint256 balance) {
        require(_canAccessFeature(featureId, balance), "Access denied");
        _;
    }
}
