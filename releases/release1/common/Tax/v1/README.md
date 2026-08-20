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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `taxRegime`
- `taxCategory`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/README.md`

## Common rejection reasons

Missing `taxRegime` where required by ION policy → `ION-8xxx`. See
`errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
