# insurance-contract/v1 — InsurancePolicy

**Domain:** finance  
**Extends:** `beckn:Contract.contractAttributes`  
**Stage:** `on_confirm`  
**JSON-LD Type:** `ion:InsurancePolicy`  
**Context:** `https://schema.ion.id/finance/insurance-contract/v1/context.jsonld`

## Purpose

Carries the issued insurance policy record after premium is paid and policy
is activated. Contains policy number, digital certificate URL, coverage dates,
sum insured, and claims history.

## Key Fields

| Field | Required | Description |
|---|---|---|
| `policyNumber` | Yes | Unique policy number from insurer's PMS |
| `certificateUrl` | Yes | HTTPS URL to digital policy certificate PDF |
| `policyStatus` | Yes | `ACTIVE` \| `LAPSED` \| `CANCELLED` \| `EXPIRED` \| `CLAIMED` \| `TOTAL_LOSS` |
| `coverageStartDate` | Yes | Coverage start date (YYYY-MM-DD) |
| `coverageEndDate` | Yes | Coverage end date (YYYY-MM-DD) |
| `sumInsuredIDR` | Yes | Maximum sum insured in IDR |
| `actualIDV` | Yes | Insured Declared Value frozen at issuance |
| `policyConsentRef` | No | SPPA digital consent reference |
| `ojkPolicyReference` | No | OJK IKNB regulatory reference |
| `beneficiaryDetails` | No | Named beneficiary or loss payee (bancassurance) |
| `claimsHistory[]` | No | Claim records — reference, date, type, status, amount |
| `addOnPolicyCertificateUrls[]` | No | Certificate URLs for add-on covers |

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`
