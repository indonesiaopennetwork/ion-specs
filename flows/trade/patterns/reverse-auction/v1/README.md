# Procurement Reverse Auction (AUC-R)

Buyer publishes requirement; sellers bid down. Lowest valid bid wins.

## Applicable categories
Government procurement (LKPP), corporate procurement, hospital supply, agritech bulk buying

## Mechanism
- BAP publishes RFQ via `/discover` with procurement intent (ceiling price, spec, delivery deadline)
- Multiple BPPs respond via `on_discover` with their quotes
- BAP evaluates (price, delivery time, compliance, track record) and sends `/select` to winner
- Winner proceeds: on_select → init → on_init → confirm → on_confirm → standard fulfilment

## Key fields
`rfq_id`, `ceiling_price`, `submission_deadline`, `tkdn_percentage`, `technical_compliance`, `incoterms` (for export procurement)

## Performance state machine
`performance-states/v1/states.yaml#standard`
Standard delivery machine from DISPATCHED onwards (post procurement fulfilment).

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`releases/release1/schema/extension/trade/TradeResource/v1/README.md`](../../../../releases/release1/schema/extension/trade/TradeResource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`releases/release1/schema/extension/trade/TradeOffer/v1/README.md`](../../../../releases/release1/schema/extension/trade/TradeOffer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`releases/release1/schema/extension/trade/TradeCommitment/v1/README.md`](../../../../releases/release1/schema/extension/trade/TradeCommitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`releases/release1/schema/extension/trade/TradeConsideration/v1/README.md`](../../../../releases/release1/schema/extension/trade/TradeConsideration/v1/README.md) |
| `trade/contract/v1` | See pack README | [`releases/release1/schema/extension/trade/TradeContract/v1/README.md`](../../../../releases/release1/schema/extension/trade/TradeContract/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

