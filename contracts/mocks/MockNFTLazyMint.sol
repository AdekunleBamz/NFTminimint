// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTLazyMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockNFTLazyMint is NFTLazyMint, Ownable {
    mapping(uint256 => address) public owners;

    event TokenRedeemed(uint256 indexed tokenId, address indexed owner);

    constructor() Ownable(msg.sender) {}

    function setVoucherSigner(address signer) external onlyOwner {
        _setVoucherSigner(signer);
    }

    function verifyVoucher(MintVoucher calldata voucher) external view returns (bool) {
        return _verifyVoucher(voucher);
    }

    function redeem(MintVoucher calldata voucher) external payable {
        require(_verifyVoucher(voucher), "Invalid voucher");
        require(msg.value == voucher.price, "Incorrect price");
        _useVoucher(voucher);

        owners[voucher.tokenId] = msg.sender;
        emit TokenRedeemed(voucher.tokenId, msg.sender);
    }
}
