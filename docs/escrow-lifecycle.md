# SafeBase Escrow Lifecycle Specification

## Overview

SafeBase escrow system is a production-grade, modular escrow and conditional payment layer for Base L2. The system consists of two core components:

- **SafeBaseEscrowV1**: State machine managing escrow lifecycle and fund custody
- **RulesEngineV1**: Programmable condition evaluation for release/refund decisions

## State Machine

### States (6 total)

1. **Created** - Initial state after escrow creation
2. **Funded** - Funds deposited (via direct funding or Base Pay)
3. **Released** - Funds released to seller (terminal state)
4. **Refunded** - Funds refunded to buyer (terminal state)
5. **Disputed** - Dispute raised, requires mediator intervention
6. **Cancelled** - Escrow cancelled before funding (terminal state)

### State Transition Diagram

```
Created ──fundEscrow()──────────> Funded ──releaseToSeller()──> Released ✓
   │                                 │
   │                                 ├──refundToBuyer()────────> Refunded ✓
   │                                 │
   └──cancelEscrow()──> Cancelled ✓ └──disputeEscrow()────────> Disputed
                                                                   │
                                                                   ├──releaseToSeller()──> Released ✓
                                                                   │
                                                                   └──refundToBuyer()────> Refunded ✓
```

### Allowed Transitions

| From       | To         | Trigger              | Authorization                                    |
|------------|------------|----------------------|--------------------------------------------------|
| Created    | Funded     | fundEscrow()         | Buyer only                                       |
| Created    | Funded     | fundEscrowWithBasePay() | Anyone (off-chain verified)                   |
| Created    | Cancelled  | cancelEscrow()       | Buyer only                                       |
| Funded     | Released   | releaseToSeller()    | Buyer (with approval) OR Mediator               |
| Funded     | Refunded   | refundToBuyer()      | Mediator OR Anyone after deadline               |
| Funded     | Disputed   | disputeEscrow()      | Buyer OR Seller (requires mediator set)         |
| Disputed   | Released   | releaseToSeller()    | Mediator only                                    |
| Disputed   | Refunded   | refundToBuyer()      | Mediator only                                    |

**Terminal states**: Released, Refunded, Cancelled - no transitions out.

## Roles

### Buyer
- Creates escrow
- Funds escrow
- Can approve release (buyerApproved flag)
- Can raise dispute
- Receives refund

### Seller
- Receives funds on release
- Can approve delivery (sellerApproved flag - future use)
- Can raise dispute

### Mediator (optional)
- Can override any approval requirements
- Can release or refund from any Funded/Disputed state
- Required for dispute resolution
- Escrows without mediator cannot be disputed

## Rules Engine Integration

### Without Rules Engine (ruleSetId = 0)
Default behavior:
- **Release**: Requires buyer approval (buyerApproved) OR mediator override
- **Refund**: Requires mediator action OR deadline expiration

### With Rules Engine (ruleSetId > 0)
Delegates decision logic to RulesEngineV1:
- **canRelease()**: Evaluates approval requirements, mediator override, external verifiers
- **canRefund()**: Evaluates deadline, mediator override, auto-refund rules

### Rule Set Structure
```solidity
struct RuleSet {
    bool requireBuyerApproval;      // Buyer must approve before release
    bool requireSellerApproval;     // Seller must approve (future)
    bool autoRefundAfterDeadline;   // Auto-refund when deadline expires
    bool autoReleaseOnFullApproval; // Auto-release when both parties approve
    bool mediatorOverrideEnabled;   // Mediator can bypass all rules
    bool externalVerifierEnabled;   // Use external contract for verification
    address externalVerifier;       // External verifier contract address
}
```

## Invariants

### State Invariants
1. **Monotonic state progression**: Once in terminal state (Released/Refunded/Cancelled), state cannot change
2. **Single terminal state**: An escrow can only reach one terminal state
3. **Dispute requires mediator**: Cannot transition to Disputed if mediator == address(0)
4. **Funding immutability**: Once Funded, amount and parties cannot change

### Financial Invariants
1. **Conservation**: Funds held in Treasury equal sum of all Funded/Disputed escrows
2. **Single release**: Each escrow can only trigger one withdrawal (release OR refund, never both)
3. **Amount consistency**: Withdrawal amount always equals escrow.amount

### Authorization Invariants
1. **Buyer exclusivity**: Only buyer can fund and cancel
2. **Mediator authority**: Mediator can always release/refund from Funded/Disputed states
3. **Approval requirement**: Non-mediator releases require buyerApproved (unless rules override)

