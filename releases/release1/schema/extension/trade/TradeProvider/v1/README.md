# trade/provider/v1

Trade-sector provider attributes covering operational availability, operating
hours, serviceability, invoicing, logistics, commerce channels, and verification.

## Attaches to
`beckn:Provider.providerAttributes`

See `attributes.yaml` for complete field definitions.

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `operationalStatus.status`
- `businessRegistration.nib`

This is not a normative Release 1 requirement. Per-step requirements must come
from Trade flow material included in the release.

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

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — Storefront catalog
publish step.

## Common rejection reasons

See the Release 1 [Trade error registry](../../../../../errors/README.md) for the
error codes included in this release.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
