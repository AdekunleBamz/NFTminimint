// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTReveal
 * @dev Delayed reveal functionality for NFT collections
 * @author Adekunle Bamz
 * @notice Implements hidden metadata until reveal
 */
abstract contract NFTReveal {
    
    /// @dev Whether collection is revealed
    bool public revealed;
    
    /// @dev Hidden metadata URI (before reveal)
    string public hiddenMetadataURI;
    
    /// @dev Base URI (after reveal)
    string public revealedBaseURI;
    
    /// @dev Emitted when collection is revealed
    event Revealed(string baseURI);
    
    /// @dev Emitted when hidden metadata URI is set
    event HiddenMetadataURISet(string uri);
    
    /**
     * @notice Check if collection is revealed
     * @return bool True if revealed
     */
    function isRevealed() external view returns (bool) {
        return revealed;
    }
    
    /**
     * @notice Get metadata URI for a token
     * @param tokenId Token to query
     * @return string URI (hidden or revealed based on state)
     */
    function getTokenMetadataURI(uint256 tokenId) public view returns (string memory) {
        if (!revealed) {
            return hiddenMetadataURI;
        }
        return string(abi.encodePacked(revealedBaseURI, _toString(tokenId), ".json"));
    }
    
    /**
     * @dev Internal reveal function
     */
    function _reveal(string memory baseURI) internal {
        require(!revealed, "Already revealed");
        require(bytes(baseURI).length > 0, "Empty base URI");
        revealed = true;
        revealedBaseURI = baseURI;
        emit Revealed(baseURI);
    }
    
    /**
     * @dev Internal set hidden metadata
     */
    function _setHiddenMetadataURI(string memory uri) internal {
        require(!revealed, "Already revealed");
        hiddenMetadataURI = uri;
        emit HiddenMetadataURISet(uri);
    }
    
    /**
     * @dev Convert uint to string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
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
