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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

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

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Per-step required fields

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — used in all trade patterns`

## Common rejection reasons

Unknown policy IRI → `ION-2xxx`. Missing `contactDetailsConsumerCare` → `ION-8xxx`. Missing policy IRIs → `ION-8xxx`. See `policies/README.md` for valid IRIs. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
