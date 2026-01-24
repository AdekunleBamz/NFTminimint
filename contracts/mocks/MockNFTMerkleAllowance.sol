// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTMerkleAllowance.sol";

/**
 * @title MockNFTMerkleAllowance
 * @dev Mock contract to test NFTMerkleAllowance extension
 */
contract MockNFTMerkleAllowance is NFTMerkleAllowance {
    uint256 public totalMinted;

    function setMerkleRoot(bytes32 root) external {
        _setAllowanceMerkleRoot(root);
    }

    function setEnabled(bool enabled) external {
        _setAllowanceMintEnabled(enabled);
    }

    function claim(uint256 quantity, uint256 allowance, bytes32[] calldata proof) external {
        _validateAndConsumeAllowance(proof, msg.sender, quantity, allowance);
        totalMinted += quantity;
    }
}
