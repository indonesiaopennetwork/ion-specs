# Weight Dispute Branch

Handles discrepancies between declared and measured weight/dimensions.

## Applies to
LOG-PARCEL, LOG-FREIGHT.

## Trigger
BPP measures actual weight at pickup or hub and finds it exceeds declared weight by more than the policy tolerance.

## Sub-branches
`weight-discrepancy-raised`, `weight-discrepancy-accepted`, `weight-discrepancy-countered`, `weight-discrepancy-escalated`.

## Resolution flow
BPP raises via `/on_update` → BAP accepts or counters → if unresolved within policy SLA, either party escalates via `/raise` → ION Central adjudicates.

## Policy references
`ion://policy/weight-dispute.standard-10pct-tolerance` (public), `ion://policy/weight-dispute.enterprise-5pct-tolerance` (FWA-governed).

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
