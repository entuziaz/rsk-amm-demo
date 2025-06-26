// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Use latest stable version

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(
        string memory name, 
        string memory symbol, 
        uint256 initialSupply // Add supply parameter
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }
}