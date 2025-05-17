// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

contract LiquidityPool {
    IPoolManager public immutable poolManager;

    // save pool key by token address
    mapping(address => PoolKey) public poolKeys;

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }

    function createPool(
        address currency1,
        uint24 fee,
        int24 tickSpacing,
        address hooks,
        uint160 startingPrice
    ) external returns (PoolKey memory pool) {
        // Ensure currencies are sorted
        require(CurrencyLibrary.ADDRESS_ZERO == Currency.wrap(currency1), "Currencies not sorted");

        // Create the pool key
        pool = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO,
            currency1: Currency.wrap(currency1),
            fee: fee,
            tickSpacing: tickSpacing,
            hooks: IHooks(hooks)
        });

        // save pool key by token address
        poolKeys[address(currency1)] = pool;

        // Initialize the pool with the starting price
        poolManager.initialize(pool, startingPrice);
    }

    function getPoolKey(address tokenAddress) external view returns (PoolKey memory pool) {
        return poolKeys[tokenAddress];
    }

    function addLiquidity(
        address currency1,
        uint256 amount1
    ) external {

        // // Set the recipient to the caller
        // address recipient = msg.sender;
        
        // // Optional hook data, empty in this simple example
        // bytes memory hookData = "";

        // // Prepare actions for minting a position
        // bytes memory actions = abi.encodePacked(
        //     Actions.MINT_POSITION,
        //     abi.encode(poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, recipient, hookData),
        //     Actions.SETTLE_PAIR,
        //     abi.encode(token0, token1)
        // );
        
        // uint256 deadline = block.timestamp + 1000;
        // posm.modifyLiquidities(actions, deadline);
        // Currency currency0 = CurrencyLibrary.ADDRESS_ZERO;
        // poolManager.addLiquidity(poolKeys[currency1], CurrencyLibrary.ADDRESS_ZERO, Currency.wrap(currency1), amount1, 0);
    }
}
