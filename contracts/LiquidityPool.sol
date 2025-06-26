// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; 



contract LiquidityPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Pool {
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLiquidity;
        mapping(address => uint256) balances;
    }

    mapping(address => mapping(address => Pool)) public pools;

    event deposit(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event withdraw(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event swapExecuted(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor() {
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant returns (uint256 liquidity) {
        require(tokenA != tokenB, "Identical tokens");
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        
        Pool storage pool = pools[token0][token1];
        uint256 amount0 = tokenA == token0 ? amountADesired : amountBDesired;
        uint256 amount1 = tokenA == token0 ? amountBDesired : amountADesired;

        if (pool.totalLiquidity == 0) {
            liquidity = sqrt(amount0 * amount1);
        } else {
            liquidity = min(
                (amount0 * pool.totalLiquidity) / pool.reserveA,
                (amount1 * pool.totalLiquidity) / pool.reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");
        require(amount0 >= amountAMin && amount1 >= amountBMin, "Slippage exceeded");

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        pool.reserveA += amount0;
        pool.reserveB += amount1;
        pool.totalLiquidity += liquidity;
        pool.balances[msg.sender] += liquidity;

        emit deposit(msg.sender, token0, token1, amount0, amount1, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        
        amount0 = (liquidity * pool.reserveA) / pool.totalLiquidity;
        amount1 = (liquidity * pool.reserveB) / pool.totalLiquidity;
        
        require(amount0 >= amountAMin && amount1 >= amountBMin, "Insufficient output");
        require(pool.balances[msg.sender] >= liquidity, "Insufficient liquidity");

        pool.reserveA -= amount0;
        pool.reserveB -= amount1;
        pool.totalLiquidity -= liquidity;
        pool.balances[msg.sender] -= liquidity;

        IERC20(token0).safeTransfer(msg.sender, amount0);
        IERC20(token1).safeTransfer(msg.sender, amount1);

        emit withdraw(msg.sender, token0, token1, amount0, amount1, liquidity);
    }

    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external nonReentrant {
        require(tokenIn != tokenOut, "Identical tokens");
        (address token0, address token1) = sortTokens(tokenIn, tokenOut);
        Pool storage pool = pools[token0][token1];
        
        // Transfer tokens from user to pool
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        
        // Update reserves
        if (tokenIn == token0) {
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;
        } else {
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;
        }
        
        // Transfer output tokens to user
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }



    // Helper functions
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB) {
        require(tokenA != tokenB, "Identical tokens");
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        
        // Return reserves in the order of input tokens (not necessarily token0/token1)
        return (tokenA == token0 ? pool.reserveA : pool.reserveB, 
                tokenA == token0 ? pool.reserveB : pool.reserveA);
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}