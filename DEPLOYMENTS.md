# Deployment Addresses

## Base Mainnet

Deployed on: 2025-11-22

### Treasury (UUPS Upgradeable Proxy)

**Proxy Address:** `0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2`
- [View on BaseScan](https://basescan.org/address/0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2)
- Verification Status: ✅ Verified (Basescan)

**Implementation Address:** `0x8FeD01EB5FC4Ec7f7719a726efFbD19F081c83fC`
- [View on BaseScan](https://basescan.org/address/0x8FeD01EB5FC4Ec7f7719a726efFbD19F081c83fC)
- Verification Status: ✅ Verified (Basescan)

### Configuration

- Required Approvals: 2
- Admins: 2
  - Admin 1: `0x9dE32c8F0a7533E1344eDd1F75F4914F70943564`
  - Admin 2: `0x6fE19d47d43c8912A09F45303Dc219d8c0EC941c`
- Executors: 1
  - Executor: `0x414B7bBF639714514b704512762730947D401604`

### Deployment Transaction

- Gas Used: ~2,233,923
- Gas Cost: ~0.000012 ETH
- Chain ID: 8453

---

## Base Sepolia (Testnet)

Deployed on: 2025-11-22

### Treasury (UUPS Upgradeable Proxy)

**Proxy Address:** `0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE`
- [View on BaseScan](https://sepolia.basescan.org/address/0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE)
- Verification Status: ✅ Verified (Basescan)

**Implementation Address:** `0xAA1be2099208db011dFbEa7174114D69982cFcef`
- [View on BaseScan](https://sepolia.basescan.org/address/0xAA1be2099208db011dFbEa7174114D69982cFcef)
- Verification Status: ✅ Verified (Basescan)

### Configuration

- Required Approvals: 2
- Admins: 2
  - Admin 1: `0x9dE32c8F0a7533E1344eDd1F75F4914F70943564`
  - Admin 2: `0x6fE19d47d43c8912A09F45303Dc219d8c0EC941c`
- Executors: 1
  - Executor: `0x414B7bBF639714514b704512762730947D401604`

### Deployment Transaction

- Gas Used: ~2,233,923
- Gas Cost: ~0.000003 ETH
- Chain ID: 84532

---

## Interact with Contracts

### View Treasury Info

**Base Mainnet:**
```bash
cast call 0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2 "requiredApprovals()" --rpc-url https://mainnet.base.org
cast call 0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2 "owner()" --rpc-url https://mainnet.base.org
```

**Base Sepolia:**
```bash
cast call 0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE "requiredApprovals()" --rpc-url https://sepolia.base.org
cast call 0x546bD44cE5576A6e90cC7150aD93aAD1B06291BE "owner()" --rpc-url https://sepolia.base.org
```

### Request Withdrawal (Admin)

```bash
cast send 0xE965E798Fd2cDeA9e5BCeD37292477Cc802d92f2 \
  "requestWithdrawal(address,address,uint256)" \
  0x0000000000000000000000000000000000000000 \
  <recipient_address> \
  1000000000000000 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY
```

---

Generated: 2025-11-22T14:30:00Z
