// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTTrait
 * @dev Extension for on-chain trait management (like loot-style traits)
 */
abstract contract NFTTrait {
    
    struct Trait {
        string name;
        string value;
        uint256 rarity; // 1-100
    }
    
    // tokenId => traitIndex => Trait
    mapping(uint256 => mapping(uint256 => Trait)) private _tokenTraits;
    mapping(uint256 => uint256) private _traitCounts;
    
    string[] private _availableTraitNames;
    mapping(string => string[]) private _availableTraitValues;
    
    event TraitSet(uint256 indexed tokenId, uint256 indexed traitIndex, string name, string value);
    event TraitRemoved(uint256 indexed tokenId, uint256 indexed traitIndex);
    event TraitTemplateAdded(string name, string[] values);
    
    /**
     * @dev Add a trait template (available trait category)
     */
    function _addTraitTemplate(string memory name, string[] memory values) internal {
        _availableTraitNames.push(name);
        for (uint256 i = 0; i < values.length; i++) {
            _availableTraitValues[name].push(values[i]);
        }
        emit TraitTemplateAdded(name, values);
    }
    
    /**
     * @dev Set a trait on a token
     */
    function _setTrait(
        uint256 tokenId,
        uint256 traitIndex,
        string memory name,
        string memory value,
        uint256 rarity
    ) internal {
        require(rarity >= 1 && rarity <= 100, "Invalid rarity");
        
        _tokenTraits[tokenId][traitIndex] = Trait({
            name: name,
            value: value,
            rarity: rarity
        });
        
        if (traitIndex >= _traitCounts[tokenId]) {
            _traitCounts[tokenId] = traitIndex + 1;
        }
        
        emit TraitSet(tokenId, traitIndex, name, value);
    }
    
    /**
     * @dev Remove a trait from a token
     */
    function _removeTrait(uint256 tokenId, uint256 traitIndex) internal {
        delete _tokenTraits[tokenId][traitIndex];
        emit TraitRemoved(tokenId, traitIndex);
    }
    
    /**
     * @dev Get a trait for a token
     */
    function getTrait(uint256 tokenId, uint256 traitIndex) public view returns (
        string memory name,
        string memory value,
        uint256 rarity
    ) {
        Trait memory trait = _tokenTraits[tokenId][traitIndex];
        return (trait.name, trait.value, trait.rarity);
    }
    
    /**
     * @dev Get all traits for a token
     */
    function getAllTraits(uint256 tokenId) public view returns (Trait[] memory) {
        uint256 count = _traitCounts[tokenId];
        Trait[] memory traits = new Trait[](count);
        
        for (uint256 i = 0; i < count; i++) {
            traits[i] = _tokenTraits[tokenId][i];
        }
        
        return traits;
    }
    
    /**
     * @dev Get trait count for a token
     */
    function getTraitCount(uint256 tokenId) public view returns (uint256) {
        return _traitCounts[tokenId];
    }
    
    /**
     * @dev Calculate overall rarity score
     */
    function calculateRarityScore(uint256 tokenId) public view returns (uint256) {
        uint256 count = _traitCounts[tokenId];
        if (count == 0) return 0;
        
        uint256 totalRarity = 0;
        for (uint256 i = 0; i < count; i++) {
            totalRarity += _tokenTraits[tokenId][i].rarity;
        }
        
        return totalRarity / count;
    }
    
    /**
     * @dev Get available trait names
     */
    function getAvailableTraitNames() public view returns (string[] memory) {
        return _availableTraitNames;
    }
    
    /**
     * @dev Get available values for a trait
     */
    function getAvailableTraitValues(string memory name) public view returns (string[] memory) {
        return _availableTraitValues[name];
    }
}
