# Security Notes

## Invariants
- Escrow: terminal states are final; exactly one payout (release or refund) per escrow.
- Deadline: refund after deadline is open to anyone if no mediator; dispute requires mediator.
- Treasury: funds balance >= sum of active Funded/Disputed escrows; approvals before withdrawal.
- Rules: external verifier required when enabled; missing address blocks release.

## Risks and mitigations
- **Mediator collusion**: mediator can release/refund from Funded/Disputed. Mitigate with trusted selection, log review, rule templates/limits.
- **Reentrancy / external calls**: withdrawals via call; keep reentrancy guard, ensure safe tokens when ERC20 path is added.
- **Deadline DoS**: many escrows with short deadlines stress Executor. Mitigate with batching, rate-limits in off-chain worker.
- **Verifier downtime**: blocks release; backend should retry and avoid calling contract until verified.
- **Upgrade risk**: UUPS - check storage layout, proxy owner, test on testnet before prod.
- **Key/role compromise**: AccessController/Treasury admins in multisig, enforce limits/approvals.

## Upgrades
- Ensure proxy owner is nonzero; never renounce on upgradeable infra.
- Review storage layout diff before release; adjust gap carefully.
- Upgrade scripts must use `upgradeTo`/`upgradeToAndCall` and log tx.

## Tests / QA (minimum)
- Invariant tests: single payout, terminal states irreversible, deadline rules, no release without buyerApproved when required by RuleSet.
- Fuzz: dispute/approve racing deadline; duplicate `paymentId`; mass fund/refund.
- Negative: missing verifier, zero mediator dispute, release from Created, double refund.

## Operations
- Monitor events: `EscrowFunded/Released/Refunded/Disputed`, `BasePayFundingReceived`, `BasePayTransactionProcessed`, Treasury approvals/executions.
- Runbooks: manual withdrawal if Executor fails; actions when Verifier/Base Pay is down.
- RPC: prefer reliable RPC (mainnet.base.org/Alchemy/Infura/Ankr); avoid unstable endpoints.
