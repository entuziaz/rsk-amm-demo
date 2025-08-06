// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    address public immutable pool;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        pool = msg.sender;
    }

    modifier onlyPool() {
        require(msg.sender == pool, "Not authorized");
        _;
    }

    function mint(address to, uint256 amount) public virtual onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public virtual onlyPool {
        _burn(from, amount);
    }
}
