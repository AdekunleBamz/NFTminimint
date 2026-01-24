// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AddressUtils
 * @dev Address utility functions
 * @author Adekunle Bamz
 * @notice Helper functions for address operations
 */
library AddressUtils {
    /**
     * @notice Check if address is a contract
     * @param account Address to check
     * @return bool True if contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    /**
     * @notice Check if address is zero
     * @param account Address to check
     * @return bool True if zero address
     */
    function isZero(address account) internal pure returns (bool) {
        return account == address(0);
    }
    
    /**
     * @notice Require non-zero address
     * @param account Address to check
     * @param errorMessage Error message if zero
     */
    function requireNonZero(address account, string memory errorMessage) internal pure {
        require(account != address(0), errorMessage);
    }
}
