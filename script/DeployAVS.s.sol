// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AVS} from "../src/AVS.sol";
import {InstantSlasher} from "@eigenlayer-middleware/src/slashers/InstantSlasher.sol";
import {IAllocationManager} from "@eigenlayer/contracts/interfaces/IAllocationManager.sol";
import {ISlashingRegistryCoordinator} from "@eigenlayer-middleware/src/interfaces/ISlashingRegistryCoordinator.sol";

/**
 * @title DeployAVS
 * @dev Script to deploy AVS and its related contracts
 */
contract DeployAVS is Script {
    event AVSDeployed(address indexed avs, address indexed slasher);

    function run() external {
        // Load environment variables
        //         # Deployment private key (without 0x prefix)
        // PRIVATE_KEY=0xfc5125e9fdc8963c11b341c5d76b9c0aeb90758aa9dbe1e9b8c506581bcaf490

        // # EigenLayer contract addresses
        // AVS_DIRECTORY=0xB8F3221Bf7974F1682d0AcBC2F40ba3597db3151
        // STAKE_REGISTRY=0xE62a528Fa2787B7ba2399506D94D82c98fAFD01a
        // REWARDS_COORDINATOR=0x16A26002119C039DE57b051c8e8871b0AE8f2768
        // DELEGATION_MANAGER=0xff8e53df56550c27bF6A8BAADC839eD86A7c99d7
        // ALLOCATION_MANAGER=0x51FF720105655c01BE501523Dd5C2642ce53FDde
        uint256 deployerPrivateKey = 0xfc5125e9fdc8963c11b341c5d76b9c0aeb90758aa9dbe1e9b8c506581bcaf490;
        address avsDirectory = 0xB8F3221Bf7974F1682d0AcBC2F40ba3597db3151;
        address stakeRegistry = 0xE62a528Fa2787B7ba2399506D94D82c98fAFD01a;
        address rewardsCoordinator = 0x16A26002119C039DE57b051c8e8871b0AE8f2768;
        address delegationManager = 0xff8e53df56550c27bF6A8BAADC839eD86A7c99d7;
        address allocationManager = 0x51FF720105655c01BE501523Dd5C2642ce53FDde;
        address owner = address(this);
        address rewardsInitiator = vm.envOr("REWARDS_INITIATOR", address(this));

        // Log environment variables to verify they are loaded correctly
        console.log("Environment variables loaded:");
        console.log("AVS_DIRECTORY:", avsDirectory);
        console.log("STAKE_REGISTRY:", stakeRegistry);
        console.log("REWARDS_COORDINATOR:", rewardsCoordinator);
        console.log("DELEGATION_MANAGER:", delegationManager);
        console.log("ALLOCATION_MANAGER:", allocationManager);
        console.log("OWNER:", owner);
        console.log("REWARDS_INITIATOR:", rewardsInitiator);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy InstantSlasher with all three required parameters
        InstantSlasher instantSlasher = new InstantSlasher(
            IAllocationManager(allocationManager),
            ISlashingRegistryCoordinator(avsDirectory),
            address(this)
        );
        address slasher = address(instantSlasher);

        // Deploy AVS
        AVS avsContract = new AVS(
            avsDirectory,
            stakeRegistry,
            rewardsCoordinator,
            delegationManager,
            allocationManager
        );
        address avs = address(avsContract);

        // Try to initialize AVS (will fail if already initialized)
        // try avsContract.initialize(owner, rewardsInitiator, slasher) {
        //     console.log("AVS initialized successfully");
        // } catch {
        //     console.log("AVS already initialized or initialization failed");
        // }

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment addresses
        console.log("AVS deployed at:", avs);
        console.log("Slasher deployed at:", slasher);

        // Emit event for tracking deployments
        emit AVSDeployed(avs, slasher);
    }
} 