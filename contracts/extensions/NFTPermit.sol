// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTPermit
 * @dev EIP-4494 permit extension for signature-based approvals
 */
abstract contract NFTPermit {
    
    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
    );
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    mapping(uint256 => uint256) private _nonces;
    string private _permitName;
    
    event PermitUsed(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    /**
     * @dev Initialize permit name (call in constructor of inheriting contract)
     */
    function _initPermit(string memory name) internal {
        _permitName = name;
    }
    
    /**
     * @dev Permit approval by signature
     */
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "Permit expired");
        
        address owner = _ownerOfPermit(tokenId);
        require(owner != address(0), "Token does not exist");
        require(spender != owner, "Approval to current owner");
        
        uint256 nonce = _nonces[tokenId];
        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                spender,
                tokenId,
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator(),
                structHash
            )
        );
        
        address signer = ecrecover(digest, v, r, s);
        require(signer == owner, "Invalid signature");
        
        _nonces[tokenId] = nonce + 1;
        _approvePermit(spender, tokenId);
        
        emit PermitUsed(owner, spender, tokenId);
    }
    
    /**
     * @dev Get current nonce for token
     */
    function nonces(uint256 tokenId) public view returns (uint256) {
        return _nonces[tokenId];
    }
    
    /**
     * @dev EIP-712 domain separator
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparator();
    }
    
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_permitName)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    /**
     * @dev Must be implemented to return token owner
     */
    function _ownerOfPermit(uint256 tokenId) internal view virtual returns (address);
    
    /**
     * @dev Must be implemented to approve spender
     */
    function _approvePermit(address spender, uint256 tokenId) internal virtual;
}
