// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract NFTRoyalty is ERC2981 {
    // Inherits ERC2981 functionality
    // _setDefaultRoyalty and _setTokenRoyalty are available internally
}
