# Base Pay - flow and integration

## Goals
- Map off-chain payment to on-chain escrow.
- Idempotency: each `paymentId` processed once (`paymentIdToEscrow`, `TreasuryV2.basePayTransactions`).
- Transparency: events for indexer and dashboards.

## Flow
1) User pays via Base Pay off-chain.
2) Backend listens to Base Pay notification -> validates -> triggers Verifier/PaymentTracker.
3) On-chain call `fundEscrowWithBasePay(escrowId, paymentId)`:
   - Sets state to Funded.
   - Stores `paymentIdToEscrow[paymentId] = escrowId`.
   - Emits `BasePayFundingReceived`.
4) (Optional) `TreasuryV2.processBasePayTransaction(txId, token, to, amount)`:
   - Marks `basePayTransactions[txId] = true` (idempotent).
   - Emits `BasePayTransactionProcessed`.

## Backend requirements
- Verify `paymentId` authenticity (Base Pay signature/webhook).
- Guarantee once-only processing per `paymentId` (retry with same id must be no-op).
- Log escrowId/paymentId/tx hash; retry on network errors.
- Respect proxy settings from environment.

## Errors / edge cases
- Duplicate `paymentId`: should safely no-op/fail.
- Escrow not in Created: `InvalidState`.
- Invalid `escrowId`: `EscrowNotFound`.
- Verifier unavailable: backend must not call contract until verified.

## Metrics/events for indexer
- `BasePayFundingReceived(escrowId, paymentId)`
- `EscrowFunded(escrowId, amount)`
- `BasePayTransactionProcessed(txId)`

## Next steps
- Add full ERC20 handling in `fundEscrowWithBasePay` (currently only marks funding).
- Add worker service for reliable retries and dead-letter handling.
