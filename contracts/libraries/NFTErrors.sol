// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTErrors
 * @dev Custom error definitions for NFTminimint ecosystem
 * @author Adekunle Bamz
 * @notice Gas-efficient custom errors for all contracts
 */

/// @dev Thrown when zero address is provided
error ZeroAddress();

/// @dev Thrown when caller is not authorized
error NotAuthorized();

/// @dev Thrown when token does not exist
error TokenDoesNotExist(uint256 tokenId);

/// @dev Thrown when minting is paused
error MintingPaused();

/// @dev Thrown when caller is not whitelisted
error NotWhitelisted(address account);

/// @dev Thrown when wallet mint limit is reached
error WalletLimitReached(address wallet, uint256 limit);

/// @dev Thrown when max supply would be exceeded
error MaxSupplyExceeded(uint256 requested, uint256 remaining);

/// @dev Thrown when metadata is frozen
error MetadataFrozen();

/// @dev Thrown when token metadata is frozen
error TokenMetadataFrozen(uint256 tokenId);

/// @dev Thrown when public mint is not open
error PublicMintNotOpen();

/// @dev Thrown when batch size is invalid
error InvalidBatchSize(uint256 size, uint256 maxSize);

/// @dev Thrown when arrays length mismatch
error ArrayLengthMismatch(uint256 length1, uint256 length2);

/// @dev Thrown when royalty fee is too high
error RoyaltyFeeTooHigh(uint96 fee, uint96 maxFee);

/// @dev Thrown when caller is not the owner
error NotOwner();

/// @dev Thrown when caller is not admin
error NotAdmin();

/// @dev Thrown when operation is already done
error AlreadyDone();

/// @dev Thrown when invalid parameter
error InvalidParameter(string param);
