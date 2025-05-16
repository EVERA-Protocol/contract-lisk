// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LiquidityPool} from "./LiquidityPool.sol";

/**
 * @title RWAMarketplace
 * @dev A pool-based marketplace for RWA tokens where only the token creator can manage listings
 */
contract RWAMarketplace is Ownable, ReentrancyGuard {
    // Pool structure
    struct Pool {
        uint256 totalTokens;
        uint256 pricePerToken;
        bool active;
        address tokenCreator; // Track the creator of each token pool
    }

    // Storage
    mapping(address => Pool) public pools;
    mapping(address => uint256) public pendingRevenue;

    // Events
    event TokensAddedToPool(address indexed tokenAddress, uint256 amount, uint256 pricePerToken);
    event TokensRemovedFromPool(address indexed tokenAddress, uint256 amount);
    event TokensPurchased(address indexed tokenAddress, address indexed buyer, uint256 amount, uint256 totalPrice);
    event RevenueClaimed(address indexed tokenCreator, uint256 amount);
    event PoolPriceUpdated(address indexed tokenAddress, uint256 newPricePerToken);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add tokens to the pool - only token creator can do this
     * @param tokenAddress The address of the token being sold
     * @param amount The amount of tokens to add
     * @param pricePerToken The price in ETH per token unit
     */
    function addTokensToPool(address tokenAddress, uint256 amount, uint256 pricePerToken) external {
        require(amount > 0, "Amount must be greater than 0");
        require(pricePerToken > 0, "Price must be greater than 0");

        Pool storage pool = pools[tokenAddress];
        
        // If pool doesn't exist, create it and set the caller as the token creator
        if (!pool.active) {
            pool.active = true;
            pool.pricePerToken = pricePerToken;
            pool.tokenCreator = msg.sender;
        } else {
            // If pool exists, ensure caller is the token creator
            require(msg.sender == pool.tokenCreator, "Only token creator can add tokens");
            
            // If price is different, update it
            if (pool.pricePerToken != pricePerToken) {
                pool.pricePerToken = pricePerToken;
                emit PoolPriceUpdated(tokenAddress, pricePerToken);
            }
        }

        // Transfer tokens from creator to contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Update pool total
        pool.totalTokens += amount;
        
        emit TokensAddedToPool(tokenAddress, amount, pricePerToken);
    }

    /**
     * @dev Remove tokens from the pool - only token creator can do this
     * @param tokenAddress The address of the token
     * @param amount The amount of tokens to remove
     */
    function removeTokensFromPool(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        Pool storage pool = pools[tokenAddress];
        require(pool.active, "Pool not active");
        require(msg.sender == pool.tokenCreator, "Only token creator can remove tokens");
        require(pool.totalTokens >= amount, "Insufficient tokens in pool");
        
        // Update total tokens
        pool.totalTokens -= amount;
        
        // If pool is empty, mark as inactive
        if (pool.totalTokens == 0) {
            pool.active = false;
        }
        
        // Return tokens to creator
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        
        emit TokensRemovedFromPool(tokenAddress, amount);
    }

    /**
     * @dev Update the price per token for a pool - only token creator can do this
     * @param tokenAddress The address of the token
     * @param newPricePerToken The new price per token
     */
    function updatePoolPrice(address tokenAddress, uint256 newPricePerToken) external {
        require(newPricePerToken > 0, "Price must be greater than 0");
        
        Pool storage pool = pools[tokenAddress];
        require(pool.active, "Pool not active");
        require(msg.sender == pool.tokenCreator, "Only token creator can update price");
        
        pool.pricePerToken = newPricePerToken;
        
        emit PoolPriceUpdated(tokenAddress, newPricePerToken);
    }

    /**
     * @dev Buy tokens from the pool - anyone can buy
     * @param tokenAddress The address of the token to buy
     * @param amount The amount of tokens to buy
     */
    function buyTokens(address tokenAddress, uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        Pool storage pool = pools[tokenAddress];
        require(pool.active, "Pool not active");
        require(pool.totalTokens >= amount, "Not enough tokens in pool");
        
        // Calculate total price
        uint256 totalPrice = amount * pool.pricePerToken;
        require(msg.value == totalPrice, "Incorrect payment amount");
        
        // Add revenue to token creator's pending amount
        // totalPrice should be reduced to 80% of the price
        // 20% goes to the uniswap pool
        uint256 revenue = totalPrice * 80 / 100;
        pendingRevenue[pool.tokenCreator] += revenue;

        uint256 uniswapLiquidity = totalPrice * 20 / 100;
        // call the uniswap pool to add liquidity from LiquidityPool contract
        LiquidityPool(uniswapPool).addLiquidity(tokenAddress, uniswapLiquidity);

        // Update pool
        pool.totalTokens -= amount;
        if (pool.totalTokens == 0) {
            pool.active = false;
        }
        
        // Transfer tokens to buyer
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        
        emit TokensPurchased(tokenAddress, msg.sender, amount, totalPrice);
    }

    /**
     * @dev Claim pending revenue - only token creators can claim their revenue
     */
    function claimRevenue() external nonReentrant {
        uint256 amount = pendingRevenue[msg.sender];
        require(amount > 0, "No revenue to claim");
        
        // Reset pending revenue
        pendingRevenue[msg.sender] = 0;
        
        // Transfer ETH to creator
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit RevenueClaimed(msg.sender, amount);
    }

    /**
    * @dev Get pool details
    * @param tokenAddress The token address
    * @return totalTokens The total tokens available in the pool
    * @return pricePerToken The price per token in ETH
    * @return active Whether the pool is active
    * @return tokenCreator The address of the token creator
    */
    function getPoolDetails(address tokenAddress) external view returns (
        uint256 totalTokens,
        uint256 pricePerToken,
        bool active,
        address tokenCreator
    ) {
        Pool memory pool = pools[tokenAddress];
        return (
            pool.totalTokens,
            pool.pricePerToken,
            pool.active,
            pool.tokenCreator
        );
    }
    
    /**
     * @dev Check if caller is the creator of a token pool
     * @param tokenAddress The token address
     * @return True if caller is the token creator
     */
    function isTokenCreator(address tokenAddress) external view returns (bool) {
        return pools[tokenAddress].tokenCreator == msg.sender;
    }
}