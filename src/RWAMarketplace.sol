// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
    event LiquidityPoolUpdated(address indexed oldPool, address indexed newPool);
    event FeeTransferred(address indexed recipient, uint256 amount);

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

    address constant IDRX = 0xD63029C1a3dA68b51c67c6D1DeC3DEe50D681661;
    address public PAYMENT_TOKEN_ADDRESS = IDRX;

    function updatePaymentToken(address newPaymentTokenAddress) external onlyOwner {
        PAYMENT_TOKEN_ADDRESS = newPaymentTokenAddress;
    }

    function buyTokens(address tokenAddress, uint256 amount, address paymentTokenAddress) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // Simple check to ensure only the specified payment token is used
        require(paymentTokenAddress == PAYMENT_TOKEN_ADDRESS, "Invalid payment token");
        
        Pool storage pool = pools[tokenAddress];
        require(pool.active, "Pool not active");
        require(pool.totalTokens >= amount, "Not enough tokens in pool");
        
        // Get decimals for both tokens
        uint8 tokenDecimals = IERC20Metadata(tokenAddress).decimals();
        uint8 paymentDecimals = IERC20Metadata(PAYMENT_TOKEN_ADDRESS).decimals();
        
        // Check for precision loss before calculation
        uint256 rawPrice = amount * pool.pricePerToken;
        require(rawPrice >= (10 ** tokenDecimals), "Purchase amount too small for current price");
        
        uint256 totalPrice = rawPrice / (10 ** tokenDecimals);
        require(totalPrice > 0, "Total price must be greater than 0");
        
        // Transfer payment tokens from buyer to this contract
        IERC20 paymentToken = IERC20(PAYMENT_TOKEN_ADDRESS);
        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Payment transfer failed");
        
        // Add revenue to token creator's pending amount
        uint256 revenue = totalPrice * 100 / 100;
        pendingRevenue[pool.tokenCreator] += revenue;
        
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
        
        // Transfer Revenue to creator
        IERC20 token = IERC20(PAYMENT_TOKEN_ADDRESS);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        
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