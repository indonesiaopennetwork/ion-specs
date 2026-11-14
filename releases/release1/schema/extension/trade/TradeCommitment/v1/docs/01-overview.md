# Trade Commitment Extension — Overview

Per-line item details within a contract. One Commitment per item line.

## Commitment identity
`Commitment.id` is the line identifier assigned by the BAP at select. It
persists through the lifecycle and identifies the commitment for partial
cancellations, line-level returns, and price adjustments. It is not repeated
inside `commitmentAttributes`.

## Locked price
`commitmentAttributes.price.value` is locked at `on_select`. It does not change
unless a `mid-transaction-changes` variant is triggered. This is the source of
truth for per-line amounts in reconciliation.

## selectedCustomizations
For COMPOSED and WITH_EXTRAS resources, it records the selected `groupId` and
`optionId` values. Price deltas remain on the Resource customization-option
definitions; the commitment `price` records the final committed line price.

## replacementPreferred
Line-specific buyer preference for replacement instead of refund when the
committed resource is eligible for remediation.
