# trade/commitment/v1

Per-line trade attributes extending RetailCommitment v2.1. The upstream schema supplies line, resource, offer, quantity, committed-price, selected-customization, add-on, and special-instruction fields. This pack adds line-specific replacement preference and an ION extension point.

## Attaches to
`beckn:Commitment.commitmentAttributes`

See `attributes.yaml` for complete field definitions.

## Required fields

RetailCommitment v2.1 requires these inherited attributes:

- `lineId`
- `resourceId`
- `quantity`

ION network policy additionally requires inherited `offerId`.

These compatibility attributes overlap the current core locations
`Commitment.id`, `Commitment.resources[]`, and `Commitment.offer`. The overlap
comes from RetailCommitment v2.1 and cannot be removed by this child schema.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

Missing an inherited or network-required commitment field is rejected according
to the active ONIX validation profile. See the Release 1
[Trade error registry](../../../../../errors/README.md) for included errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
