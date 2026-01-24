// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTEmergency
 * @dev Emergency functions for NFT contracts
 * @author Adekunle Bamz
 * @notice Use with caution - emergency operations only
 */
abstract contract NFTEmergency is Ownable {
    
    /// @dev Emitted when emergency withdrawal is executed
    event EmergencyWithdrawal(address indexed to, uint256 amount);
    
    /// @dev Emitted when ERC20 emergency withdrawal is executed
    event EmergencyERC20Withdrawal(address indexed token, address indexed to, uint256 amount);
    
    /**
     * @notice Emergency withdraw all ETH
     * @param to Recipient address
     */
    function emergencyWithdrawETH(address payable to) external onlyOwner {
        require(to != address(0), "Zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        
        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawal(to, balance);
    }
    
    /**
     * @notice Check contract ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
