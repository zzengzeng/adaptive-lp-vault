// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap-v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// errors
error NoUniswapV2Pair();

/**
 *     @title Adaptive LP Vault
 *     @notice A vault that accepts deposits of a specific ERC20 token and invests them into a Uniswap V2 liquidity pool. The vault will manage the LP tokens and allow users to redeem their shares for the underlying assets.
 *
 */
contract AdaptiveLpVault is ERC4626, AccessControl {
    // Roles
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    address public immutable token0;
    address public immutable token1;

    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    // Events

    constructor(IERC20 _asset, address _token0, address _token1, IUniswapV2Router02 _router)
        ERC4626(_asset)
        ERC20("Adaptive LP Share", "aLPS")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initialize state variables
        token0 = _token0;
        token1 = _token1;
        router = IUniswapV2Router02(_router);

        // Get the Uniswap V2 pair address for the given tokens
        pair = IUniswapV2Factory(router.factory()).getPair(_token0, _token1);
        if (pair == address(0)) {
            revert NoUniswapV2Pair();
        }
    }

    /**
     * @notice Returns the total amount of assets managed by the vault, including the value of the LP tokens.
     * @return The total assets in the vault.
     *
     */
    function totalAssets() public view override returns (uint256) {
        // Get the balance of the underlying asset in the vault
        uint256 balance = IERC20(address(asset())).balanceOf(address(this));
        // Get the value of the LP tokens held by the vault
        uint256 v2LpValue = _getV2PositionValue();
        // Return the total assets, which is the sum of the balance and the value of the LP tokens
        return balance + v2LpValue;
    }

    /**
     * @notice Invests the underlying assets into the Uniswap V2 liquidity pool by providing liquidity. The vault will receive LP tokens in return, which represent the vault's share of the liquidity pool.
     * @dev This function should be called by the strategist role after depositing assets into the vault. The strategist will need to approve the vault to spend the underlying assets before calling this function.
     * @param amount0 The amount of token0 to provide as liquidity.
     * @param amount1 The amount of token1 to provide as liquidity.
     * @param amount0Min The minimum amount of token0 to provide as liquidity (used for slippage protection).
     * @param amount1Min The minimum amount of token1 to provide as liquidity (used for slippage protection).
     * @notice The strategist should ensure that the amounts provided are in the correct ratio according to the current reserves of the Uniswap V2 pair to avoid unnecessary slippage.
     *
     */
    function investV2(uint256 amount0, uint256 amount1, uint256 amount0Min, uint256 amount1Min) public {
        IERC20(token0).approve(address(router), amount0);
        IERC20(token1).approve(address(router), amount1);
        router.addLiquidity(token0, token1, amount0, amount1, amount0Min, amount1Min, address(this), block.timestamp);
    }

    /**
     * @notice Calculates the value of the Uniswap V2 position held by the vault.
     * @return The value of the Uniswap V2 position in terms of the underlying asset.
     *
     */
    function _getV2PositionValue() public view returns (uint256) {
        uint256 lpBalance = IUniswapV2Pair(pair).balanceOf(address(this));
        if (lpBalance == 0) {
            return 0;
        }
        uint256 totalSupply = IUniswapV2Pair(pair).totalSupply();
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 amount0 = (lpBalance * reserve0) / totalSupply;
        uint256 amount1 = (lpBalance * reserve1) / totalSupply;

        // Assuming token0 is the underlying asset, we can calculate the total value in terms of token0
        // If token1 is the underlying asset, we would need to convert amount0 to the value of token1 using the Uniswap V2 price
        return amount0 + amount1; // This is a simplified calculation, in a real implementation you would need to consider the price of token1 in terms of token0
    }
}
