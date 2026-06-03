# During-Transaction Branch

Sub-branches that activate between `/select` and `/on_confirm`. They shape the transaction before it is committed.

## Sub-branches
| Sub-branch | When active | Purpose |
|---|---|---|
| `payment-prepaid-bap-collected` | init → on_confirm | QRIS/VA/EWallet collected by BAP before confirm |
| `payment-cod-bpp-collected` | init → on_confirm | COD — LSP collects cash at delivery |
| `payment-credit-fwa` | init → on_confirm | Post-delivery credit terms under FWA |
| `fwa-activation` | select → confirm | FWA reference in contract — rates and policies inherited |
| `technical-cancel-confirm-bap` | at confirm | BAP handles NACK or timeout gracefully |
| `technical-cancel-confirm-bpp` | at on_confirm | BPP cannot process confirm — NACKs |

## Multiple can be active simultaneously
FWA activation and payment-credit-fwa often coexist. FWA activation and eKYC branch do not — FWA waives eKYC.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
