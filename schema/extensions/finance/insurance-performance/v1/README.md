# insurance-performance/v1 — PolicyPerformance

**Domain:** finance  
**Extends:** `beckn:Contract.performance[].performanceAttributes`  
**Stage:** `on_confirm` + `on_status`  
**JSON-LD Type:** `ion:PolicyPerformance`  
**Context:** `https://schema.ion.id/finance/insurance-performance/v1/context.jsonld`

## Purpose

Coverage period tracking and policy lifecycle state machine. Updated on
every `on_status` callback to reflect current policy state. Drives
variant activation (claim-settlement, policy-renewal).

## Key Fields

| Field | Required | Description |
|---|---|---|
| `policyState` | Yes | Current lifecycle state (see state machine below) |
| `coveragePeriodStart` | Yes | Coverage start date |
| `coveragePeriodEnd` | Yes | Coverage end date |
| `nextRenewalDueDate` | Yes | T−30 days before coveragePeriodEnd |
| `claimCount` | No | Total claims filed this period (default 0) |
| `ncdPercentage` | No | No Claims Discount % earned (0–25%) |
| `remainingSumInsuredIDR` | No | Sum insured remaining after claims |

## Policy State Machine

```
PENDING_ISSUANCE
    ↓ (on_confirm)
ACTIVE
    ↓ (FNOL)              ↓ (T−30 days before expiry)
CLAIM_FILED          RENEWAL_DUE
    ↓                     ↓            ↓ (no renewal)
CLAIM_SETTLED         RENEWED        EXPIRED
    ↓ (if total loss)
TOTAL_LOSS
    
CANCELLED  ←  (endorsement/cancellation variant)
LAPSED     ←  (renewal premium not paid)
```

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`
