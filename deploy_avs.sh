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
ETHERSCAN_API_KEY=""

# Environment variables for deployment
export AVS_DIRECTORY=""
export STAKE_REGISTRY=""
export REWARDS_COORDINATOR=""
export DELEGATION_MANAGER=""
export ALLOCATION_MANAGER=""
export REGISTRY_COORDINATOR=""
export REWARDS_INITIATOR=""

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
    --etherscan-api-key)
      ETHERSCAN_API_KEY="$2"
      shift 2
      ;;
    --avs-directory)
      export AVS_DIRECTORY="$2"
      shift 2
      ;;
    --stake-registry)
      export STAKE_REGISTRY="$2"
      shift 2
      ;;
    --rewards-coordinator)
      export REWARDS_COORDINATOR="$2"
      shift 2
      ;;
    --delegation-manager)
      export DELEGATION_MANAGER="$2"
      shift 2
      ;;
    --allocation-manager)
      export ALLOCATION_MANAGER="$2"
      shift 2
      ;;
    --registry-coordinator)
      export REGISTRY_COORDINATOR="$2"
      shift 2
      ;;
    --rewards-initiator)
      export REWARDS_INITIATOR="$2"
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
      echo "Usage: ./deploy_avs.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --rpc-url URL                  RPC URL to use for deployment (default: http://localhost:8545)"
      echo "  --private-key KEY              Private key to use for deployment"
      echo "  --broadcast                    Broadcast transactions to the network"
      echo "  --verify                       Verify contracts on Etherscan"
      echo "  --etherscan-api-key KEY        Etherscan API key for verification"
      echo "  --network NETWORK              Use predefined network (local, sepolia, goerli, mainnet, polygon, mumbai, base-sepolia)"
      echo ""
      echo "AVS Contract Parameters:"
      echo "  --avs-directory ADDRESS        Address of the AVS Directory contract"
      echo "  --stake-registry ADDRESS       Address of the Stake Registry contract"
      echo "  --rewards-coordinator ADDRESS  Address of the Rewards Coordinator contract"
      echo "  --delegation-manager ADDRESS   Address of the Delegation Manager contract"
      echo "  --allocation-manager ADDRESS   Address of the Allocation Manager contract"
      echo "  --registry-coordinator ADDRESS Address of the Registry Coordinator contract"
      echo "  --rewards-initiator ADDRESS    Address of the Rewards Initiator"
      echo ""
      echo "  --help                         Show this help message"
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

# Check required parameters
if [[ -z "$AVS_DIRECTORY" && "$BROADCAST" == "true" ]]; then
  echo -e "${YELLOW}Warning: --avs-directory is not set. Using default value.${NC}"
fi

# Build the command
CMD="forge script script/DeployAVS.s.sol --rpc-url $RPC_URL --ffi"

# Add --broadcast flag if requested
if $BROADCAST; then
  CMD="$CMD --broadcast"
fi

# Add verification if requested
if $VERIFY; then
  if [[ -z "$ETHERSCAN_API_KEY" ]]; then
    echo -e "${YELLOW}Warning: Etherscan API key not provided. Contract verification will be skipped.${NC}"
  else
    CMD="$CMD --verify --etherscan-api-key $ETHERSCAN_API_KEY"
  fi
fi

# Print deployment information
echo -e "${GREEN}Deploying AVS to:${NC} $RPC_URL"
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
  if [ -f "avs_deployment_addresses.json" ]; then
    echo -e "${GREEN}AVS contract addresses:${NC}"
    cat avs_deployment_addresses.json
  fi
else
  echo -e "${YELLOW}Deployment failed.${NC}"
  exit 1
fi 