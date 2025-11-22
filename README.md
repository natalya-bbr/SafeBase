# SafeBase

Upgradeable multi-signature treasury system for Base network with UUPS proxy pattern.

## Features

- ✅ **UUPS Upgradeable Proxy** - Upgrade contracts without changing addresses
- ✅ **Multi-sig Withdrawals** - Request → Approve → Execute workflow
- ✅ **Role-based Access** - Owner, Admins, and Executors
- ✅ **Base Pay Integration** - Ready for USDC disbursements (TreasuryV2)
- ✅ **Battle-tested** - Built with OpenZeppelin upgradeable contracts

## Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone repository
git clone https://github.com/natalya-bbr/SafeBase.git
cd SafeBase

# Install dependencies
forge install
```

### Deploy to Base Sepolia (Testnet)

```bash
# 1. Create .env file
cp .env.example .env

# 2. Edit .env with your values:
#    - PRIVATE_KEY (your wallet private key)
#    - OWNER_ADDRESS (your wallet address)
#    - BASESCAN_API_KEY (get from https://basescan.org/myapikey)

# 3. Deploy with automatic Basescan verification
forge script script/DeployAndInteract.s.sol \
  --rpc-url base-sepolia \
  --broadcast \
  --verify \
  -vvvv
```

### Deploy to Base Mainnet

```bash
forge script script/DeployAndInteract.s.sol \
  --rpc-url base \
  --broadcast \
  --verify \
  -vvvv
```

## Verify Existing Deployment

If you already deployed but contracts aren't verified on Basescan:

```bash
export BASESCAN_API_KEY="your_key_here"
./verify.sh
```

See [VERIFICATION.md](./VERIFICATION.md) for detailed instructions.

## Deployed Contracts

See [DEPLOYMENTS.md](./DEPLOYMENTS.md) for addresses on all networks.

## Architecture

```
┌─────────────────────┐
│   ERC1967Proxy      │  ← User interacts here
│  (Treasury Address) │
└──────────┬──────────┘
           │ delegatecall
           ▼
┌─────────────────────┐
│   Treasury (v1)     │  ← Implementation
│   - Multi-sig       │
│   - Withdrawals     │
└─────────────────────┘
           │ upgradeable to
           ▼
┌─────────────────────┐
│   TreasuryV2        │  ← Future upgrade
│   + Base Pay        │
└─────────────────────┘
```

## Usage

### Request Withdrawal

```solidity
// Admin creates withdrawal request
uint256 requestId = treasury.requestWithdrawal(
    tokenAddress,  // ERC20 token or address(0) for ETH
    recipient,
    amount
);
```

### Approve Withdrawal

```solidity
// Other admins approve
treasury.approveWithdrawal(requestId);
```

### Execute Withdrawal

```solidity
// Executor executes when enough approvals
treasury.executeWithdrawal(requestId);
```

### Upgrade Contract

```bash
forge script script/Upgrade.s.sol \
  --rpc-url base-sepolia \
  --broadcast
```

## Configuration Management

```bash
# View current config
forge script script/ConfigManager.s.sol \
  --rpc-url base-sepolia

# Add admin
ACTION=add-admin ADMIN_ADDRESS=0x... \
forge script script/ConfigManager.s.sol \
  --rpc-url base-sepolia \
  --broadcast

# Change required approvals
ACTION=set-approvals NEW_APPROVALS=3 \
forge script script/ConfigManager.s.sol \
  --rpc-url base-sepolia \
  --broadcast
```

## Development

```bash
# Build
forge build

# Test
forge test

# Gas report
forge test --gas-report

# Format
forge fmt
```

## Security

- Built with OpenZeppelin v5.5.0 upgradeable contracts
- UUPS proxy pattern prevents unauthorized upgrades
- Multi-signature approval system
- Role-based access control

⚠️ **Audits**: This code has NOT been audited. Use at your own risk.

## License

MIT

## Links

- [Base Network](https://base.org)
- [Basescan](https://basescan.org)
- [OpenZeppelin](https://www.openzeppelin.com/)
- [Foundry](https://getfoundry.sh)
