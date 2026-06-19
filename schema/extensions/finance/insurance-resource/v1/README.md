# insurance-resource/v1 — InsuranceProduct

**Domain:** finance  
**Extends:** `beckn:Resource.resourceAttributes`  
**Stage:** `publish_catalog`  
**JSON-LD Type:** `ion:InsuranceProduct`  
**Context:** `https://schema.ion.id/finance/insurance-resource/v1/context.jsonld`

## Purpose

Carries insurance product catalog data published by OJK IKNB-licensed insurers.
Enforced on every resource published under CRC `FNC-insurance`.

## Key Fields

| Field | Required | Description |
|---|---|---|
| `productType` | Yes | `MOTOR_COMPREHENSIVE` \| `MOTOR_THIRD_PARTY` \| `MOTOR_FIRE_THEFT` |
| `vehicleType` | Yes | `TWO_WHEELER` \| `FOUR_WHEELER` \| `COMMERCIAL_VEHICLE` |
| `tariffZone` | Yes | `ZONE_1` through `ZONE_5` per OJK SE-06/D.05/2013 |
| `premiumRateRange` | Yes | OJK floor/ceiling `{ min, max }` (% of IDV per annum) |
| `ojkProductCode` | Yes | OJK IKNB product classification code |
| `ojkLicenseNumber` | Yes | Insurer's OJK Nomor Izin Usaha Perasuransian |
| `coverageInclusions[]` | Yes | List of covered perils |
| `standardExclusions[]` | Yes | Standard AAUI policy exclusions |
| `deductibleAmount` | No | Risiko sendiri per claim in IDR (default IDR 300.000) |
| `addOnOptions[]` | No | Optional add-on covers with premium rates |

## Applicable To

FIN-03 (Insurance) — CRC: `FNC-insurance`

Product types: `MOTOR_COMPREHENSIVE` · `MOTOR_THIRD_PARTY` · `MOTOR_FIRE_THEFT`
