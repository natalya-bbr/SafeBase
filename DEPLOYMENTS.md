# Deployment Addresses

## Base Sepolia

Deployed on: 2025-11-22

### Treasury (UUPS Upgradeable Proxy)

**Proxy Address:** `0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba`
- [View on BaseScan](https://sepolia.basescan.org/address/0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba)
- Verification Status: ✅ Verified (Sourcify)

**Implementation Address:** `0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331`
- [View on BaseScan](https://sepolia.basescan.org/address/0x6f54752a6EA251C88Fe07C82D4A0C67f0e1Ec331)
- Verification Status: ✅ Verified (Sourcify)

### Configuration

- Required Approvals: 2
- Initial Deposit: 0.001 ETH
- Admins: 2
- Executors: 1

### Deployment Transaction

- Gas Used: ~3,724,225
- Gas Cost: ~0.000005 ETH
- Chain ID: 84532

### Interact with Contract

```bash
# View treasury info
cast call 0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba "requiredApprovals()" --rpc-url https://sepolia.base.org

# Check balance
cast balance 0xD9C9e166815f1A57B9da26E920e07E72A835B3Ba --rpc-url https://sepolia.base.org
```

## Base Mainnet

_Not deployed yet_

---

Generated: 2025-11-22T13:50:00Z
