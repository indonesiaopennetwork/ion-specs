# delivery-order — Hospitality Pattern v1

Food and beverage ordered for delivery or self-pickup. Item is **prepared fresh after order confirmation**.

**Sector:** `ion:hospitality`  
**CRC:** `HSC-delivery`  
**Pattern:** `delivery-order`

## State sequence

```
ACCEPTED → PREPARING → READY_FOR_PICKUP → OUT_FOR_DELIVERY → DELIVERED
                                        → PICKED_UP  (self-pickup mode)
```

## Applicable variants

- `cross-cutting` — always active (track, support, rating, reconcile, raise)
- `cancellation` — before preparation starts (typically 5 min window)
- `cash-on-delivery` — when `offer.availableOnCod=true`

## Path notation example

```
hospitality / HSP-05 / HSC-delivery / delivery-order / cash-on-delivery
```

## Key differences from trade/storefront

| | `storefront` (Trade) | `delivery-order` (Hospitality) |
|---|---|---|
| Item state at order | In stock, pre-packaged | Does not exist — made to order |
| Returns | Yes (policy-dependent) | No — `returnable: false` always |
| Cancellation | Up to dispatch | Only before PREPARING starts |
| Inventory | Stock-based | Capacity-based |
| Logistics | External LSP | Usually embedded in BPP |

See `pattern.yaml` for the full API sequence.

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `hospitality/menu-item/v1` | See pack README | [`schema/extensions/hospitality/menu-item/v1/README.md`](../../../../schema/extensions/hospitality/menu-item/v1/README.md) |
| `hospitality/menu-item/v1` | See pack README | [`schema/extensions/hospitality/menu-item/v1/README.md`](../../../../schema/extensions/hospitality/menu-item/v1/README.md) |
| `hospitality/commitment/v1` | See pack README | [`schema/extensions/hospitality/commitment/v1/README.md`](../../../../schema/extensions/hospitality/commitment/v1/README.md) |
| `hospitality/consideration/v1` | See pack README | [`schema/extensions/hospitality/consideration/v1/README.md`](../../../../schema/extensions/hospitality/consideration/v1/README.md) |
| `hospitality/performance/v1` | See pack README | [`schema/extensions/hospitality/performance/v1/README.md`](../../../../schema/extensions/hospitality/performance/v1/README.md) |
| `hospitality/contract/v1` | See pack README | [`schema/extensions/hospitality/contract/v1/README.md`](../../../../schema/extensions/hospitality/contract/v1/README.md) |
| `core/localization/v1` | See pack README | [`schema/extensions/core/localization/v1/README.md`](../../../../schema/extensions/core/localization/v1/README.md) |
| `core/payment/v1` | See pack README | [`schema/extensions/core/payment/v1/README.md`](../../../../schema/extensions/core/payment/v1/README.md) |
| `core/address/v1` | See pack README | [`schema/extensions/core/address/v1/README.md`](../../../../schema/extensions/core/address/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `cancellation, cash-on-delivery, age-verification, group-order, pre-order` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

