// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StringUtils
 * @dev String utility functions
 * @author Adekunle Bamz
 * @notice Helper functions for string operations
 */
library StringUtils {
    /**
     * @notice Check if string is empty
     * @param str String to check
     * @return bool True if empty
     */
    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
    
    /**
     * @notice Get string length
     * @param str String to measure
     * @return uint256 Length in bytes
     */
    function length(string memory str) internal pure returns (uint256) {
        return bytes(str).length;
    }
    
    /**
     * @notice Compare two strings
     * @param a First string
     * @param b Second string
     * @return bool True if equal
     */
    function equals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    /**
     * @notice Concatenate two strings
     * @param a First string
     * @param b Second string
     * @return string Concatenated result
     */
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    /**
     * @notice Convert uint to string
     * @param value Number to convert
     * @return string String representation
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
