# B2C Make-to-Order (B2C-MTO)

Extends B2C-SF for products prepared after confirm. Once preparation starts, cancellation closes.

## Applicable categories
Custom bakery (packaged), meal kits, tailoring, custom furniture — NOT restaurant/cloud kitchen food ordering (→ Hospitality sector)

## Key differences from B2C-SF
- State machine: **mto** — PREPARING → READY → DISPATCHED → OUT_FOR_DELIVERY → DELIVERED
- Cancellation policy: `cancel.mto.nofee.before_prepare` — free before PREPARING, closed after
- `averagePreparationTime` required on provider; `preparationTime` required per item
- On `on_status[PREPARING]` — cancellation window closes

## API sequence
Same as B2C-SF. State code differences only in `on_status`.

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`releases/release1/extension/trade/TradeResource/v1/README.md`](../../../../releases/release1/extension/trade/TradeResource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`releases/release1/extension/trade/TradeOffer/v1/README.md`](../../../../releases/release1/extension/trade/TradeOffer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`releases/release1/extension/trade/TradeCommitment/v1/README.md`](../../../../releases/release1/extension/trade/TradeCommitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`releases/release1/extension/trade/TradeConsideration/v1/README.md`](../../../../releases/release1/extension/trade/TradeConsideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`releases/release1/extension/trade/TradePerformance/v1/README.md`](../../../../releases/release1/extension/trade/TradePerformance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`releases/release1/extension/trade/TradeContract/v1/README.md`](../../../../releases/release1/extension/trade/TradeContract/v1/README.md) |
| `core/product-compliance/v1` | See pack README | [`schema/extensions/core/product-compliance/v1/README.md`](../../../../schema/extensions/core/product-compliance/v1/README.md) |
| `core/localization/v1` | See pack README | [`schema/extensions/core/localization/v1/README.md`](../../../../schema/extensions/core/localization/v1/README.md) |
| `core/payment/v1` | See pack README | [`releases/release1/common/Payment/v1/README.md`](../../../../releases/release1/common/Payment/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

