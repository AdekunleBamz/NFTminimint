// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTRentable
 * @dev Extension for EIP-4907 rentable NFTs
 */
abstract contract NFTRentable {
    
    struct UserInfo {
        address user;
        uint64 expires;
    }
    
    mapping(uint256 => UserInfo) private _users;
    
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    
    /**
     * @dev Set user and expiry for a token
     */
    function _setUser(uint256 tokenId, address user, uint64 expires) internal {
        _users[tokenId] = UserInfo(user, expires);
        emit UpdateUser(tokenId, user, expires);
    }
    
    /**
     * @dev Get the current user of a token
     */
    function userOf(uint256 tokenId) public view returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        }
        return address(0);
    }
    
    /**
     * @dev Get the expiry timestamp for user
     */
    function userExpires(uint256 tokenId) public view returns (uint256) {
        return _users[tokenId].expires;
    }
    
    /**
     * @dev Check if token has active rental
     */
    function hasActiveRental(uint256 tokenId) public view returns (bool) {
        return _users[tokenId].user != address(0) && 
               uint256(_users[tokenId].expires) >= block.timestamp;
    }
    
    /**
     * @dev Clear user info (call on transfer/burn)
     */
    function _clearUser(uint256 tokenId) internal {
        delete _users[tokenId];
        emit UpdateUser(tokenId, address(0), 0);
    }
    
    /**
     * @dev Get full user info
     */
    function getUserInfo(uint256 tokenId) public view returns (address user, uint64 expires) {
        UserInfo memory info = _users[tokenId];
        return (info.user, info.expires);
    }
}
