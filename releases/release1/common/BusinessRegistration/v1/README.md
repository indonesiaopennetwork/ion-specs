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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `npwp`
- `nib`
- `pkpStatus`
- `legalEntityName`
- `businessType`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Participant attachment note

`Participant` in Beckn v2.0 does not have a `participantAttributes` bag. Fields from this pack attach as **direct properties on the `Participant` object**. Do not wrap them in a `participantAttributes` sub-object — ONIX will reject the payload.

## Used in

`flows/trade/README.md`

## Common rejection reasons

Missing `npwp` → `ION-8xxx`. Missing `nib` → `ION-8xxx`. These fields are always required for every network participant. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
