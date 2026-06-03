# ion-core/raise/v1

NP-to-NP and NP-to-ION issue ticketing. APIs: raise, on_raise, raise_status, on_raise_status, raise_details, on_raise_details.

## Attaches to
`ION network channel`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `type`
- `priority`
- `thread`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/variants/cross-cutting/v1/variant.yaml`

## Common rejection reasons

Missing `type` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
