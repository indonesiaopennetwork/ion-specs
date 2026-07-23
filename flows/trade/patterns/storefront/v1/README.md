# B2C Single Fulfilment (B2C-SF)

The reference commerce pattern on ION. Consumer buys a physical product; delivery or self-pickup follows. Every other spine is defined as a delta from this one.

## Applicable categories
Packaged Food (FMCG), Grocery, Fashion, Electronics, Beauty, FMCG, Home & Kitchen, Agritech (consumer-facing)

## API sequence
```
Phase 1  BPP → publish_catalog → ION Catalogue Service
         ION Catalogue Service → on_discover → BAP

Phase 2  BAP → select  → BPP → on_select
         BAP → init    → BPP → on_init
         BAP → confirm → BPP → on_confirm

Phase 3  BPP → on_status [PACKED]
         BPP → on_status [DISPATCHED]        ← AWB + trackingUrl added
         BPP → on_status [OUT_FOR_DELIVERY]
         BPP → on_status [DELIVERED]         ← Contract COMPLETE
```

## Performance state machine
`performance-states/v1/states.yaml#standard`

## Available branches
All branches available. See `flows/trade/README.md` for the complete branch map.

## Key fields introduced
`resourceStructure`, `resourceTangibility`, `availability.status` (signal only — no stock count), `policies.cancellation.policyRef`, `policies.returns.policyRef`, `policies.warranty.policyRef`, `policies.dispute.policyRef`, `provinsiCode`, `deliveryOtp`, `fulfillingLocationId`

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`schema/extensions/trade/resource/v1/README.md`](../../../../schema/extensions/trade/resource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`schema/extensions/trade/offer/v1/README.md`](../../../../schema/extensions/trade/offer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`schema/extensions/trade/commitment/v1/README.md`](../../../../schema/extensions/trade/commitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`schema/extensions/trade/consideration/v1/README.md`](../../../../schema/extensions/trade/consideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`schema/extensions/trade/performance/v1/README.md`](../../../../schema/extensions/trade/performance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`schema/extensions/trade/contract/v1/README.md`](../../../../schema/extensions/trade/contract/v1/README.md) |
| `core/product-compliance/v1` | See pack README | [`schema/extensions/core/product-compliance/v1/README.md`](../../../../schema/extensions/core/product-compliance/v1/README.md) |
| `core/localization/v1` | See pack README | [`schema/extensions/core/localization/v1/README.md`](../../../../schema/extensions/core/localization/v1/README.md) |
| `core/payment/v1` | See pack README | [`schema/extensions/core/payment/v1/README.md`](../../../../schema/extensions/core/payment/v1/README.md) |
| `core/tax/v1` | See pack README | [`schema/extensions/core/tax/v1/README.md`](../../../../schema/extensions/core/tax/v1/README.md) |
| `core/participant/v1` | See pack README | [`schema/extensions/core/participant/v1/README.md`](../../../../schema/extensions/core/participant/v1/README.md) |
| `core/address/v1` | See pack README | [`schema/extensions/core/address/v1/README.md`](../../../../schema/extensions/core/address/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, returns, rto, mid-transaction-changes` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

