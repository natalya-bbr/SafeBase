#!/bin/bash

# Verify SafeBase Treasury contracts on Basescan

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contract addresses (Base Sepolia deployment)
IMPLEMENTATION="0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331"
PROXY="0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba"
CHAIN_ID="84532"

# Check for BASESCAN_API_KEY
if [ -z "$BASESCAN_API_KEY" ]; then
    echo -e "${YELLOW}Error: BASESCAN_API_KEY not set${NC}"
    echo "Get your API key from: https://basescan.org/myapikey"
    echo "Then run: export BASESCAN_API_KEY='your_key_here'"
    exit 1
fi

echo -e "${GREEN}=== Verifying SafeBase Contracts on Basescan ===${NC}\n"

# Verify Treasury Implementation
echo -e "${YELLOW}[1/2] Verifying Treasury Implementation...${NC}"
forge verify-contract \
  $IMPLEMENTATION \
  src/Treasury.sol:Treasury \
  --chain-id $CHAIN_ID \
  --verifier etherscan \
  --etherscan-api-key $BASESCAN_API_KEY \
  --watch

echo ""

# Verify ERC1967Proxy
echo -e "${YELLOW}[2/2] Verifying ERC1967 Proxy...${NC}"

# Constructor args for proxy: implementation address + initialization data
CONSTRUCTOR_ARGS="0000000000000000000000006f54752a6ea251c88fe07c82d4a0c67f0e1ec33100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000044cd6dc68700000000000000000000000062e8e1a78fd727854fb173cb260ef7a863dff690000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000"

forge verify-contract \
  $PROXY \
  lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --chain-id $CHAIN_ID \
  --verifier etherscan \
  --etherscan-api-key $BASESCAN_API_KEY \
  --constructor-args $CONSTRUCTOR_ARGS \
  --watch

echo ""
echo -e "${GREEN}=== Verification Complete ===${NC}"
echo -e "View on Basescan:"
echo -e "  Implementation: https://sepolia.basescan.org/address/$IMPLEMENTATION#code"
echo -e "  Proxy: https://sepolia.basescan.org/address/$PROXY#code"
