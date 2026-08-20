# Marketplace Inventory Less (MP-IL)

3P marketplace. Each seller is an independent BPP. Marketplace is the BAP.

## Architecture
```
Consumer → Marketplace BAP
           Seller A BPP (own stock, own fulfilment)
           Seller B BPP (own stock, own fulfilment)
```
Marketplace routes consumer's order to the specific seller BPP.


## Performance state machine
`performance-states/v1/states.yaml#standard`
Each seller BPP manages its own state machine independently.

## Key differences from B2C-SF
- Many BPPs — each seller = one BPP
- Marketplace aggregates multi-BPP catalog in own discovery layer
- `collectedBy = BAP` (marketplace collects from consumer, settles to seller)
- `PLATFORM_FEE` consideration line: marketplace commission deducted in reconcile
- `buyerFinderFeeAmount` in reconcile = marketplace commission
- Post-order: consumer communicates with marketplace; marketplace relays to BPP
- Dispute: marketplace intervenes if seller non-responsive (raise → ION escalation)

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`releases/release1/extension/trade/TradeResource/v1/README.md`](../../../../releases/release1/extension/trade/TradeResource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`releases/release1/extension/trade/TradeOffer/v1/README.md`](../../../../releases/release1/extension/trade/TradeOffer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`releases/release1/extension/trade/TradeCommitment/v1/README.md`](../../../../releases/release1/extension/trade/TradeCommitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`releases/release1/extension/trade/TradeConsideration/v1/README.md`](../../../../releases/release1/extension/trade/TradeConsideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`releases/release1/extension/trade/TradePerformance/v1/README.md`](../../../../releases/release1/extension/trade/TradePerformance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`releases/release1/extension/trade/TradeContract/v1/README.md`](../../../../releases/release1/extension/trade/TradeContract/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, returns` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

