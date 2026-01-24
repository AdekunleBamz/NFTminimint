// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTEvents
 * @dev Common event definitions for NFTminimint ecosystem
 * @author Adekunle Bamz
 * @notice Centralized event definitions for indexing
 */

abstract contract NFTEvents {
	/// @dev Emitted when a contract is upgraded
	event ContractUpgraded(address indexed oldContract, address indexed newContract);

	/// @dev Emitted when ownership transfer is initiated
	event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);

	/// @dev Emitted when a contract is paused
	event ContractPaused(address indexed pauser);

	/// @dev Emitted when a contract is unpaused
	event ContractUnpaused(address indexed unpauser);

	/// @dev Emitted when emergency withdrawal is executed
	event EmergencyWithdrawal(address indexed to, uint256 amount);

	/// @dev Emitted when batch operation completes
	event BatchOperationCompleted(string operation, uint256 count);
}
