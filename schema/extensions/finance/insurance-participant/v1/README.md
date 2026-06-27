# insurance-participant/v1 — Policyholder / Insurer

**Domain:** finance  
**Extends:** `beckn:Contract.participants[].participantAttributes`  
**Stage:** `on_confirm`  
**JSON-LD Types:** `ion:Policyholder` · `ion:Insurer`  
**Context:** `https://schema.ion.id/finance/insurance-participant/v1/context.jsonld`

## Purpose

Identity attributes for the two primary participants in an insurance transaction:
the policyholder and the insurer. Policyholder KYC data is verified via
the `kyc-verification` variant.

## Policyholder Fields

| Field | Required | Description |
|---|---|---|
| `nik` | Yes | 16-digit KTP national ID |
| `npwp` | Conditional | Tax ID — required when annual premium > IDR 5 juta |
| `driverLicenseType` | No | SIM class (SIM_A, SIM_B1, SIM_B2, SIM_C, SIM_D) |
| `kycStatus` | Yes | eKYC result per OJK SP-30/D.05/2020 |
| `kycExpiry` | No | Date when kycStatus expires |

## Insurer Fields

| Field | Required | Description |
|---|---|---|
| `ojkIknbLicense` | Yes | OJK IKNB operating license number |
| `companyName` | Yes | Full legal entity name |
| `lossPayeeIfAny` | No | Loss payee name for bancassurance-linked policies |

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`
