#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RPC_URL="http://localhost:8545"
PRIVATE_KEY=""
BROADCAST=false
VERIFY=false
VERIFIER_URL=""

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
    --verify)
      VERIFY=true
      shift
      ;;
    --verifier-url)
      VERIFIER_URL="$2"
      shift 2
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
           RPC_URL="https://base-sepolia.drpc.org"
          ;;
        lisk-sepolia)
           RPC_URL="https://rpc.sepolia-api.lisk.com"
           export CHAIN_ID=4202
          ;;
        *)
          echo "Unknown network: $2"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --help)
      echo "Usage: ./deploy.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rpc-url URL       RPC URL to use for deployment (default: http://localhost:8545)"
      echo "  --private-key KEY   Private key to use for deployment"
      echo "  --broadcast         Broadcast transactions to the network"
      echo "  --verify            Verify contracts on the block explorer"
      echo "  --verifier-url URL  URL for the contract verification service"
      echo "  --network NETWORK   Use predefined network (local, sepolia, goerli, mainnet, polygon, mumbai, base-sepolia, lisk-sepolia)"
      echo "  --help              Show this help message"
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

# Build the command
CMD="forge script script/DeployAll.s.sol --rpc-url $RPC_URL --ffi"

# Add --broadcast flag if requested
if $BROADCAST; then
  CMD="$CMD --broadcast"
fi

# Add --verify flag if requested
if $VERIFY; then
  CMD="$CMD --verify"
  
  # Add verifier URL if provided
  if [[ -n "$VERIFIER_URL" ]]; then
    CMD="$CMD --verifier-url $VERIFIER_URL"
  fi
fi

# Add chain ID if set
if [[ -n "$CHAIN_ID" ]]; then
  CMD="$CMD --chain-id $CHAIN_ID"
fi

# Print deployment information
echo -e "${GREEN}Deploying contracts to:${NC} $RPC_URL"
if [[ -n "$CHAIN_ID" ]]; then
  echo -e "${GREEN}Chain ID:${NC} $CHAIN_ID"
fi
if $BROADCAST; then
  echo -e "${YELLOW}Transactions will be broadcast to the network${NC}"
else
  echo -e "${YELLOW}Dry run mode (use --broadcast to send transactions)${NC}"
fi
if $VERIFY; then
  echo -e "${YELLOW}Contracts will be verified after deployment${NC}"
  if [[ -n "$VERIFIER_URL" ]]; then
    echo -e "${YELLOW}Using verifier URL:${NC} $VERIFIER_URL"
  fi
fi

# Run the deployment script
echo -e "${GREEN}Running deployment script...${NC}"
eval $CMD

# Check if deployment was successful
# if [ $? -eq 0 ]; then
#   echo -e "${GREEN}Deployment completed successfully!${NC}"
  
#   # Check if addresses file exists
#   if [ -f "deployed_addresses.json" ]; then
#     echo -e "${GREEN}Deployed addresses:${NC}"
#     cat deployed_addresses.json
#   fi
# else
#   echo -e "${YELLOW}Deployment failed.${NC}"
#   exit 1
# fi
