// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTProvenance
 * @dev Extension for tracking token history and provenance
 */
abstract contract NFTProvenance {
    
    struct ProvenanceRecord {
        address from;
        address to;
        uint256 timestamp;
        uint256 price;
        string eventType; // "mint", "transfer", "sale"
    }
    
    mapping(uint256 => ProvenanceRecord[]) private _tokenHistory;
    mapping(uint256 => address) private _originalCreator;
    
    event ProvenanceRecorded(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string eventType,
        uint256 price
    );
    
    /**
     * @dev Record mint event
     */
    function _recordMint(uint256 tokenId, address creator) internal {
        _originalCreator[tokenId] = creator;
        
        _tokenHistory[tokenId].push(ProvenanceRecord({
            from: address(0),
            to: creator,
            timestamp: block.timestamp,
            price: 0,
            eventType: "mint"
        }));
        
        emit ProvenanceRecorded(tokenId, address(0), creator, "mint", 0);
    }
    
    /**
     * @dev Record transfer event
     */
    function _recordTransfer(uint256 tokenId, address from, address to) internal {
        _tokenHistory[tokenId].push(ProvenanceRecord({
            from: from,
            to: to,
            timestamp: block.timestamp,
            price: 0,
            eventType: "transfer"
        }));
        
        emit ProvenanceRecorded(tokenId, from, to, "transfer", 0);
    }
    
    /**
     * @dev Record sale event with price
     */
    function _recordSale(uint256 tokenId, address from, address to, uint256 price) internal {
        _tokenHistory[tokenId].push(ProvenanceRecord({
            from: from,
            to: to,
            timestamp: block.timestamp,
            price: price,
            eventType: "sale"
        }));
        
        emit ProvenanceRecorded(tokenId, from, to, "sale", price);
    }
    
    /**
     * @dev Get original creator
     */
    function getOriginalCreator(uint256 tokenId) public view returns (address) {
        return _originalCreator[tokenId];
    }
    
    /**
     * @dev Get number of provenance records
     */
    function getProvenanceCount(uint256 tokenId) public view returns (uint256) {
        return _tokenHistory[tokenId].length;
    }
    
    /**
     * @dev Get specific provenance record
     */
    function getProvenanceRecord(uint256 tokenId, uint256 index) 
        public 
        view 
        returns (
            address from,
            address to,
            uint256 timestamp,
            uint256 price,
            string memory eventType
        ) 
    {
        require(index < _tokenHistory[tokenId].length, "Invalid index");
        
        ProvenanceRecord memory record = _tokenHistory[tokenId][index];
        return (record.from, record.to, record.timestamp, record.price, record.eventType);
    }
    
    /**
     * @dev Get complete token history
     */
    function getFullProvenance(uint256 tokenId) 
        public 
        view 
        returns (ProvenanceRecord[] memory) 
    {
        return _tokenHistory[tokenId];
    }
}
