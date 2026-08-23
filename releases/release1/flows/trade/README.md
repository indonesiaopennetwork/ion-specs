# Release 1 Trade flows

Release 1 includes seven validated reference flows:

- [`storefront/v1`](patterns/storefront/v1/) — a standard B2C purchase of a
  packaged physical product, from catalog publication through delivery.
- [`made-to-order/v1`](patterns/made-to-order/v1/) — goods prepared or assembled
  after confirmation, with preparation states and a concrete cancellation
  policy that closes at `PREPARING`.
- [`live-commerce/v1`](patterns/live-commerce/v1/) — standard Beckn commerce
  initiated from live, OTT, social, or attributed content, with time-bounded
  offers and source attribution.
- [`digital-goods/v1`](patterns/digital-goods/v1/) — electronically delivered
  vouchers and subscriptions using the Digital Goods performance states,
  without a physical shipping leg.
- [`business-procurement/v1`](patterns/business-procurement/v1/) — registered
  business wholesale procurement with minimum quantities, purchase-order
  linkage, tax invoicing, and upfront payment.
- [`marketplace-inhouse/v1`](patterns/marketplace-inhouse/v1/) — first-party or
  consignment marketplace commerce fulfilled from marketplace-held inventory.
- [`marketplace-listed/v1`](patterns/marketplace-listed/v1/) — third-party
  marketplace routing from a marketplace BAP to an independent seller BPP.

The remaining root Trade patterns and variants are non-normative work in
progress. Subscription requires non-Beckn actions. Cross-Border depends on the
excluded Logistics customs contract and states. Government and both auction
patterns lack standalone schemas for their defining wire objects and currently
use ad hoc tags. They were reviewed but not copied into Release 1.

All included patterns use only the nine Release 1 Trade packs and the included
Address, Business Registration, Payment, and Tax common packs. Individual flows
declare the subset they require. Their schema and context references remain
inside Release 1.

## Included variants

- [`variants/during-transaction/v1`](variants/during-transaction/v1/) — six
  transaction-time branches covering fulfilment-mode selection, BAP prepayment,
  two COD collection models, multi-performance fulfilment, and cancellation-fee
  display. Four incompatible source sub-branches are explicitly excluded in the
  variant definition.

Other root variants remain non-normative until they are reviewed individually.
