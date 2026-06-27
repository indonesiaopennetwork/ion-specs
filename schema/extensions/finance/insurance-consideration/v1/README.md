# insurance-consideration/v1 — PremiumConsideration

**Domain:** finance  
**Extends:** `beckn:Contract.consideration[].considerationAttributes`  
**Stage:** `on_confirm`  
**JSON-LD Type:** `ion:PremiumConsideration`  
**Context:** `https://schema.ion.id/finance/insurance-consideration/v1/context.jsonld`

## Purpose

Total premium and itemised breakup at policy issuance. Enables full
transparency of premium components per POJK 23/2023 consumer protection
disclosure requirements.

## Key Fields

| Field | Required | Description |
|---|---|---|
| `totalPremiumIDR` | Yes | Total premium (all-in) in IDR |
| `currency` | Yes | Always `IDR` |
| `paymentFrequency` | Yes | `ANNUAL` \| `SEMI_ANNUAL` \| `QUARTERLY` \| `MONTHLY` |
| `breakup[]` | Yes | Itemised line items — see types below |
| `addOnPremiums[]` | No | Add-on cover premiums |
| `ncdDiscountIDR` | No | NCD deduction amount in IDR |

## Breakup Types

| Type | Description |
|---|---|
| `BASE_PREMIUM` | Core premium: approvedIDV × ojkFinalRatePercent |
| `ADD_ON_PREMIUM` | Optional coverage add-ons |
| `ADMIN_FEE` | Policy administration fee |
| `STAMP_DUTY` | Materai (stamp duty) per policy document |
| `TAX_PPN` | PPN (value-added tax) on commission if applicable |
| `TAX_PPH` | PPh 22 withholding tax on premium |
| `NCD_DISCOUNT` | No Claims Discount deduction (negative) |
| `LOADING` | Risk loading for high-risk profiles |

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`
