// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTLazyMint
 * @dev Extension for lazy minting (mint on demand with vouchers)
 */
abstract contract NFTLazyMint {
    
    struct MintVoucher {
        uint256 tokenId;
        string uri;
        uint256 price;
        address creator;
        bytes signature;
    }
    
    mapping(bytes32 => bool) private _usedVouchers;
    address private _voucherSigner;
    
    event VoucherSignerUpdated(address indexed oldSigner, address indexed newSigner);
    event VoucherRedeemed(uint256 indexed tokenId, address indexed redeemer, address indexed creator);
    
    /**
     * @dev Set the voucher signer address
     */
    function _setVoucherSigner(address signer) internal {
        address oldSigner = _voucherSigner;
        _voucherSigner = signer;
        emit VoucherSignerUpdated(oldSigner, signer);
    }
    
    /**
     * @dev Verify voucher signature
     */
    function _verifyVoucher(MintVoucher calldata voucher) internal view returns (bool) {
        bytes32 hash = _hashVoucher(voucher);
        bytes32 ethSignedHash = _getEthSignedMessageHash(hash);
        
        return _recover(ethSignedHash, voucher.signature) == _voucherSigner;
    }
    
    /**
     * @dev Hash voucher data
     */
    function _hashVoucher(MintVoucher calldata voucher) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            voucher.tokenId,
            voucher.uri,
            voucher.price,
            voucher.creator
        ));
    }
    
    /**
     * @dev Get Ethereum signed message hash
     */
    function _getEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hash
        ));
    }
    
    /**
     * @dev Recover signer from signature
     */
    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "Invalid signature v value");
        
        return ecrecover(hash, v, r, s);
    }
    
    /**
     * @dev Mark voucher as used
     */
    function _useVoucher(MintVoucher calldata voucher) internal {
        bytes32 voucherHash = _hashVoucher(voucher);
        require(!_usedVouchers[voucherHash], "Voucher already used");
        _usedVouchers[voucherHash] = true;
        
        emit VoucherRedeemed(voucher.tokenId, msg.sender, voucher.creator);
    }
    
    /**
     * @dev Check if voucher has been used
     */
    function isVoucherUsed(bytes32 voucherHash) public view returns (bool) {
        return _usedVouchers[voucherHash];
    }
    
    /**
     * @dev Get current voucher signer
     */
    function getVoucherSigner() public view returns (address) {
        return _voucherSigner;
    }
}
