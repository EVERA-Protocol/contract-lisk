// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import {RWAMarketplace} from "../src/RWAMarketplace.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// // Mock RWA Token for testing purposes
// contract MockRWAToken is ERC20 {
//     constructor() ERC20("Mock RWA Token", "MRWA") {
//         _mint(msg.sender, 1000000 * 10 ** decimals());
//     }
// }

// contract RWAMarketplaceTest is Test {
//     RWAMarketplace public marketplace;
//     MockRWAToken public rwaToken;
    
//     address public admin = address(1);
//     address public tokenCreator = address(2);
//     address public otherUser = address(3);
//     address public buyer = address(4);
    
//     uint256 public constant TOKEN_AMOUNT = 100 * 10**18;
//     uint256 public constant PRICE_PER_TOKEN = 0.01 ether;
    
//     function setUp() public {
//         // Deploy marketplace with admin as owner
//         vm.prank(admin);
//         marketplace = new RWAMarketplace();
        
//         // Deploy token with tokenCreator as the creator
//         vm.startPrank(tokenCreator);
//         rwaToken = new MockRWAToken();
        
//         // Transfer some tokens to otherUser for testing non-creator interactions
//         rwaToken.transfer(otherUser, TOKEN_AMOUNT);
//         vm.stopPrank();
//     }
    
//     function testAddTokensToPool() public {
//         // Token creator adds tokens
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         // Verify pool details
//         (uint256 totalTokens, uint256 price, bool active, address creator) = marketplace.getPoolDetails(address(rwaToken));
        
//         assertEq(totalTokens, TOKEN_AMOUNT);
//         assertEq(price, PRICE_PER_TOKEN);
//         assertTrue(active);
//         assertEq(creator, tokenCreator);
        
//         // Verify creator status
//         vm.prank(tokenCreator);
//         assertTrue(marketplace.isTokenCreator(address(rwaToken)));
//     }
    
//     function testNonCreatorCannotAddTokens() public {
//         // First, creator establishes the pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT / 2);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT / 2, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         // Non-creator tries to add tokens
//         vm.startPrank(otherUser);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
        
//         // Should revert with the correct message
//         vm.expectRevert("Only token creator can add tokens");
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
//     }
    
//     function testRemoveTokensFromPool() public {
//         // Calculate initial balance (after transfer to otherUser in setUp)
//         uint256 initialCreatorBalance = 1000000 * 10**18 - TOKEN_AMOUNT;
        
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
        
//         uint256 amountToRemove = TOKEN_AMOUNT / 2;
        
//         // Creator removes tokens
//         marketplace.removeTokensFromPool(address(rwaToken), amountToRemove);
//         vm.stopPrank();
        
//         // Verify pool details
//         (uint256 totalTokens, , bool active, ) = marketplace.getPoolDetails(address(rwaToken));
//         assertEq(totalTokens, TOKEN_AMOUNT - amountToRemove);
//         assertTrue(active);
        
//         // Verify tokens returned to creator
//         assertEq(rwaToken.balanceOf(tokenCreator), initialCreatorBalance - TOKEN_AMOUNT + amountToRemove);
//     }
    
//     function testNonCreatorCannotRemoveTokens() public {
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         // Non-creator tries to remove tokens
//         vm.prank(otherUser);
//         vm.expectRevert("Only token creator can remove tokens");
//         marketplace.removeTokensFromPool(address(rwaToken), TOKEN_AMOUNT / 2);
//     }
    
//     function testUpdatePoolPrice() public {
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
        
//         uint256 newPrice = PRICE_PER_TOKEN * 2;
        
//         // Creator updates price
//         marketplace.updatePoolPrice(address(rwaToken), newPrice);
//         vm.stopPrank();
        
//         // Verify updated price
//         (, uint256 price, , ) = marketplace.getPoolDetails(address(rwaToken));
//         assertEq(price, newPrice);
//     }
    
//     function testNonCreatorCannotUpdatePrice() public {
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         // Non-creator tries to update price
//         vm.prank(otherUser);
//         vm.expectRevert("Only token creator can update price");
//         marketplace.updatePoolPrice(address(rwaToken), PRICE_PER_TOKEN * 2);
//     }
    
//     function testBuyTokens() public {
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         uint256 buyAmount = TOKEN_AMOUNT / 2;
//         uint256 totalPrice = buyAmount * PRICE_PER_TOKEN;
        
//         // Buyer purchases tokens
//         vm.deal(buyer, totalPrice); // Give buyer exactly the right amount of ETH
//         vm.prank(buyer);
//         marketplace.buyTokens{value: totalPrice}(address(rwaToken), buyAmount);
        
//         // Verify buyer received tokens
//         assertEq(rwaToken.balanceOf(buyer), buyAmount);
        
//         // Verify pool details
//         (uint256 remainingTokens, , bool active, ) = marketplace.getPoolDetails(address(rwaToken));
//         assertEq(remainingTokens, TOKEN_AMOUNT - buyAmount);
//         assertTrue(active);
        
//         // Verify creator has pending revenue
//         assertEq(marketplace.pendingRevenue(tokenCreator), totalPrice);
//     }
    
//     function testClaimRevenue() public {
//         // Setup: Creator adds tokens and buyer purchases
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         uint256 buyAmount = TOKEN_AMOUNT;
//         uint256 totalPrice = buyAmount * PRICE_PER_TOKEN;
        
//         vm.deal(buyer, totalPrice);
//         vm.prank(buyer);
//         marketplace.buyTokens{value: totalPrice}(address(rwaToken), buyAmount);
        
//         // Track creator's balance before claiming
//         uint256 creatorBalanceBefore = address(tokenCreator).balance;
        
//         // Creator claims revenue
//         vm.prank(tokenCreator);
//         marketplace.claimRevenue();
        
//         // Verify creator received funds
//         assertEq(address(tokenCreator).balance - creatorBalanceBefore, totalPrice);
        
//         // Verify pending revenue is cleared
//         assertEq(marketplace.pendingRevenue(tokenCreator), 0);
//     }
    
//     function testNonCreatorCannotClaimRevenue() public {
//         // Setup: Creator adds tokens and buyer purchases
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         uint256 totalPrice = TOKEN_AMOUNT * PRICE_PER_TOKEN;
//         vm.deal(buyer, totalPrice);
//         vm.prank(buyer);
//         marketplace.buyTokens{value: totalPrice}(address(rwaToken), TOKEN_AMOUNT);
        
//         // Non-creator tries to claim revenue (will revert with "No revenue to claim")
//         vm.prank(otherUser);
//         vm.expectRevert("No revenue to claim");
//         marketplace.claimRevenue();
//     }
    
//     function testEmptyPool() public {
//         // Setup: Creator adds tokens to pool
//         vm.startPrank(tokenCreator);
//         rwaToken.approve(address(marketplace), TOKEN_AMOUNT);
//         marketplace.addTokensToPool(address(rwaToken), TOKEN_AMOUNT, PRICE_PER_TOKEN);
//         vm.stopPrank();
        
//         // Buy all tokens
//         uint256 totalPrice = TOKEN_AMOUNT * PRICE_PER_TOKEN;
//         vm.deal(buyer, totalPrice);
//         vm.prank(buyer);
//         marketplace.buyTokens{value: totalPrice}(address(rwaToken), TOKEN_AMOUNT);
        
//         // Verify pool is empty and inactive
//         (uint256 remainingTokens, , bool active, ) = marketplace.getPoolDetails(address(rwaToken));
//         assertEq(remainingTokens, 0);
//         assertFalse(active);
//     }
// }