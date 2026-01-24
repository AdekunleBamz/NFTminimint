// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTRoyaltySplit
 * @dev Extension for splitting royalties among multiple recipients
 */
abstract contract NFTRoyaltySplit {
    
    struct RoyaltyRecipient {
        address recipient;
        uint256 share; // Basis points (e.g., 5000 = 50%)
    }
    
    RoyaltyRecipient[] private _royaltyRecipients;
    uint256 private _totalShares;
    
    event RoyaltyRecipientAdded(address indexed recipient, uint256 share);
    event RoyaltyRecipientRemoved(address indexed recipient);
    event RoyaltySplitUpdated(address[] recipients, uint256[] shares);
    
    /**
     * @dev Add a royalty recipient
     */
    function _addRoyaltyRecipient(address recipient, uint256 share) internal {
        require(recipient != address(0), "Invalid recipient");
        require(share > 0, "Share must be > 0");
        require(_totalShares + share <= 10000, "Total shares exceed 100%");
        
        _royaltyRecipients.push(RoyaltyRecipient({
            recipient: recipient,
            share: share
        }));
        
        _totalShares += share;
        emit RoyaltyRecipientAdded(recipient, share);
    }
    
    /**
     * @dev Set all royalty recipients at once
     */
    function _setRoyaltySplit(
        address[] memory recipients,
        uint256[] memory shares
    ) internal {
        require(recipients.length == shares.length, "Arrays length mismatch");
        
        // Clear existing
        delete _royaltyRecipients;
        _totalShares = 0;
        
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            require(shares[i] > 0, "Share must be > 0");
            
            total += shares[i];
            require(total <= 10000, "Total shares exceed 100%");
            
            _royaltyRecipients.push(RoyaltyRecipient({
                recipient: recipients[i],
                share: shares[i]
            }));
        }
        
        _totalShares = total;
        emit RoyaltySplitUpdated(recipients, shares);
    }
    
    /**
     * @dev Calculate royalty split for a sale
     */
    function _calculateRoyaltySplit(uint256 totalRoyalty) 
        internal 
        view 
        returns (address[] memory recipients, uint256[] memory amounts) 
    {
        uint256 count = _royaltyRecipients.length;
        recipients = new address[](count);
        amounts = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            recipients[i] = _royaltyRecipients[i].recipient;
            amounts[i] = (totalRoyalty * _royaltyRecipients[i].share) / _totalShares;
        }
        
        return (recipients, amounts);
    }
    
    /**
     * @dev Get royalty recipient info
     */
    function getRoyaltyRecipient(uint256 index) 
        public 
        view 
        returns (address recipient, uint256 share) 
    {
        require(index < _royaltyRecipients.length, "Invalid index");
        RoyaltyRecipient memory r = _royaltyRecipients[index];
        return (r.recipient, r.share);
    }
    
    /**
     * @dev Get total number of royalty recipients
     */
    function getRoyaltyRecipientCount() public view returns (uint256) {
        return _royaltyRecipients.length;
    }
    
    /**
     * @dev Get total shares allocated
     */
    function getTotalShares() public view returns (uint256) {
        return _totalShares;
    }
}
