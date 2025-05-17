// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RWAMarketplace} from "../src/RWAMarketplace.sol";

contract DeployRWAMarketplace is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy RWAMarketplace
        RWAMarketplace rwaMarketplace = new RWAMarketplace();

        console.log("RWAMarketplace deployed at:", address(rwaMarketplace));

        vm.stopBroadcast();
    }
} 