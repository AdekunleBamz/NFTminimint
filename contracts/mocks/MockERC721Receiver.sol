// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockERC721Receiver
 * @dev Mock contract to test ERC721 safe transfer functionality
 */
contract MockERC721Receiver {
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    bool public shouldRevert;
    bool public shouldReturnWrongValue;
    
    event Received(address operator, address from, uint256 tokenId, bytes data);
    
    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }
    
    function setShouldReturnWrongValue(bool _shouldReturnWrongValue) external {
        shouldReturnWrongValue = _shouldReturnWrongValue;
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(!shouldRevert, "MockERC721Receiver: reverting");
        
        emit Received(operator, from, tokenId, data);
        
        if (shouldReturnWrongValue) {
            return bytes4(0xdeadbeef);
        }
        
        return _ERC721_RECEIVED;
    }
}

/**
 * @title MockERC721NonReceiver
 * @dev Contract that doesn't implement ERC721Receiver
 */
contract MockERC721NonReceiver {
    // Intentionally no onERC721Received function
    
    function doNothing() external pure returns (bool) {
        return true;
    }
}
