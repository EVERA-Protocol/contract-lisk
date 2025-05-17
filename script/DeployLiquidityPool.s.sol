// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";

contract DeployLiquidityPool is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get the Pool Manager address from environment or use a default for testing
        address poolManagerAddress = vm.envOr("POOL_MANAGER_ADDRESS", address(0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408));
        require(poolManagerAddress != address(0), "Pool Manager address not set");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy LiquidityPool
        LiquidityPool liquidityPool = new LiquidityPool(poolManagerAddress);

        console.log("LiquidityPool deployed at:", address(liquidityPool));

        vm.stopBroadcast();
    }
} 