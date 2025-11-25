# SafeBase

Modular, upgradeable escrow and conditional payment protocol for Base L2 with UUPS proxy pattern.

## Features

- ✅ **UUPS Upgradeable Proxy** - Upgrade contracts without changing addresses
- ✅ **Multi-party Escrow** - Buyer + Seller + Mediator workflow with 6-state machine
- ✅ **Programmable Rules Engine** - Conditional release logic with external verification
- ✅ **Automated Execution** - Deadline-based auto-refund and auto-release
- ✅ **Treasury Integration** - Multi-sig treasury for custody management
- ✅ **Base Pay Bridge** - Offchain/onchain payment integration
- ✅ **Indexing & Discovery** - Registry for escrow tracking and queries
- ✅ **Battle-tested** - Built with OpenZeppelin v5.5.0 upgradeable contracts

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

**Note:** Contracts will be automatically verified on Basescan if `BASESCAN_API_KEY` is set in `.env`

## Deployed Contracts

### Base Sepolia (Testnet)

| Contract | Proxy Address | Verified |
|----------|---------------|----------|
| Treasury | `0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE` | ✅ |
| AccessController | `0x273930106653461A2F4f33Ea2821652283dcAE11` | ✅ |
| Verifier | `0x1B079e9519CF110b491a231d7AA67c9a597F13B2` | ✅ |
| PaymentTracker | `0xdBa335d18751944b46f205F32F03Fa4F1BEf1a94` | ✅ |
| BasePay | `0x062d3a45862a32BF5D1e35404aaA55e7027c4F4B` | ✅ |
| RulesEngine | `0xDb1855c6C8ADd51eE4B7e132173cA9833B1DAf07` | ✅ |
| Registry | `0x57741EE5bAc991D43Cf71207781fCB0eE4b9e9a8` | ✅ |
| SafeBaseEscrow | `0xA1e13a0E7E54bC71ee4173D74773b455A86816aB` | ✅ |
| Executor | `0xB49e7b4cCB76B3aE9439798eb980434CBCF8c428` | ✅ |

### Base Mainnet

| Contract | Proxy Address | Verified |
|----------|---------------|----------|
| Treasury | `0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2` | ✅ |
| AccessController | `0xb5118513642b8cC05201b68Ed1a4B2cB2db93edE` | ✅ |
| Verifier | `0xb06d4414B479eb425f6E7d38226d0194C595c7CF` | ✅ |
| PaymentTracker | `0xAA1be2099208db011dFbEa7174114D69982cFcef` | ✅ |
| BasePay | `0xD47991043dA73bdfcF6c399e5Ed26e5C8D6c3D27` | ✅ |
| RulesEngine | `0x7bFA481f050AC09d676A7Ba61397b3f4dac6E558` | ✅ |
| Registry | `0x273930106653461A2F4f33Ea2821652283dcAE11` | ✅ |
| SafeBaseEscrow | `0x1B079e9519CF110b491a231d7AA67c9a597F13B2` | ✅ |
| Executor | `0xdBa335d18751944b46f205F32F03Fa4F1BEf1a94` | ✅ |

**Network Details:**
- **Base Sepolia RPC**: `https://sepolia.base.org`
- **Base Mainnet RPC**: `https://mainnet.base.org`
- **Explorer**: [Basescan](https://basescan.org)

## Architecture

### Core Escrow System

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  SafeBaseEscrow  │────▶│  RulesEngine     │────▶│  Verifier        │
│  (6-state FSM)   │     │  (Conditions)    │     │  (External)      │
└────────┬─────────┘     └──────────────────┘     └──────────────────┘
         │
         │ custody
         ▼
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Treasury        │     │  Registry        │     │  Executor        │
│  (Multi-sig)     │     │  (Indexing)      │     │  (Automation)    │
└──────────────────┘     └──────────────────┘     └──────────────────┘
         ▲
         │ funding
         │
┌──────────────────┐     ┌──────────────────┐
│  BasePay         │────▶│  PaymentTracker  │
│  (Bridge)        │     │  (ID Mapping)    │
└──────────────────┘     └──────────────────┘
```

### State Machine (SafeBaseEscrow)

```
Created → Funded → Released (to seller)
   ↓         ↓
Cancelled  Refunded (to buyer)
   ↓         ↓
Disputed ← ─┘
```

### UUPS Upgradeability

All contracts use ERC1967Proxy pattern:
```
User → Proxy (fixed address) → Implementation (upgradeable)
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
