// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Governance is Ownable {
    // using SafeMath for uint256;
    
    uint256 public tradingFee; // Stored in basis points (1 = 0.01%)
    uint256 public constant MAX_FEE = 100; // 1% maximum (100 basis points)

    event FeeUpdated(uint256 newFee);

    constructor(uint256 initialFee) Ownable(msg.sender) {
        require(initialFee <= MAX_FEE, "Initial fee too high");
        tradingFee = initialFee;
    }

    function setTradingFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, "Fee exceeds maximum");
        tradingFee = newFee;
        emit FeeUpdated(newFee);
    }

    function calculateFee(uint256 amount) external view returns (uint256) {
        // return amount.mul(tradingFee).div(10000);
        return (amount * tradingFee) / 10000;

    }
}