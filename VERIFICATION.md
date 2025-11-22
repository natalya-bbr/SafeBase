# Contract Verification on Basescan

The deployed contracts are currently verified on **Sourcify** but not on **Basescan**. To get the green checkmark on Basescan, follow these steps:

## Prerequisites

Get your Basescan API key:
1. Go to https://basescan.org/myapikey
2. Sign up / Log in
3. Click "Add" to create new API key
4. Copy the API key

## Method 1: Using the verification script (Recommended)

```bash
# Export your API key
export BASESCAN_API_KEY="YOUR_API_KEY_HERE"

# Run the verification script
./verify.sh
```

This will verify both:
- ✅ Treasury Implementation (`0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331`)
- ✅ ERC1967 Proxy (`0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba`)

## Method 2: Manual verification

### Verify Implementation Contract

```bash
forge verify-contract \
  0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331 \
  src/Treasury.sol:Treasury \
  --chain-id 84532 \
  --verifier etherscan \
  --etherscan-api-key YOUR_API_KEY \
  --watch
```

### Verify Proxy Contract

```bash
forge verify-contract \
  0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba \
  lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --chain-id 84532 \
  --verifier etherscan \
  --etherscan-api-key YOUR_API_KEY \
  --constructor-args 0000000000000000000000006f54752a6ea251c88fe07c82d4a0c67f0e1ec33100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000044cd6dc68700000000000000000000000062e8e1a78fd727854fb173cb260ef7a863dff690000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000 \
  --watch
```

## Method 3: Using Basescan Web UI

### For Implementation Contract:

1. Go to https://sepolia.basescan.org/address/0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331#code
2. Click "Verify and Publish"
3. Fill in:
   - **Compiler Type:** Solidity (Single file)
   - **Compiler Version:** v0.8.28+commit.7893614a
   - **Open Source License Type:** MIT
4. Paste the flattened source code (generate with `forge flatten src/Treasury.sol`)
5. Click "Verify and Publish"

### For Proxy Contract:

1. Go to https://sepolia.basescan.org/address/0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba#code
2. Since it's an OpenZeppelin standard proxy, Basescan might auto-detect it
3. If not, click "Verify and Publish" and select "Proxy Contract Verification"

## Verification Status

After successful verification, you'll see:
- ✅ Green checkmark on Basescan
- "Contract Source Code Verified" badge
- Readable contract functions in the "Read Contract" and "Write Contract" tabs

## Troubleshooting

**Error: "Already verified"**
- Contract is already verified on Basescan, nothing to do!

**Error: "Invalid API Key"**
- Check your API key at https://basescan.org/myapikey

**Error: "Compilation failed"**
- Make sure you're using Solidity v0.8.28
- Ensure all dependencies are installed (`forge install`)

## Links

- Base Sepolia Explorer: https://sepolia.basescan.org
- API Documentation: https://docs.basescan.org/
- Sourcify (current verification): https://sourcify.dev/
