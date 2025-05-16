// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./RWAToken.sol";
import "./interfaces/IRWALaunchpad.sol";
import "./libraries/RWAConstants.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./LiquidityPool.sol";

/**
 * @title RWALaunchpad
 * @notice Factory contract for creating and launching RWA tokens
 * @dev Implements IRWALaunchpad interface
 */
contract RWALaunchpad is Ownable(msg.sender), ReentrancyGuard, IRWALaunchpad {
    address[] private _allRWATokens;

    // Mapping from creator address to their created tokens
    mapping(address => address[]) private _creatorToTokens;

    /**
     * @notice Creates a new RWA token
     * @param name Token name
     * @param symbol Token symbol
     * @param institutionName Name of the issuing institution
     * @param institutionAddress Address of the issuing institution
     * @param documentURI IPFS URI for supporting documents
     * @param imageURI IPFS URI for RWA image
     * @param totalRWASupply Total supply of RWA tokens
     * @param pricePerRWA Initial price per RWA token
     * @param description Brief description of the RWA
     * @return tokenAddress Address of the newly created RWA token
     */
    function createRWAToken(
        string memory name,
        string memory symbol,
        string memory institutionName,
        string memory institutionAddress,
        string memory documentURI,
        string memory imageURI,
        uint256 totalRWASupply,
        uint256 pricePerRWA,
        string memory description
    ) external nonReentrant returns (address tokenAddress) {
        // Validate inputs
        if (
            bytes(name).length == 0 ||
            bytes(name).length > RWAConstants.MAX_NAME_LENGTH
        ) {
            revert RWAConstants.EmptyString();
        }
        if (
            bytes(symbol).length == 0 ||
            bytes(symbol).length > RWAConstants.MAX_SYMBOL_LENGTH
        ) {
            revert RWAConstants.EmptyString();
        }
        if (bytes(institutionName).length == 0) {
            revert RWAConstants.EmptyString();
        }
        if (bytes(institutionAddress).length == 0) {
            revert RWAConstants.EmptyString();
        }
        if (totalRWASupply == 0) {
            revert RWAConstants.InvalidAmount();
        }
        if (pricePerRWA == 0) {
            revert RWAConstants.InvalidAmount();
        }

        // Create new RWA token with the creator as the owner
        RWAToken newToken = new RWAToken(
            name,
            symbol,
            institutionName,
            institutionAddress,
            documentURI,
            imageURI,
            totalRWASupply,
            pricePerRWA,
            description,
            msg.sender
        );

        tokenAddress = address(newToken);

        // Store the token address
        _allRWATokens.push(tokenAddress);
        _creatorToTokens[msg.sender].push(tokenAddress);

        // create new empty pool for the token
        LiquidityPool(uniswapPool).createPool(tokenAddress, 0, 0);

        emit RWATokenCreated(
            msg.sender,
            tokenAddress,
            name,
            symbol,
            totalRWASupply,
            pricePerRWA
        );

        return tokenAddress;
    }

    /**
     * @notice Returns all RWA tokens created by a specific address
     * @param creator Address of the creator
     * @return Array of token addresses created by the creator
     */
    function getTokensByCreator(
        address creator
    ) external view returns (address[] memory) {
        return _creatorToTokens[creator];
    }

    /**
     * @notice Returns all RWA tokens created through this launchpad
     * @return Array of all token addresses
     */
    function getAllTokens() external view returns (address[] memory) {
        return _allRWATokens;
    }

    /**
     * @notice Returns the total number of RWA tokens created
     * @return Total number of tokens
     */
    function getTotalTokensCount() external view returns (uint256) {
        return _allRWATokens.length;
    }

    /**
     * @notice Returns a specific RWA token by index
     * @param index Index of the token in the array
     * @return Token address
     */
    function getRWATokenAtIndex(uint256 index) external view returns (address) {
        if (index >= _allRWATokens.length) {
            revert RWAConstants.InvalidAmount();
        }
        return _allRWATokens[index];
    }

    /**
     * @notice Returns a specific RWA token created by a creator by index
     * @param creator Address of the creator
     * @param index Index of the token in the creator's array
     * @return Token address
     */
    function getCreatorTokenAtIndex(
        address creator,
        uint256 index
    ) external view returns (address) {
        if (index >= _creatorToTokens[creator].length) {
            revert RWAConstants.InvalidAmount();
        }
        return _creatorToTokens[creator][index];
    }
}
