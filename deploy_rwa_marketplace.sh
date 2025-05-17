#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if .env file exists, if not, create based on example
if [ ! -f ".env" ]; then
    if [ -f "deploy.env.example" ]; then
        echo -e "${BLUE}Creating .env file from example...${NC}"
        cp deploy.env.example .env
        echo -e "${GREEN}Created .env file. Please edit it with your configuration and run this script again.${NC}"
        exit 0
    else
        echo -e "${RED}Error: deploy.env.example file not found.${NC}"
        exit 1
    fi
fi

# Load environment variables
source .env

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}     Deploying RWA Marketplace Contract    ${NC}"
echo -e "${BLUE}============================================${NC}"

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable not set in .env file${NC}"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo -e "${RED}Error: RPC_URL environment variable not set in .env file${NC}"
    exit 1
fi

echo -e "${BLUE}Deploying to network: ${NC}$NETWORK"

# Build the project
echo -e "${BLUE}Building project...${NC}"
forge build

# Deploy the contract
echo -e "${BLUE}Deploying RWAMarketplace contract...${NC}"
forge script script/DeployRWAMarketplace.s.sol:DeployRWAMarketplace \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --verify \
    --verifier-url "$VERIFIER_URL" \
    -vvv

echo -e "${GREEN}Deployment completed!${NC}" 