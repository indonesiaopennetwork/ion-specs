# ion-core/tax/v1

Indonesia-specific extension of the tax detail carried by each tax entry in
`RetailConsideration.breakup[]`.

## Attaches to
`beckn:Consideration.considerationAttributes.breakup[].taxDetail`

See `attributes.yaml` for complete field definitions.

## Canonical monetary fields

The generic monetary fields are inherited from RetailConsideration v2.1:

- `rate` — applicable tax rate as a decimal fraction
- `included` — whether tax is included in the price
- `taxableBase` — amount to which the rate applies

The containing breakup entry's `amount` is the calculated tax amount.
`IONTaxDetail` adds only `taxRegime`, `taxCategory`, and `eFakturRef`.

## Implementation guidance

The following fields are implementation guidance rather than normative Release 2
requirements:

- `taxRegime`
- `taxCategory`

This is not a normative Release 2 requirement. Release 2 validation is defined by
the standalone schema and included Trade flow material.

## Used in

[Release 2 Trade flow](../../../../flows/trade/README.md)

## Common rejection reasons

See the Release 2 [Trade error registry](../../../../errors/README.md) for the error
codes included in this release.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
