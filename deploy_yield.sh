#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RPC_URL="http://localhost:8545"
PRIVATE_KEY=""
BROADCAST=false
SCRIPT="DeployYieldSystemWithToken.s.sol"
TOKEN_ADDRESS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --rpc-url)
      RPC_URL="$2"
      shift 2
      ;;
    --private-key)
      PRIVATE_KEY="$2"
      shift 2
      ;;
    --broadcast)
      BROADCAST=true
      shift
      ;;
    --token-address)
      TOKEN_ADDRESS="$2"
      SCRIPT="DeployYieldSystem.s.sol"
      shift 2
      ;;
    --with-token)
      SCRIPT="DeployYieldSystemWithToken.s.sol"
      shift
      ;;
    --network)
      case "$2" in
        local)
          RPC_URL="http://localhost:8545"
          ;;
        sepolia)
          RPC_URL="https://sepolia.infura.io/v3/${INFURA_API_KEY}"
          ;;
        goerli)
          RPC_URL="https://goerli.infura.io/v3/${INFURA_API_KEY}"
          ;;
        mainnet)
          RPC_URL="https://mainnet.infura.io/v3/${INFURA_API_KEY}"
          ;;
        polygon)
          RPC_URL="https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}"
          ;;
        mumbai)
          RPC_URL="https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}"
          ;;
        base-sepolia)
          RPC_URL="https://sepolia.base.org"
          ;;
        lisk-sepolia)
           RPC_URL="https://rpc.sepolia-api.lisk.com"
          ;;
        *)
          echo "Unknown network: $2"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --help)
      echo "Usage: ./deploy_yield.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rpc-url URL         RPC URL to use for deployment (default: http://localhost:8545)"
      echo "  --private-key KEY     Private key to use for deployment"
      echo "  --broadcast           Broadcast transactions to the network"
      echo "  --network NETWORK     Use predefined network (local, sepolia, goerli, mainnet, polygon, mumbai, base-sepolia)"
      echo "  --token-address ADDR  Address of an existing token to use with YieldDistributionSystem"
      echo "  --with-token          Deploy both a test token and YieldDistributionSystem (default)"
      echo "  --help                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if INFURA_API_KEY is set when using a public network
if [[ $RPC_URL == *"infura.io"* && -z "${INFURA_API_KEY}" ]]; then
  echo -e "${YELLOW}Warning: INFURA_API_KEY environment variable is not set.${NC}"
  echo -e "${YELLOW}Set it with: export INFURA_API_KEY=your_infura_api_key${NC}"
  exit 1
fi

# Set PRIVATE_KEY environment variable if provided
if [[ -n "$PRIVATE_KEY" ]]; then
  export PRIVATE_KEY
fi

# Set TOKEN_ADDRESS environment variable if provided
if [[ -n "$TOKEN_ADDRESS" ]]; then
  export TOKEN_ADDRESS
fi

# Build the command
CMD="forge script script/$SCRIPT --rpc-url $RPC_URL --ffi"

# Add --broadcast flag if requested
if $BROADCAST; then
  CMD="$CMD --broadcast"
fi

# Print deployment information
echo -e "${GREEN}Deploying YieldDistributionSystem to:${NC} $RPC_URL"
if [[ "$SCRIPT" == "DeployYieldSystemWithToken.s.sol" ]]; then
  echo -e "${GREEN}Deploying with a new test token${NC}"
else
  echo -e "${GREEN}Using existing token at:${NC} $TOKEN_ADDRESS"
fi

if $BROADCAST; then
  echo -e "${YELLOW}Transactions will be broadcast to the network${NC}"
else
  echo -e "${YELLOW}Dry run mode (use --broadcast to send transactions)${NC}"
fi

# Run the deployment script
echo -e "${GREEN}Running deployment script...${NC}"
eval $CMD

# Check if deployment was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Deployment completed successfully!${NC}"
  
  # Check if addresses file exists
  if [[ "$SCRIPT" == "DeployYieldSystemWithToken.s.sol" && -f "yield_system_with_token_addresses.json" ]]; then
    echo -e "${GREEN}Deployed addresses:${NC}"
    cat yield_system_with_token_addresses.json
  elif [[ "$SCRIPT" == "DeployYieldSystem.s.sol" && -f "yield_system_addresses.json" ]]; then
    echo -e "${GREEN}Deployed addresses:${NC}"
    cat yield_system_addresses.json
  fi
else
  echo -e "${YELLOW}Deployment failed.${NC}"
  exit 1
fi 