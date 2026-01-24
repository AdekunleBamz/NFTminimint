// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMerkleAllowance
 * @dev Merkle allowlist where each address has a mint allowance baked into the leaf.
 *      Leaf format: keccak256(abi.encodePacked(account, allowance))
 */
abstract contract NFTMerkleAllowance {
    bytes32 private _allowanceMerkleRoot;
    bool private _allowanceMintEnabled;

    mapping(address => uint256) private _allowanceClaimed;

    event AllowanceMerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event AllowanceMintStatusChanged(bool enabled);
    event AllowanceClaimed(address indexed account, uint256 quantity, uint256 totalClaimed, uint256 allowance);

    function _setAllowanceMerkleRoot(bytes32 merkleRoot) internal {
        bytes32 oldRoot = _allowanceMerkleRoot;
        _allowanceMerkleRoot = merkleRoot;
        emit AllowanceMerkleRootUpdated(oldRoot, merkleRoot);
    }

    function _setAllowanceMintEnabled(bool enabled) internal {
        _allowanceMintEnabled = enabled;
        emit AllowanceMintStatusChanged(enabled);
    }

    function _validateAndConsumeAllowance(
        bytes32[] calldata proof,
        address account,
        uint256 quantity,
        uint256 allowance
    ) internal {
        require(_allowanceMintEnabled, "Allowance mint disabled");
        require(quantity > 0, "Zero quantity");
        require(_verifyAllowanceProof(proof, account, allowance), "Invalid proof");

        uint256 claimed = _allowanceClaimed[account];
        require(claimed + quantity <= allowance, "Allowance exceeded");

        uint256 totalClaimed = claimed + quantity;
        _allowanceClaimed[account] = totalClaimed;

        emit AllowanceClaimed(account, quantity, totalClaimed, allowance);
    }

    function _verifyAllowanceProof(
        bytes32[] calldata proof,
        address account,
        uint256 allowance
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account, allowance));
        return _verify(proof, _allowanceMerkleRoot, leaf);
    }

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

    function allowanceClaimed(address account) public view returns (uint256) {
        return _allowanceClaimed[account];
    }

    function isAllowanceMintEnabled() public view returns (bool) {
        return _allowanceMintEnabled;
    }

    function getAllowanceMerkleRoot() public view returns (bytes32) {
        return _allowanceMerkleRoot;
    }
}
