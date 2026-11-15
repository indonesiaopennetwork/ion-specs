# Trade Offer Extension — Overview

Terms of sale. Every commercial condition a buyer needs to know before committing to purchase.

## Schema layers

The pack has two layers. `TradeOffer` contains generic offer mechanics that can apply in any trade network. `IONTradeOffer` extends it with ION policy-registry fields, Indonesian payment-method eligibility, ION language policy, domestic IDR weight slabs, and offer customization groups. Property definitions are intentionally unchanged in this structural split and will be reviewed separately against upstream `RetailOffer/v2.1`.

## Customizations

`customization.groups` declares the selectable groups and options offered to a
buyer. A group specifies whether selection is required or optional and whether
one or multiple options may be chosen. Options can carry price deltas and can
reference Resources or Offers. The selected group and option codes become
`IONTradeCommitment.selectedCustomizations` when the buyer selects the offer.

## Policy IRIs
ION encodes standard policies as IRI strings — not freeform text. This enables machine-readable policy enforcement:
- `ion://policy/return.7d.sellerpays` — 7-day return, seller pays pickup
- `ion://policy/cancel.prepacked.free` — free cancellation before packed
- `ion://policy/warranty.1y.manufacturer` — 1-year manufacturer warranty
- `ion://policy/dispute.consumer.bpsk` — consumer dispute via BPSK
- `ion://policy/dispute.commercial.bani` — commercial dispute via BANI

## returnAllowedReasons
DEFECTIVE and DAMAGED_IN_TRANSIT are always implied by UU 8/1999 regardless of what this list says. The list declares additional reasons the seller accepts — CHANGE_OF_MIND, WRONG_ITEM_SENT etc.

## Promotions
`offerType = DISCOUNT/BUNDLE/CASHBACK/VOUCHER/AUCTION/FLASH_SALE`, `voucherCode`, `stackingGroup`, `stackingRules`, and `subsidyBreakup` (which party funds the promotion: seller, platform, or brand).
