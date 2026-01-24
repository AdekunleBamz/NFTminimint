// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTRandomMint
 * @dev Extension for randomized token ID assignment
 */
abstract contract NFTRandomMint {
    
    uint256 private _maxSupply;
    uint256 private _remaining;
    mapping(uint256 => uint256) private _availableTokens;
    
    event RandomMintConfigured(uint256 maxSupply);
    
    /**
     * @dev Initialize random mint with max supply
     */
    function _initializeRandomMint(uint256 maxSupply) internal {
        require(maxSupply > 0, "Max supply must be > 0");
        _maxSupply = maxSupply;
        _remaining = maxSupply;
        emit RandomMintConfigured(maxSupply);
    }
    
    /**
     * @dev Get a random available token ID
     * Uses Fisher-Yates shuffle algorithm
     */
    function _getRandomTokenId(uint256 nonce) internal returns (uint256) {
        require(_remaining > 0, "No tokens remaining");
        
        uint256 randomIndex = _pseudoRandom(nonce) % _remaining;
        uint256 tokenId = _getAvailableTokenAtIndex(randomIndex);
        
        _remaining--;
        
        // Swap with last available
        _availableTokens[randomIndex] = _getAvailableTokenAtIndex(_remaining);
        
        return tokenId;
    }
    
    /**
     * @dev Get token at index or index itself if not swapped
     */
    function _getAvailableTokenAtIndex(uint256 index) internal view returns (uint256) {
        if (_availableTokens[index] != 0) {
            return _availableTokens[index];
        }
        return index;
    }
    
    /**
     * @dev Generate pseudo-random number
     * Note: Not secure for high-value use cases
     */
    function _pseudoRandom(uint256 nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            nonce,
            _remaining
        )));
    }
    
    /**
     * @dev Get remaining tokens
     */
    function remainingTokens() public view returns (uint256) {
        return _remaining;
    }
    
    /**
     * @dev Get max supply for random mint
     */
    function randomMintMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }
}