### Temporal Invariants
1. **Deadline in future**: createEscrow requires deadline > block.timestamp
2. **Auto-refund**: After deadline, anyone can trigger refund (if no mediator)
3. **No deadline bypass**: Release does not check deadline (allows late fulfillment)

## Edge Cases

### Race Conditions
1. **Approve + Deadline**: Buyer approves just as deadline expires
   - **Result**: Both release and refund are valid; first transaction wins

2. **Dispute + Release**: Buyer disputes while mediator releases
   - **Result**: Dispute fails (state already Released) OR Release fails (state Disputed)

3. **Dual approval**: Buyer and seller approve simultaneously
   - **Result**: Both approvals succeed; state unchanged until release called

### Failure Modes
1. **Missing verifier**: If externalVerifierEnabled but verifier == address(0)
   - **Result**: canRelease() returns false, blocking release

2. **Treasury withdrawal fails**: Network congestion or recipient revert
   - **Result**: State changes to Released/Refunded but withdrawal reverts entire transaction

3. **Mediator unavailable**: Escrow disputed but mediator address compromised
   - **Result**: Funds locked until mediator acts; no fallback mechanism

### Boundary Conditions
1. **Zero deadline**: Prevented by createEscrow validation
2. **Zero amount**: Prevented by createEscrow validation
3. **Missing seller**: Prevented by createEscrow validation
4. **Missing mediator**: Allowed; disputes disabled for this escrow

## Integration Patterns

### Standard Escrow Flow
```solidity
// 1. Create escrow
uint256 escrowId = escrow.createEscrow(
    seller,
    mediator,
    address(0),  // ETH
    1 ether,
    block.timestamp + 7 days,
    ruleSetId
);

// 2. Buyer funds
escrow.fundEscrow{value: 1 ether}(escrowId);

// 3. Buyer approves after delivery
escrow.approveBuyer(escrowId);

// 4. Release to seller
escrow.releaseToSeller(escrowId);
```

### Base Pay Integration
```solidity
// Off-chain: User pays via Base Pay
// On-chain: Verifier calls fundEscrowWithBasePay
escrow.fundEscrowWithBasePay(escrowId, paymentId);
```

### Dispute Resolution
```solidity
// Buyer raises dispute
escrow.disputeEscrow(escrowId);

// Mediator investigates and decides
// Option A: Release to seller
escrow.releaseToSeller(escrowId);

// Option B: Refund to buyer
escrow.refundToBuyer(escrowId);
```

## Upgrade Considerations

### Storage Layout
SafeBaseEscrowV1 uses UUPS proxy pattern:
- `EscrowData` struct can be extended (append-only)
- New fields added in Block 1: `ruleSetId`
- Gap: `uint256[50] __gap` reserved for future storage

### Breaking Changes from V0 (if exists)
1. `createEscrow()` now requires `ruleSetId` parameter
2. `releaseToSeller()` now accepts Disputed state
3. RulesEngine integration changes authorization logic

### Migration Strategy
- Existing escrows (without ruleSetId) continue with legacy logic
- New escrows can use Rules Engine by setting ruleSetId > 0
- No state migration required; backward compatible

## Security Model

### Trust Assumptions
1. **Mediator honesty**: Mediators have full control over disputed escrows
2. **Treasury security**: Multi-sig treasury protects all funds
3. **Rules immutability**: Once created, RuleSets cannot be modified (future: add updateRuleSet)

### Attack Vectors
1. **Mediator collusion**: Mediator + Buyer/Seller collude to steal funds
   - **Mitigation**: Reputation system, EAS attestations (future blocks)

2. **Denial of service**: Attacker creates many escrows to bloat state
   - **Mitigation**: Registry indexing, off-chain filtering (Block 6)

3. **Reentrancy**: Withdrawal triggers external call to recipient
   - **Mitigation**: ReentrancyGuard on releaseToSeller/refundToBuyer

### Access Control
- **Owner**: Can set rulesEngine, registry, pause contract
- **Buyer**: Can create, fund, approve, dispute, cancel
- **Seller**: Can approve, dispute
- **Mediator**: Can release, refund from Funded/Disputed
- **Anyone**: Can refund after deadline (if no mediator)

## Future Enhancements (Beyond Block 1)

1. **Partial releases**: Split payments for milestone-based escrows
2. **Multi-token support**: ERC20 token escrows (currently ETH only)
3. **Time-locked releases**: Automatic release after deadline + approval
4. **Appeal mechanism**: Secondary mediator for disputed cases
5. **Escrow templates**: Pre-configured rule sets for common use cases
6. **Event-driven automation**: Executor integration for auto-release/refund

---

**Version**: 1.0 (Block 1 - Lifecycle Hardening)
**Last Updated**: 2025-12-11
**Maintainer**: SafeBase Core Team
