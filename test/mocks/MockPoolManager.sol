// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

/**
 * @title MockPoolManager
 * @dev Mock implementation of IPoolManager for testing purposes.
 */
contract MockPoolManager {
    bool public poolInitialized;
    bool public liquidityAdded;
    uint256 public lastAmount0;
    uint256 public lastAmount1;
    
    /**
     * @dev Mocks the initialize function of IPoolManager
     */
    function initialize(PoolKey calldata key, uint160 sqrtPriceX96) external returns (int24 tick) {
        poolInitialized = true;
        // Return a mock tick value
        return 0;
    }
    
    /**
     * @dev Mocks the addLiquidity function of IPoolManager
     */
    function addLiquidity(
        PoolKey calldata key,
        Currency currency0,
        Currency currency1,
        uint256 amount0,
        uint256 amount1
    ) external {
        liquidityAdded = true;
        lastAmount0 = amount0;
        lastAmount1 = amount1;
    }
    
    /**
     * @dev Mocks receiving ETH
     */
    receive() external payable {}
} 