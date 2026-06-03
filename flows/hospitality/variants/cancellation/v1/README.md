# cancellation — ION Hospitality Variant v1

**Applies to:** delivery-order  
**Window:** On confirm → kitchen state PREPARING  

Cancellation for food orders is time-critical. The window is typically
60-90 seconds — once the kitchen is PREPARING, self-service cancel is not
available and the consumer must raise a dispute.

| Scenario | Refund | Fee |
|---|---|---|
| Before kitchen accepts | Full | None |
| After accept, before preparing | Full | None (within window) |
| During preparation | None | Full order amount |
| Kitchen cancels (ingredient unavailable) | Full | None + platform voucher |
| Platform cancels (no rider) | Full | None |

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
