# SafeBase Deployment Guide

## Current Deployment Status

### Base Mainnet (Chain ID: 8453)

| Contract | Proxy Address | Implementation | Status |
|----------|--------------|----------------|--------|
| Treasury | `0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2` | `0x8FeD01EB5FC4Ec7f7719a726efFbD19F081c83fC` | ✅ Deployed |
| AccessController | - | - | ⏳ Pending |
| Verifier | - | - | ⏳ Pending |
| PaymentTracker | - | - | ⏳ Pending |
| BasePay | - | - | ⏳ Pending |
| RulesEngine | - | - | ⏳ Pending |
| Registry | - | - | ⏳ Pending |
| SafeBaseEscrow | - | - | ⏳ Pending |
| Executor | - | - | ⏳ Pending |

### Base Sepolia (Chain ID: 84532)

| Contract | Proxy Address | Implementation | Status |
|----------|--------------|----------------|--------|
| Treasury | `0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE` | `0xAA1be2099208db011dFbEa7174114D69982cFcef` | ✅ Deployed |
| AccessController | - | - | ⏳ Pending |
| Verifier | - | - | ⏳ Pending |
| PaymentTracker | - | - | ⏳ Pending |
| BasePay | - | - | ⏳ Pending |
| RulesEngine | - | - | ⏳ Pending |
| Registry | - | - | ⏳ Pending |
| SafeBaseEscrow | - | - | ⏳ Pending |
| Executor | - | - | ⏳ Pending |

## GitHub Actions Deployment

### Using the Deploy Workflow

The project includes a unified deployment workflow that allows selective contract deployment.

**Access:** GitHub Actions → Deploy SafeBase Contracts

**Parameters:**
- **Network:** Choose between `sepolia` (testnet) or `mainnet`
- **Contract:** Select which contract to deploy:
  - `all` - Deploy all missing contracts
  - `Treasury` - Deploy only Treasury
  - `AccessController` - Deploy only AccessController
  - `Verifier` - Deploy only Verifier
  - `PaymentTracker` - Deploy only PaymentTracker
  - `BasePay` - Deploy only BasePay
  - `RulesEngine` - Deploy only RulesEngine
  - `Registry` - Deploy only Registry
  - `SafeBaseEscrow` - Deploy only SafeBaseEscrow
  - `Executor` - Deploy only Executor

**Features:**
- ✅ **Smart Deployment** - Automatically reads existing addresses from `deployments/*.json`
- ✅ **Skip Deployed** - Skips already deployed contracts (saves gas!)
- ✅ **Idempotent** - Safe to run multiple times without redeploying
- ✅ **Automatic Basescan Verification** - All contracts verified on deployment
- ✅ **Saves Artifacts** - Deployment data saved for audit trail
- ✅ **Auto-Configuration** - Configures contract dependencies automatically

### Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

- `PRIVATE_KEY` - Deployer private key
- `OWNER_ADDRESS` - Contract owner address
- `BASESCAN_API_KEY` - Basescan API key for verification

## Local Deployment

### Deploy All Contracts (Smart Mode)

Both `DeployProxy.s.sol` and `DeployModular.s.sol` now support smart deployment:

```bash
# Using DeployModular.s.sol (recommended for selective deployment)
forge script script/DeployModular.s.sol \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --verify

# Using DeployProxy.s.sol (deploys all contracts)
forge script script/DeployProxy.s.sol \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --verify
```

✅ **File permissions configured in `foundry.toml`** - scripts can automatically read from `deployments/` directory.

### Deploy Specific Contract

```bash
DEPLOY_CONTRACT=RulesEngine forge script script/DeployModular.s.sol \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --verify
```

### How Smart Deployment Works

1. **Read JSON** - Script reads `deployments/8453.json` or `deployments/84532.json` based on chain ID
2. **Check Existing** - For each contract, checks if proxy address exists and is not `address(0)`
3. **Skip or Deploy** - If exists, logs "already deployed at X" and skips; otherwise deploys fresh
4. **Configure** - After all deployments, configures dependencies (setRulesEngine, setRegistry, etc.)
5. **Safe Retry** - Configuration uses try-catch, so safe to run multiple times

### Console Output Examples

```
Treasury already deployed at: 0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2
AccessController deployed - Proxy: 0x123... Impl: 0x456...
```

### Environment Variables

```bash
export PRIVATE_KEY=0x...
export OWNER_ADDRESS=0x...
export BASESCAN_API_KEY=...
export DEPLOY_CONTRACT=all  # or specific contract name
```

## Deployment Order

The modular deployment script automatically handles dependencies:

1. **Treasury** - No dependencies
2. **AccessController** - No dependencies
3. **Verifier** - No dependencies
4. **PaymentTracker** - No dependencies
5. **BasePay** - No dependencies
6. **RulesEngine** - No dependencies
7. **Registry** - No dependencies
8. **SafeBaseEscrow** - Requires Treasury
9. **Executor** - Requires SafeBaseEscrow and RulesEngine

## Contract Architecture

### Core Escrow Modules

- **SafeBaseEscrowV1** - Main escrow engine with 6-state machine
- **RulesEngineV1** - Programmable conditional logic
- **RegistryV1** - Escrow indexing and discovery
- **ExecutorV1** - Automated execution module

### Integration Modules

- **AccessController** - Role-based access control
- **Verifier** - External verification hooks
- **BasePay** - Offchain/onchain payment bridging
- **PaymentTracker** - Payment ID mapping

### Existing Module

- **Treasury** - Multi-sig treasury with UUPS upgradeability

## Upgradeability

All contracts use UUPS (Universal Upgradeable Proxy Standard) via ERC1967Proxy:
- Implementation contracts are deployed first
- Proxy contracts wrap implementations with initialization
- Only owner can upgrade via `upgradeToAndCall`

## Verification

Contracts are automatically verified on Basescan during deployment using:
- `--verify` flag in forge script
- `--verifier etherscan` for Basescan
- API key from `BASESCAN_API_KEY` environment variable

## Post-Deployment

After deployment, addresses are automatically printed to console. Update the JSON files manually:

1. Copy addresses from deployment output
2. Update `deployments/8453.json` (mainnet) or `deployments/84532.json` (sepolia)
3. Commit and push changes

Example JSON structure:
```json
{
  "contracts": {
    "Treasury": {
      "proxy": "0x...",
      "implementation": "0x..."
    }
  }
}
```
