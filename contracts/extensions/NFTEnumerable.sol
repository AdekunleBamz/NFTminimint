// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../NFTCore.sol"; // Need NFTCore to know what we are mixing with? No, just the standard.

abstract contract NFTEnumerable is ERC721Enumerable {
    // This abstract contract brings in ERC721Enumerable functionality.
    // The implementing contract must override _update, _increaseBalance, and supportsInterface.
    // We can provide helper virtual functions or just let the user handle it.
    // But since this is a mixin, we can't easily override the base NFTCore functions here because we don't inherit NFTCore here.
    // The user combines them.
}
