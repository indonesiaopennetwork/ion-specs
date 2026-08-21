# Trade Commitment Extension — Overview

Per-line item details within a contract. One Commitment per item line.

## lineId
Assigned by BAP at select. Persists through the entire lifecycle. Used to reference specific lines in partial cancellations, line-level returns, and price adjustments. Never reassigned.

## Locked price
`price.value` is locked at `on_select`. It does not change unless a `mid-transaction-changes` variant is triggered. This is the source of truth for per-line amounts in reconciliation.

## selectedCustomizations
Inherited from RetailCommitment v2.1. For COMPOSED and WITH_EXTRAS resources,
it records the selected `groupId` and `optionId` values. Price deltas remain on
the Resource customization-option definitions; the inherited commitment
`price` records the final committed line price.

## replacementPreferred
Line-specific buyer preference for replacement instead of refund when the
committed resource is eligible for remediation.
