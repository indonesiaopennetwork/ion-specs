# Forward Auction (AUC-F)

English ascending auction. Seller sets starting price; buyers bid up. Highest bid wins.

## Applicable categories
Agritech produce lots (coffee, cocoa, mangoes), collectibles, excess inventory clearance, used electronics, art

## Mechanism
- Offer carries `offerType = AUCTION`, `validity.startDate`, `validity.endDate`, `min_bid_increment`, `reserve_price_set`
- `/select` = bid submission (bid amount in offer.price)
- `on_select` acknowledges: LEADING / OUTBID / REJECTED
- BPP sends unsolicited `on_select` when bidder is outbid
- At auction close: BPP sends unsolicited `on_update[AUCTION_CLOSED]` to winner
- Winner proceeds: init → on_init → confirm → on_confirm → standard fulfilment

## Post-award
Identical to B2C-SF from init onwards. Cancellation typically not permitted after confirm for auction winners.

## Performance state machine
`performance-states/v1/states.yaml#standard`
Standard delivery machine from DISPATCHED onwards (post auction-award fulfilment).

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`schema/extensions/trade/resource/v1/README.md`](../../../../schema/extensions/trade/resource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`schema/extensions/trade/offer/v1/README.md`](../../../../schema/extensions/trade/offer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`schema/extensions/trade/commitment/v1/README.md`](../../../../schema/extensions/trade/commitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`schema/extensions/trade/consideration/v1/README.md`](../../../../schema/extensions/trade/consideration/v1/README.md) |
| `trade/contract/v1` | See pack README | [`schema/extensions/trade/contract/v1/README.md`](../../../../schema/extensions/trade/contract/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

