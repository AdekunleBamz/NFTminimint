// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTSoulbound
 * @dev Extension for non-transferable soulbound tokens
 */
abstract contract NFTSoulbound {
    
    bool private _soulbound;
    mapping(uint256 => bool) private _soulboundTokens;
    
    event SoulboundEnabled();
    event SoulboundDisabled();
    event TokenSoulbound(uint256 indexed tokenId);
    event TokenUnbound(uint256 indexed tokenId);
    
    /**
     * @dev Enable soulbound mode globally
     */
    function _enableSoulbound() internal {
        _soulbound = true;
        emit SoulboundEnabled();
    }
    
    /**
     * @dev Disable soulbound mode globally
     */
    function _disableSoulbound() internal {
        _soulbound = false;
        emit SoulboundDisabled();
    }
    
    /**
     * @dev Make a specific token soulbound
     */
    function _setSoulbound(uint256 tokenId, bool soulbound) internal {
        _soulboundTokens[tokenId] = soulbound;
        
        if (soulbound) {
            emit TokenSoulbound(tokenId);
        } else {
            emit TokenUnbound(tokenId);
        }
    }
    
    /**
     * @dev Check if a token is soulbound
     */
    function isSoulbound(uint256 tokenId) public view returns (bool) {
        return _soulbound || _soulboundTokens[tokenId];
    }
    
    /**
     * @dev Check if global soulbound mode is enabled
     */
    function isGlobalSoulbound() public view returns (bool) {
        return _soulbound;
    }
    
    /**
     * @dev Modifier to prevent transfer of soulbound tokens
     */
    modifier notSoulbound(uint256 tokenId) {
        require(!isSoulbound(tokenId), "Token is soulbound");
        _;
    }
    
    /**
     * @dev Hook to check soulbound status before transfer
     * Override in child contract
     */
    function _checkSoulbound(uint256 tokenId) internal view {
        require(!isSoulbound(tokenId), "Token is soulbound");
    }
}
