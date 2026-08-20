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

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — used in all trade patterns`

## Common rejection reasons

Missing `taxDetail.rate` or an invalid ION `taxRegime` may be rejected. See
`errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
