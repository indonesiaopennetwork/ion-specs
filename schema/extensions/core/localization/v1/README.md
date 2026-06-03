# ion-core/localization/v1

Multilingual text objects. Language-keyed with ISO 639-1 codes. 'id' always required.

## Attaches to
`beckn:Resource.resourceAttributes, beckn:Provider.descriptor`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `name.id`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/README.md`

## Common rejection reasons

Missing `name.id` (Bahasa Indonesia name) → `ION-8xxx`. Every resource must have a Bahasa Indonesia name. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
