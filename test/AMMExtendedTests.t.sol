// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/LiquidityPool.sol";
import "../contracts/Governance.sol";
import "../contracts/TestToken.sol";

contract AMMExtendedTests is Test {
    TestToken tokenA;
    TestToken tokenB;
    Governance governance;
    LiquidityPool pool;
    address feeTo;

    function setUp() public {
        tokenA = new TestToken("Token A", "TKNA", 1_000_000 ether);
        tokenB = new TestToken("Token B", "TKNB", 1_000_000 ether);

        feeTo = address(0xfee);
        governance = new Governance(10); // 0.1% fee
        pool = new LiquidityPool(address(governance), feeTo);

        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
    }

    function testAddLiquidityMintsLPTokens() public {
        pool.addLiquidity(address(tokenA), address(tokenB), 1e18, 1e18, 0, 0);
        uint256 liquidity = pool.getUserLiquidity(address(tokenA), address(tokenB), address(this));
        assertGt(liquidity, 0, "LP tokens not minted");
    }

    function testRemoveLiquidityReturnsCorrectAmounts() public {
        pool.addLiquidity(address(tokenA), address(tokenB), 1e18, 1e18, 0, 0);
        uint256 liquidity = pool.getUserLiquidity(address(tokenA), address(tokenB), address(this));

        (uint256 reserveA, uint256 reserveB) = pool.getReserves(address(tokenA), address(tokenB));
        (uint256 amount0, uint256 amount1) = pool.removeLiquidity(address(tokenA), address(tokenB), liquidity, 0, 0);

        assertEq(amount0, reserveA);
        assertEq(amount1, reserveB);
    }

    function testSwapFailsOnSlippageTooHigh() public {
        pool.addLiquidity(address(tokenA), address(tokenB), 10e18, 10e18, 0, 0);

        uint256 amountIn = 1e18;
        uint256 amountOut = 2e18; // Too optimistic

        tokenA.approve(address(pool), amountIn);

        vm.expectRevert(); // Should revert due to slippage
        pool.swapTokens(address(tokenA), address(tokenB), amountIn, amountOut);
    }

    function testFeeIsTakenCorrectly() public {
    pool.addLiquidity(address(tokenA), address(tokenB), 10e18, 10e18, 0, 0);

    uint256 amountIn = 1e18;
    uint256 fee = governance.calculateFee(amountIn);
    uint256 netIn = amountIn - fee;

    // Calculate amountOut using constant product formula
    uint256 reserveIn = 10e18;
    uint256 reserveOut = 10e18;

    // x * y = k
    uint256 newReserveIn = reserveIn + netIn;
    uint256 newReserveOut = reserveIn * reserveOut / newReserveIn;
    uint256 expectedAmountOut = reserveOut - newReserveOut;

    tokenA.approve(address(pool), amountIn);
    pool.swapTokens(address(tokenA), address(tokenB), amountIn, expectedAmountOut - 1);

    (uint256 reserveA, ) = pool.getReserves(address(tokenA), address(tokenB));
    assertEq(reserveA, reserveIn + netIn, "Fee not accounted for");
}

}
