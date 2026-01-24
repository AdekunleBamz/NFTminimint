// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTConstants
 * @dev Constant definitions for NFTminimint ecosystem
 * @author Adekunle Bamz
 * @notice Gas-efficient constants library
 */
library NFTConstants {
    /// @dev Maximum batch mint size
    uint256 constant MAX_BATCH_SIZE = 50;
    
    /// @dev Maximum royalty basis points (10%)
    uint96 constant MAX_ROYALTY_BPS = 1000;
    
    /// @dev Basis points denominator
    uint256 constant BASIS_POINTS = 10000;
    
    /// @dev Default max supply (unlimited)
    uint256 constant UNLIMITED_SUPPLY = type(uint256).max;
    
    /// @dev Maximum attribute key length
    uint256 constant MAX_ATTRIBUTE_KEY_LENGTH = 64;
    
    /// @dev Maximum attribute value length
    uint256 constant MAX_ATTRIBUTE_VALUE_LENGTH = 256;
    
    /// @dev Maximum URI length
    uint256 constant MAX_URI_LENGTH = 512;
    
    /// @dev Maximum whitelist batch size
    uint256 constant MAX_WHITELIST_BATCH = 100;
    
    /// @dev Maximum airdrop batch size
    uint256 constant MAX_AIRDROP_BATCH = 50;
}
