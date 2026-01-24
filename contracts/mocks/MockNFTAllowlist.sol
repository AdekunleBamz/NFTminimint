// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../extensions/NFTAllowlist.sol";
import "../NFTCore.sol";

contract MockNFTAllowlist is NFTCore, NFTAllowlist {
    constructor() NFTCore("MockAllowlist", "MAL") {
        authorizedMinters[address(this)] = true;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _setMerkleRoot(root);
    }

    function setAllowlistMintEnabled(bool enabled) external onlyOwner {
        _setAllowlistMintEnabled(enabled);
    }

    function allowlistMint(bytes32[] calldata proof, string memory uri) external {
        require(isAllowlistMintEnabled(), "Allowlist mint disabled");
        require(!hasClaimedAllowlist(msg.sender), "Already claimed");
        require(_verifyProof(proof, msg.sender), "Not on allowlist");
        _markAllowlistClaimed(msg.sender);
        this.mint(msg.sender, uri);
    }
}
