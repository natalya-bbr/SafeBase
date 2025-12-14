# SafeBase Architecture

## Modules
- **SafeBaseEscrowV1** - 6-state FSM, stores deal params, routes calls to Treasury, RulesEngine, Registry.
- **RulesEngineV1** - evaluates release/refund (approvals, deadlines, external verifier, auto-release/auto-refund).
- **RegistryV1** - escrow index (id -> metadata), emits events for frontend/indexer.
- **ExecutorV1** - automated execution (auto-refund/auto-release) based on rules/deadlines.
- **Treasury / TreasuryV2** - custody, multi-step approvals, Base Pay transaction idempotency.
- **BasePay / PaymentTracker / Verifier** - off-chain payment bridge, paymentId -> escrow mapping, verification.
- **Wallet layer (SmartWallet, SubAccountManager, BatchCaller, WalletFactory, NameService)** - B2B roles/limits, batching.
- **AccessController** - roles/admins, used by Treasury/Registry/Executor.
- **Webhook / onchain Utils** - helper calls and notifications.

## Flows (high-level)
1) **Create**: buyer calls `createEscrow` (seller, mediator?, token, amount, deadline, ruleSetId) -> write to Registry.
2) **Funding**: 
   - `fundEscrow` (ETH) -> Treasury, state Funded.  
   - `fundEscrowWithBasePay(paymentId)` for off-chain payment -> PaymentTracker/Verifier confirm -> Funded.
3) **Approvals**: buyer/seller may approve; mediator can override when enabled.
4) **Release/Refund**: 
   - `releaseToSeller` or `refundToBuyer` check RulesEngine (approvals/deadline/verifier/mediator override) -> Treasury transfers.
   - In Disputed state mediator decides.
5) **Automation**: Executor polls rules/deadlines and triggers release/refund without manual clicks.
6) **Upgrades**: UUPS, proxy owner = admin; verify storage layout before upgrade.

## Roles
- Buyer: create/fund, approve, dispute/cancel, may trigger release when fully approved.
- Seller: receives funds, may dispute.
- Mediator: override rules, release/refund from Funded/Disputed.
- Admin/Owner: manages addresses for RulesEngine/Registry/Treasury/Executor, pause, upgrades.
- Executor bot: service that calls Executor for automated actions.

## Integrations
- **Base Pay**: off-chain payment -> Verifier -> `fundEscrowWithBasePay`, `paymentIdToEscrow` in Registry/PaymentTracker.
- **Indexer**: consume Escrow/Treasury/Rules/Executor/BasePay events; build timelines and SLA metrics.
- **Frontend (OnchainKit + Base SDK)**: wallet connect, tx launch, status rendering from indexer.
