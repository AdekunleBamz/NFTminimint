// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTOperatorFilter
 * @dev Operator filtering for marketplace restrictions
 * @author Adekunle Bamz
 * @notice Block specific operators from transferring tokens
 */
abstract contract NFTOperatorFilter {
    
    /// @dev Blocked operators mapping
    mapping(address => bool) public blockedOperators;
    
    /// @dev Whether operator filtering is enabled
    bool public operatorFilterEnabled;
    
    /// @dev Emitted when operator is blocked
    event OperatorBlocked(address indexed operator);
    
    /// @dev Emitted when operator is unblocked
    event OperatorUnblocked(address indexed operator);
    
    /// @dev Emitted when filter status changes
    event OperatorFilterStatusChanged(bool enabled);
    
    /**
     * @notice Check if operator is allowed
     * @param operator Operator to check
     * @return bool True if allowed
     */
    function isOperatorAllowed(address operator) public view returns (bool) {
        if (!operatorFilterEnabled) {
            return true;
        }
        return !blockedOperators[operator];
    }
    
    /**
     * @dev Internal function to block operator
     */
    function _blockOperator(address operator) internal {
        require(operator != address(0), "Zero address");
        blockedOperators[operator] = true;
        emit OperatorBlocked(operator);
    }
    
    /**
     * @dev Internal function to unblock operator
     */
    function _unblockOperator(address operator) internal {
        blockedOperators[operator] = false;
        emit OperatorUnblocked(operator);
    }
    
    /**
     * @dev Internal function to set filter status
     */
    function _setOperatorFilterEnabled(bool enabled) internal {
        operatorFilterEnabled = enabled;
        emit OperatorFilterStatusChanged(enabled);
    }
    
    /**
     * @dev Modifier to check operator
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            require(isOperatorAllowed(msg.sender), "Operator blocked");
        }
        _;
    }
}
