# insurance-offer/v1 — PolicyQuote

**Domain:** finance  
**Extends:** `beckn:Offer.offerAttributes`  
**Stage:** `on_select`  
**JSON-LD Type:** `ion:PolicyQuote`  
**Context:** `https://schema.ion.id/finance/insurance-offer/v1/context.jsonld`

## Purpose

Per-policyholder premium quote returned after vehicle risk classification and
IDV validation. Binding quote valid until `quoteValidUntil`.

## Key Fields

| Field | Required | Description |
|---|---|---|
| `approvedIDV` | Yes | Insured Declared Value in IDR (after depreciation) |
| `annualPremiumIDR` | Yes | Base annual premium (IDV × rate) |
| `ojkFinalRatePercent` | Yes | Tariff-compliant rate within OJK zone floor/ceiling |
| `tariffZone` | Yes | Zone assigned by vehicle registration domicile |
| `quoteValidUntil` | Yes | Quote expiry (ISO 8601 datetime) |
| `inclusions[]` | Yes | Confirmed covered perils |
| `specialExclusions[]` | No | Any special exclusions for this vehicle |
| `addOnPremiums[]` | No | Elected add-on covers with premiums |
| `deductible` | No | Standard risiko sendiri in IDR |
| `counterOfferIDV` | No | Insurer's counter IDV if declared was outside range |
| `inspectionRequired` | No | True if surveyor inspection is needed |
| `requiredDocuments[]` | No | List of documents required at init |
| `ncdApplied` | No | True if No Claims Discount applied (renewals) |
| `ncdPercentage` | No | NCD percentage (0–25%) applied |

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`
