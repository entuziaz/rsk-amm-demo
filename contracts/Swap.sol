// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IGovernance {
    function calculateFee(uint256 amount) external view returns (uint256);
}

interface ILiquidityPool {
    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external;
    function getReserves(address tokenA, address tokenB) external view returns (uint256, uint256);
}

contract Swap {
    using SafeERC20 for IERC20;

    IGovernance public governance;
    ILiquidityPool public liquidityPool;

    constructor(address _governance, address _liquidityPool) {
        governance = IGovernance(_governance);
        liquidityPool = ILiquidityPool(_liquidityPool);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external {
        require(tokenIn != tokenOut, "Same token");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(liquidityPool), amountIn);

        (uint256 reserveIn, uint256 reserveOut) = liquidityPool.getReserves(tokenIn, tokenOut);
        require(reserveIn > 0 && reserveOut > 0, "No liquidity");

        uint256 fee = governance.calculateFee(amountIn);
        uint256 netIn = amountIn - fee;

        uint256 amountOut = (netIn * reserveOut) / (reserveIn + netIn);
        require(amountOut >= minAmountOut, "Slippage too high");

        liquidityPool.swapTokens(tokenIn, tokenOut, amountIn, amountOut);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }
}
