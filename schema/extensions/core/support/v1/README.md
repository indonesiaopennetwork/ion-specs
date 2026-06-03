# ion-core/support/v1

Consumer complaint ticket — buyer raises order issues to seller. APIs: support/on_support.

## Attaches to
`beckn:Support`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `type`
- `issueType`
- `complainantInfo`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/variants/cross-cutting/v1/variant.yaml`

## Common rejection reasons

Missing `type` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
