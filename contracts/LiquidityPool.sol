// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LPToken.sol";
import "./Governance.sol"; // Needed for fee handling

contract LiquidityPool is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct Pool {
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLiquidity;
        uint256 kLast;
        LPToken lpToken;
    }

    mapping(address => mapping(address => Pool)) public pools;
    Governance public governance;
    address public feeTo;

    event Deposit(address indexed provider, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Withdraw(address indexed provider, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    event SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _governance, address _feeTo) {
        require(_governance != address(0), "Zero governance address");
        governance = Governance(_governance);
        feeTo = _feeTo;
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

        if (address(pool.lpToken) == address(0)) {
            string memory name = string(abi.encodePacked("LP-", symbol(token0), "/", symbol(token1)));
            string memory symbolStr = string(abi.encodePacked("LP-", shortSymbol(token0), shortSymbol(token1)));
            pool.lpToken = new LPToken(name, symbolStr);
        }

        uint256 amount0;
        uint256 amount1;

        if (pool.totalLiquidity == 0) {
            // First deposit - use desired amounts directly
            amount0 = tokenA == token0 ? amountADesired : amountBDesired;
            amount1 = tokenA == token0 ? amountBDesired : amountADesired;
            liquidity = Math.sqrt(amount0 * amount1);
        } else {
            // Calculate optimal amounts based on current pool ratio
            uint256 amount0Desired = tokenA == token0 ? amountADesired : amountBDesired;
            uint256 amount1Desired = tokenA == token0 ? amountBDesired : amountADesired;
            
            // Calculate how much of token1 should be deposited based on token0 amount
            uint256 amount1Optimal = (amount0Desired * pool.reserveB) / pool.reserveA;
            
            if (amount1Optimal <= amount1Desired) {
                // Use all of token0 and optimal amount of token1
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                // Calculate how much of token0 should be deposited based on token1 amount
                uint256 amount0Optimal = (amount1Desired * pool.reserveA) / pool.reserveB;
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
            
            liquidity = Math.min(
                (amount0 * pool.totalLiquidity) / pool.reserveA,
                (amount1 * pool.totalLiquidity) / pool.reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity");
        require(amount0 >= amountAMin && amount1 >= amountBMin, "Slippage");

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        pool.reserveA += amount0;
        pool.reserveB += amount1;
        pool.totalLiquidity += liquidity;
        pool.kLast = pool.reserveA * pool.reserveB;

        pool.lpToken.mint(msg.sender, liquidity);

        emit Deposit(msg.sender, token0, token1, amount0, amount1, liquidity);
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

        require(pool.lpToken.balanceOf(msg.sender) >= liquidity, "Insufficient LP tokens");

        uint256 total = pool.totalLiquidity;
        require(total > 0, "No liquidity");

        amount0 = (liquidity * pool.reserveA) / total;
        amount1 = (liquidity * pool.reserveB) / total;

        require(amount0 >= amountAMin && amount1 >= amountBMin, "Slippage");

        pool.reserveA -= amount0;
        pool.reserveB -= amount1;
        pool.totalLiquidity -= liquidity;
        pool.kLast = pool.reserveA * pool.reserveB;

        pool.lpToken.burn(msg.sender, liquidity);

        IERC20(token0).safeTransfer(msg.sender, amount0);
        IERC20(token1).safeTransfer(msg.sender, amount1);

        emit Withdraw(msg.sender, token0, token1, amount0, amount1, liquidity);
    }

    function swapTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut
    ) external nonReentrant {
        require(tokenIn != tokenOut, "Same token");
        (address token0, address token1) = sortTokens(tokenIn, tokenOut);
        Pool storage pool = pools[token0][token1];

        uint256 fee = governance.calculateFee(amountIn);
        uint256 netAmountIn = amountIn - fee;
        
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Transfer fee to feeTo address if fee exists 
        if (fee > 0 && feeTo != address(0)) {
            IERC20(tokenIn).safeTransfer(feeTo, fee);
        }

        uint256 reserveIn = tokenIn == token0 ? pool.reserveA : pool.reserveB;
        uint256 reserveOut = tokenIn == token0 ? pool.reserveB : pool.reserveA;

        // actual output amount
        uint256 amountOut = (netAmountIn * reserveOut) / (reserveIn + netAmountIn);
        
        // using minAmountOut as slippage protection 
        require(amountOut >= minAmountOut, "Slippage too high");

        if (tokenIn == token0) {
            pool.reserveA += netAmountIn;
            pool.reserveB -= amountOut;
        } else {
            pool.reserveB += netAmountIn;
            pool.reserveA -= amountOut;
        }

        pool.kLast = pool.reserveA * pool.reserveB;

        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }


    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        return (
            tokenA == token0 ? pool.reserveA : pool.reserveB,
            tokenA == token0 ? pool.reserveB : pool.reserveA
        );
    }

    function getUserLiquidity(address tokenA, address tokenB, address user) external view returns (uint256) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        Pool storage pool = pools[token0][token1];
        return address(pool.lpToken) != address(0) ? pool.lpToken.balanceOf(user) : 0;
    }



    function symbol(address token) internal view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (success && data.length >= 32) return abi.decode(data, (string));
        return "UNKNOWN";
    }

    function shortSymbol(address token) internal view returns (string memory) {
        bytes memory b = bytes(symbol(token));
        return b.length >= 3 ? string(abi.encodePacked(b[0], b[1], b[2])) : string(b);
    }
}
