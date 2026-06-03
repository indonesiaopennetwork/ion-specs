# Marketplace Inventory Held (MP-IH)

Marketplace holds physical stock. Single BPP (the marketplace) serves multiple brands.

## Architecture
```
Consumer → Marketplace BAP
           Marketplace BPP ← holds stock in own FC
           Brand A, Brand B, Brand C (each = a provider in catalog)
```
The marketplace IS the BPP. Brands supply stock on consignment or 1P. The marketplace picks, packs, and ships.

## Key differences from B2C-SF
- `invoicingModel = CENTRAL` — marketplace invoices, not individual brand
- `fulfillingLocationId` = marketplace FC ID (fast assignment at on_confirm)
- Marketplace SLA guarantees apply — faster and more reliable than 3P
- Returns handled by marketplace FC
- Brand payout is handled by marketplace's internal financial system — not via ION reconcile

## State machine
`performance-states/v1/states.yaml#standard`

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`schema/extensions/trade/resource/v1/README.md`](../../../../schema/extensions/trade/resource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`schema/extensions/trade/offer/v1/README.md`](../../../../schema/extensions/trade/offer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`schema/extensions/trade/commitment/v1/README.md`](../../../../schema/extensions/trade/commitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`schema/extensions/trade/consideration/v1/README.md`](../../../../schema/extensions/trade/consideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`schema/extensions/trade/performance/v1/README.md`](../../../../schema/extensions/trade/performance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`schema/extensions/trade/contract/v1/README.md`](../../../../schema/extensions/trade/contract/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, returns` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

