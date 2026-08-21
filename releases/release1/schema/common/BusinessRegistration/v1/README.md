# ion-core/identity/v1

Indonesian business KYC identifiers and licensing.

## Attaches to
`beckn:Provider.providerAttributes` and `beckn:Contract.contractAttributes`

## Fields
| Field | Type | Mandatory | Description |
|---|---|---|---|
| npwp | string(16) | always | Tax ID — Nomor Pokok Wajib Pajak |
| nib | string(13) | always | Business registration — Nomor Induk Berusaha |
| nikNumber | string(16) | conditional | National ID — for individual sellers |
| pkpStatus | enum | always | VAT registration: PKP or NON_PKP |
| legalEntityName | string | always | Registered business name |
| businessType | enum | always | PT/CV/UD/PERORANGAN etc. |
| siupNumber | string | optional | Trade license (legacy, being replaced by NIB) |
| spPIRTNumber | string | optional | Small-scale food production license |

## Regulatory
PMK 136/2023, PP 5/2021, UU 24/2013

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `npwp`
- `nib`
- `pkpStatus`
- `legalEntityName`
- `businessType`

This is not a normative Release 1 requirement. Release 1 validation is defined by
the standalone schema and included Trade flow material.

## Participant attachment note

`Participant` in Beckn v2.0 does not have a `participantAttributes` bag. Fields from this pack attach as **direct properties on the `Participant` object**. Do not wrap them in a `participantAttributes` sub-object — ONIX will reject the payload.

## Used in

[Release 1 Trade flow](../../../../flows/trade/README.md)

## Common rejection reasons

Applications may enforce `npwp` or `nib` according to their operating policy, but
Release 1 does not define an aggregate network-wide requirement for them.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
