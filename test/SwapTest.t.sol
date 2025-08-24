// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/LiquidityPool.sol";
import "../contracts/TestToken.sol";
import "../contracts/Swap.sol";
import "../contracts/Governance.sol";

contract SwapTest is Test {
    Governance governance;
    LiquidityPool pool;
    Swap swap;
    TestToken tokenA;
    TestToken tokenB;
    address user = address(0x123);

    function setUp() public {
        tokenA = new TestToken("Token A", "TKA", 1_000_000);
        tokenB = new TestToken("Token B", "TKB", 1_000_000);
        governance = new Governance(30);
        pool = new LiquidityPool(address(governance), address(this));
        swap = new Swap(address(governance), address(pool));

        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);

        pool.addLiquidity(address(tokenA), address(tokenB), 1e18 * 1000, 1e18 * 1000, 0, 0);

        tokenA.transfer(user, 1e18 * 10);
        vm.prank(user);
        tokenA.approve(address(swap), type(uint256).max);
    }

    function testSwapExecution() public {
        vm.prank(user);
        swap.swap(address(tokenA), address(tokenB), 1e18 * 10, 1e18);
    }
}
