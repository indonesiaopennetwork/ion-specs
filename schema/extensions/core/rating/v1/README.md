# ion-core/rating/v1

Post-transaction rating 1-5. Categories: PROVIDER, ITEM, FULFILLMENT, AGENT. APIs: rate/on_rate.

## Attaches to
`beckn:Rate`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `ratingCategory`
- `value`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/variants/cross-cutting/v1/variant.yaml`

## Common rejection reasons

Missing `ratingCategory` → `ION-8xxx`. `value` must be 1–5. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
