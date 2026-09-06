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

See the Release 1 [policy registry](../../../../../policies/README.md) for included
IRIs and the [Trade error registry](../../../../../errors/README.md) for included
errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
