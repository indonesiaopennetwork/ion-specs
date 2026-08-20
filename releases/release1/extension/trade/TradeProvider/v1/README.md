# trade/provider/v1

Trade-sector provider attributes covering operational availability, operating
hours, serviceability, invoicing, logistics, commerce channels, and verification.

## Attaches to
`beckn:Provider.providerAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `operationalStatus.status`
- `businessRegistration.nib`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## ION-specific refinements

- `businessRegistration` composes `IONBusinessRegistration`; the actual `nib`
  replaces the former registration boolean.
- `trustMarks[]` contains signed or verifiable Beckn Documents instead of a
  self-declared trusted-seller flag.
- `verification.level` adds the ION verification tier to the generic
  verification summary.
- `categoryLicenses[]` records category scope, licence identifiers, validity,
  issuer, and typed documentary evidence.

## Per-step required fields

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — catalog publish step`

## Common rejection reasons

Invalid `operationalStatus.status` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
