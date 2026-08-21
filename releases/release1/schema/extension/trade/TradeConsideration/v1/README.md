# trade/consideration/v1

Retail monetary consideration with ION tax-detail refinement.

## Attaches to
`beckn:Consideration.considerationAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

RetailConsideration v2.1 requires:

- `currency`
- `totalAmount`

Each inherited `taxDetail` requires `rate`. ION policy determines when
`taxRegime` and `taxCategory` are required.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

Missing `taxDetail.rate` or an invalid ION `taxRegime` may be rejected. See
the Release 1 [Trade error registry](../../../../../errors/README.md) for included
errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
