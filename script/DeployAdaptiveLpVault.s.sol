// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AdaptiveLpVault} from "../src/AdaptiveLpVault.sol";
import {IUniswapV2Router02} from "@uniswap-v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployAdaptiveLpVault is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Define the parameters for the vault deployment
        address token0 = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // WETH
        address token1 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        IUniswapV2Router02 router = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008); // Uniswap V2 Router

        // Deploy the Adaptive LP Vault
        AdaptiveLpVault vault = new AdaptiveLpVault(IERC20(token0), token0, token1, router);

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}