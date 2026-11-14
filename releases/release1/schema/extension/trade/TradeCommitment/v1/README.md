# trade/commitment/v1

Trade-specific attributes attached to a Beckn Commitment. The core Commitment
object carries its identity, resources, quantities, and selected offer. This pack
carries committed prices, selected add-ons, customizations, special instructions,
and replacement preference.

## Attaches to
`beckn:Commitment.commitmentAttributes`

See `attributes.yaml` for complete field definitions.

## Core and extension responsibilities

Use these core locations as the authoritative commitment references:

- `Commitment.id`
- `Commitment.resources[].resource.id`
- `Commitment.resources[].quantity`
- `Commitment.offer.id`

Do not repeat those values in `commitmentAttributes`. The extension properties
are optional unless an active flow or business rule requires them.

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
| v1 draft | 2026-11-09 | Removed RetailCommitment inheritance and duplicate core reference fields; retained the trade-specific fields directly. |
| v1 | 2026-06-02 | Initial release |
