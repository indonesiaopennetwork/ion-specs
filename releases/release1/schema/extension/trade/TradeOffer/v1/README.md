# trade/offer/v1

Terms of sale — cancellation, returns, warranties, COD, promotions.

## Attaches to
`beckn:Offer.offerAttributes`

## Schema layers

`TradeOffer` inherits from upstream `RetailOffer/v2.1` and carries 27 local network-agnostic offer properties. `IONTradeOffer` inherits from `TradeOffer` and carries 4 local ION-specific properties: policy overlays, payment eligibility, language policy, and domestic-logistics weight slabs. The root of `schema.json` resolves to `IONTradeOffer`.

## Policy IRIs
ION uses IRI-encoded policy identifiers for canonical terms:

### Return policies
- `ion://policy/return.7d.sellerpays` — 7-day return, seller arranges pickup
- `ion://policy/return.15d.sellerpays` — 15-day return, seller pays
- `ion://policy/return.7d.buyerpays` — 7-day return, buyer ships back
- `ion://policy/return.standard.none` — no returns

### Cancellation policies
- `ion://policy/cancel.prepacked.free` — free cancellation before packed
- `ion://policy/cancel.mto.nofee-before-prepare` — MTO free before preparation
- `ion://policy/cancel.standard.none` — no cancellation

### Warranty policies
- `ion://policy/warranty.1y.manufacturer`
- `ion://policy/warranty.2y.manufacturer`
- `ion://policy/warranty.standard.none`

### Dispute policies
- `ion://policy/dispute.consumer.bpsk` — B2C via BPSK
- `ion://policy/dispute.commercial.bani` — B2B via BANI arbitration

## Settlement policy

`policies.settlement` states the seller's payout terms for orders of the offer:

| Field | Meaning |
|---|---|
| `settlementBasis` | Event the payout clock starts from: `ON_CONFIRMATION`, `AFTER_SHIPMENT`, `AFTER_DELIVERY`, `AFTER_RETURN_WINDOW` |
| `settlementWindow` | ISO 8601 duration after that event within which the seller is paid, e.g. `P1D` |
| `policyRef` | Optional ION-registered settlement policy URI |

The payout falls due `settlementWindow` after the `settlementBasis` event. When
an order has several offers, the term giving the latest due date applies to the
whole contract. `SettlementBasis` and `SettlementWindow` are defined in
[`common/Settlement/v1`](../../../../common/Settlement/v1/README.md). The
commission the seller pays the buyer app is `policies.commission`, not part of
this policy.

```json
"policies": {
  "settlement": { "settlementBasis": "AFTER_DELIVERY", "settlementWindow": "P1D" }
}
```

## Commission policy

`policies.commission` states the commission the seller (BPP) pays the buyer app
(BAP) for orders of the offer. It is deducted from the seller's payout; it is
not a charge to the buyer and is not part of `breakup` or `totalAmount`. It is
an array of named entries (`IONOfferCommission`, at least one), and the
entries add up:

| Field | Meaning |
|---|---|
| `name` | Name of the entry, e.g. `Finder fee`, `Platform fee` (required) |
| `type` | `PERCENT` or `AMOUNT` (required) |
| `value` | Percentage (0-100) for `PERCENT`; an amount per unit sold for `AMOUNT` (required) |
| `appliesTo` | `PERCENT` only: `ITEM_TOTAL` (the offer's item value excluding tax; default) or `ORDER_TOTAL` (including tax) |

```json
"policies": {
  "commission": [
    { "name": "Finder fee", "type": "PERCENT", "value": 3, "appliesTo": "ITEM_TOTAL" },
    { "name": "Platform fee", "type": "AMOUNT", "value": 250 }
  ]
}
```

The BPP states what an order comes to on the contract's price consideration
(`IONTradeConsideration.commission`, see
[`TradeConsideration/v1`](../../TradeConsideration/v1/README.md)): `amount` is
the sum over every offer still ordered of all its entries, and the settlement's
`commission.value` equals it at reconciliation.

## Examples

- [`examples/food-offer.json`](examples/food-offer.json) — an F&B offer with its policies and settlement terms.
- [`examples/electronics-offer.json`](examples/electronics-offer.json) — an electronics offer with its policies and settlement terms.
- [`examples/offer-commission.json`](examples/offer-commission.json) — an offer with two commission entries (a finder fee and a platform fee).

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `policies.cancellation.policyRef`
- `policies.returns.policyRef`
- `policies.warranty.policyRef`
- `policies.dispute.policyRef`
- `policies.grievanceSla.policyRef`
- `policies.paymentTerms.policyRef`
- `policies.cancellation.allowed` (inherited from RetailOffer)
- `policies.returns.allowed` (inherited from RetailOffer)
- `contactDetailsConsumerCare`
- `paymentConstraints.codAvailable` (inherited from RetailOffer)
- `timeToShip`

This is not a normative Release 1 requirement. Per-step requirements must come
from Trade flow material included in the release.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

See the shared [policy registry](../../../../../../../policies/README.md) for registered
IRIs and the [Trade error registry](../../../../../errors/README.md) for included
errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 | 2026-10-19 | `policies.settlement`: the seller's payout terms (`settlementBasis`, `settlementWindow`) per offer; `policies.commission` (`IONOfferCommission`): the named commission entries the seller pays the buyer app |
