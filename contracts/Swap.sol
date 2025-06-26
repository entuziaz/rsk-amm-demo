// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IGovernance {
    function calculateFee(uint256 amount) external view returns (uint256);
}

interface ILiquidityPool {
    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external;

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
        uint256 amountIn
        // uint256 minAmountOut
    ) external {
        require(tokenIn != tokenOut, "Same token");

        // Transfer input tokens from user to this contract
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the liquidity pool to spend tokens
        IERC20(tokenIn).approve(address(liquidityPool), amountIn);

        // Get reserves to compute output
        (uint256 reserveIn, uint256 reserveOut) = liquidityPool.getReserves(tokenIn, tokenOut);
        require(reserveIn > 0 && reserveOut > 0, "No liquidity");

        // Basic constant product formula (x * y = k) with fee
        // Output = (amountIn * reserveOut) / (reserveIn + amountIn)
        uint256 amountOutBeforeFee = (amountIn * reserveOut) / (reserveIn + amountIn);

        // Get fee from Governance
        uint256 fee = governance.calculateFee(amountOutBeforeFee);
        uint256 finalAmountOut = amountOutBeforeFee - fee;

        // require(finalAmountOut >= minAmountOut, "Slippage too high");

        // Execute the swap in the pool
        liquidityPool.swapTokens(tokenIn, tokenOut, amountIn, finalAmountOut);

        // Send the output tokens to the user
        IERC20(tokenOut).safeTransfer(msg.sender, finalAmountOut);
    }
}