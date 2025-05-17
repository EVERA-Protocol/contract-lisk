// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {LiquidityPool} from "../src/LiquidityPool.sol";
// import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
// import {PoolKey} from "v4-core/src/types/PoolKey.sol";
// import {Currency} from "v4-core/src/types/Currency.sol";
// import {CurrencyLibrary} from "v4-core/src/types/Currency.sol";
// import {MockERC20} from "./mocks/MockERC20.sol";
// import {MockPoolManager} from "./mocks/MockPoolManager.sol";

// contract LiquidityPoolTest is Test {
//     using CurrencyLibrary for Currency;

//     LiquidityPool public liquidityPool;
//     MockPoolManager public poolManager;
//     MockERC20 public token0;
//     MockERC20 public token1;
    
//     // Test accounts
//     address public owner = address(0x1);
//     address public user1 = address(0x2);
//     address public user2 = address(0x3);

//     // Pool parameters
//     uint24 public fee = 3000; // 0.3%
//     int24 public tickSpacing = 60;
//     address public hooks = address(0);
//     uint160 public startingPrice = 79228162514264337593543950336; // 1.0 in Q96

//     function setUp() public {
//         vm.startPrank(owner);
        
//         // Deploy mock tokens
//         token0 = new MockERC20("Token0", "TK0", 18);
//         token1 = new MockERC20("Token1", "TK1", 18);
        
//         // Ensure token0 < token1 by address
//         if (address(token0) > address(token1)) {
//             (token0, token1) = (token1, token0);
//         }
        
//         // Deploy mock pool manager
//         poolManager = new MockPoolManager();
        
//         // Deploy liquidity pool
//         liquidityPool = new LiquidityPool(address(poolManager));
        
//         vm.stopPrank();
//     }

//     function testConstructor() public {
//         assertEq(address(liquidityPool.poolManager()), address(poolManager));
//     }

//     function testCreatePool() public {
//         vm.startPrank(user1);
        
//         Currency currency0 = Currency.wrap(address(token0));
//         Currency currency1 = Currency.wrap(address(token1));
        
//         // Create pool
//         PoolKey memory pool = liquidityPool.createPool(
//             currency0,
//             currency1,
//             fee,
//             tickSpacing,
//             hooks,
//             startingPrice
//         );
        
//         // Verify pool key elements
//         assertEq(address(pool.currency0), address(token0));
//         assertEq(address(pool.currency1), address(token1));
//         assertEq(pool.fee, fee);
//         assertEq(pool.tickSpacing, tickSpacing);
//         assertEq(pool.hooks, hooks);
        
//         // Verify pool initialization was called on the pool manager
//         assertTrue(poolManager.poolInitialized());
        
//         vm.stopPrank();
//     }
    
//     function testCreatePoolFailsWithUnsortedTokens() public {
//         vm.startPrank(user1);
        
//         // Deliberately use unsorted order
//         Currency currency0 = Currency.wrap(address(token1)); // Higher address
//         Currency currency1 = Currency.wrap(address(token0)); // Lower address
        
//         // Should revert
//         vm.expectRevert("Currencies not sorted");
//         liquidityPool.createPool(
//             currency0,
//             currency1,
//             fee,
//             tickSpacing,
//             hooks,
//             startingPrice
//         );
        
//         vm.stopPrank();
//     }

//     function testAddLiquidity() public {
//         vm.startPrank(user1);
        
//         Currency currency0 = Currency.wrap(address(token0));
//         Currency currency1 = Currency.wrap(address(token1));
        
//         // Create pool first
//         PoolKey memory pool = liquidityPool.createPool(
//             currency0,
//             currency1,
//             fee,
//             tickSpacing,
//             hooks,
//             startingPrice
//         );
        
//         // Add liquidity
//         uint256 amount0 = 1000 * 10**18;
//         uint256 amount1 = 1000 * 10**18;
        
//         liquidityPool.addLiquidity(
//             pool,
//             currency0,
//             currency1,
//             amount0,
//             amount1
//         );
        
//         // Verify add liquidity was called on the pool manager
//         assertTrue(poolManager.liquidityAdded());
//         assertEq(poolManager.lastAmount0(), amount0);
//         assertEq(poolManager.lastAmount1(), amount1);
        
//         vm.stopPrank();
//     }
// } 