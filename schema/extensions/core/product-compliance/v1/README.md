# ion-core/product/v1

Indonesian product certifications — halal status (MUI), BPOM, SNI, age restriction.

## Attaches to
`beckn:Resource.resourceAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `halalStatus`
- `ageRestricted`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Required for catalogue indexing

> **Silent non-indexing warning.** minimalForDiscovery includes `halalStatus` and `ageRestricted` — missing either causes the resource to be accepted but not indexed for discovery.

## Used in

`flows/trade/README.md`

## Common rejection reasons

Missing `halalStatus` → `ION-8xxx`. Missing `ageRestricted` → `ION-8xxx`. Both required for all trade resources. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
