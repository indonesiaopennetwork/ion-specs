# trade/offer/v1

Terms of sale — cancellation, returns, warranties, COD, promotions.

## Attaches to
`beckn:Offer.offerAttributes`

## Schema layers

`TradeOffer` inherits from upstream `RetailOffer/v2.1` and carries 27 local network-agnostic offer properties. `IONTradeOffer` inherits from `TradeOffer` and carries 5 local ION-specific property groups: policy overlays, payment eligibility, language policy, domestic-logistics weight slabs, and offer customization groups. The root of `schema.json` resolves to `IONTradeOffer`.

## Customization groups

`customization.groups` publishes the choices available for an offer. Each group
declares its selection rule and its available options; an option may include a
fixed or percentage price delta and may refer to another Resource or Offer.
The buyer's chosen group and option codes are recorded later in
`IONTradeCommitment.selectedCustomizations`.

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
buyer finder fee the seller pays the buyer app is on the offer's consideration
(`considerationAttributes.buyerFinderFee`,
[`TradeConsideration/v1`](../../TradeConsideration/v1/README.md)), not part of
this policy.

```json
"policies": {
  "settlement": { "settlementBasis": "AFTER_DELIVERY", "settlementWindow": "P1D" }
}
```

## Examples

- [`examples/food-offer.json`](examples/food-offer.json) — an F&B offer with customization groups, policies, and settlement terms.
- [`examples/electronics-offer.json`](examples/electronics-offer.json) — an electronics offer with its policies and settlement terms.

## Implementation guidance

The following fields are implementation guidance rather than normative Release 1
requirements:

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
| v1 | 2026-10-19 | `policies.settlement`: the seller's payout terms (`settlementBasis`, `settlementWindow`) per offer |
| v1 | 2026-11-15 | Added native ION offer customization groups and options |
