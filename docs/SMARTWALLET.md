# Smart Wallet layer (B2B)

## Components
- **SmartWallet** - base smart account with roles.
- **SubAccountManager** - hierarchy of org subaccounts/budgets.
- **BatchCaller** - batch operations (approve, release, refund, registry calls).
- **WalletFactory** - issues wallets for orgs.
- **NameService** - readable names/aliases.

## Roles / limits (example)
- Org Admin - creates subaccounts, sets limits, assigns operators.
- Operator - performs payments/escrow actions within limits.
- Viewer/Auditor - read-only/off-chain sign-offs.
- Limits: per-tx, daily, by op type (fund, release/refund, treasury withdraw).

## Flows
1) Org deploys SmartWallet via Factory, registers in NameService.
2) Creates subaccounts with limits (e.g., procurement with daily cap).
3) Operators interact with Escrow/Treasury via BatchCaller (gas and UX reduction).
4) Events include org/subaccount/actor/opType/amount for audit and indexing.

## UX / integrations
- OnchainKit + Base SDK: select subaccount, view limits, submit batches.
- Multisig/role approvals on wallet level (extra layer beyond escrow approvals).
- AA/4337 compatibility priority: avoid breaking standard smart wallet interfaces.

## Next steps
- Implement limits/roles fully if placeholders remain.
- Emit detailed audit events (org, subaccount, actor, opType, amount).
- E2E tests: batches with limits, limit violations, operator without admin rights.
