# Reverse Branch

Per-spine reverse flavours. Reverse logistics is not a separate spine — each forward spine supports a reverse branch that modifies its state machine.

## Sub-branches
| Branch | Parent spine | Key difference |
|---|---|---|
| `reverse-simple` | LOG-HYPERLOCAL | No QC, fast refund, minutes-to-hours window |
| `reverse-with-qc` | LOG-PARCEL | QC gating — refund held until QC approves |
| `reverse-freight` | LOG-FREIGHT | Acceptance states, credit-note commercial model |
| `reverse-xb` | LOG-XB | Dual customs, destroy-in-place option |
| `inventory-release` | LOG-WAREHOUSE | Spawns forward transport contract |

## Return policy governance
Return window and conditions are governed by the `returnPolicy` IRI on the original forward offer. Evidence requirements are governed by the `evidencePolicy` IRI.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
