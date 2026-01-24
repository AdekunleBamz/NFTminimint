// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTAllowlist
 * @dev Merkle tree-based allowlist for efficient whitelist management
 */
abstract contract NFTAllowlist {
    
    bytes32 private _merkleRoot;
    bool private _allowlistMintEnabled;
    
    mapping(address => bool) private _allowlistClaimed;
    
    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event AllowlistMintStatusChanged(bool enabled);
    event AllowlistClaimed(address indexed account);
    
    /**
     * @dev Set the Merkle root for allowlist verification
     */
    function _setMerkleRoot(bytes32 merkleRoot) internal {
        bytes32 oldRoot = _merkleRoot;
        _merkleRoot = merkleRoot;
        emit MerkleRootUpdated(oldRoot, merkleRoot);
    }
    
    /**
     * @dev Enable or disable allowlist minting
     */
    function _setAllowlistMintEnabled(bool enabled) internal {
        _allowlistMintEnabled = enabled;
        emit AllowlistMintStatusChanged(enabled);
    }
    
    /**
     * @dev Verify a Merkle proof
     */
    function _verifyProof(
        bytes32[] calldata proof,
        address account
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return _verify(proof, _merkleRoot, leaf);
    }
    
    /**
     * @dev Internal Merkle proof verification
     */
    function _verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        return computedHash == root;
    }
    
    /**
     * @dev Mark address as having claimed allowlist mint
     */
    function _markAllowlistClaimed(address account) internal {
        _allowlistClaimed[account] = true;
        emit AllowlistClaimed(account);
    }
    
    /**
     * @dev Check if address has claimed allowlist mint
     */
    function hasClaimedAllowlist(address account) public view returns (bool) {
        return _allowlistClaimed[account];
    }
    
    /**
     * @dev Check if allowlist minting is enabled
     */
    function isAllowlistMintEnabled() public view returns (bool) {
        return _allowlistMintEnabled;
    }
    
    /**
     * @dev Get current Merkle root
     */
    function getMerkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }
    
    /**
     * @dev Modifier to verify allowlist membership
     */
    modifier onlyAllowlisted(bytes32[] calldata proof) {
        require(_verifyProof(proof, msg.sender), "Not on allowlist");
        require(!_allowlistClaimed[msg.sender], "Already claimed");
        _;
    }
}
