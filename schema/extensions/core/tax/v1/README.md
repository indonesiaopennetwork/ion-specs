# ion-core/tax/v1

Indonesian tax detail — PPN, PPnBM, PPh regimes. BKP/JKP/NON_BKP classification.

## Attaches to
`beckn:Consideration.considerationAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `taxRegime`
- `taxCategory`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/README.md`

## Common rejection reasons

Missing `taxRegime` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
