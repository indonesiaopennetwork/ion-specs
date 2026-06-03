# Exception Branch

Damage, loss, address-unserviceable, and pickup-failed scenarios.

## Applies to
LOG-PARCEL, LOG-FREIGHT, LOG-HYPERLOCAL, LOG-XB.

## Sub-branches
`damage-claim`, `loss-claim`, `address-unserviceable`, `pickup-failed`.

## Dispute flow
All claims flow through `/update` with policy IRI referencing the applicable claim policy. Evidence is mandatory per the `evidencePolicy` IRI on the offer. Escalation to `/raise` after policy-defined SLA.

## Attribution
For `pickup-failed`, `failureAttribution` (CONSIGNOR_FAULT, LSP_FAULT, FORCE_MAJEURE) determines if a fee is charged per policy.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
