# FNC-insurance — Insurance Products

**Sector:** finance  
**Category:** FIN-03 Insurance  
**CRC Code:** `FNC-insurance`  
**CRC Status:** ACTIVE  
**Pattern:** `motor-insurance` (reference pattern)  
**Pattern IRI:** `ion://flow/finance/FIN-03/FNC-insurance/motor-insurance/v1`

## What This CRC Covers

`FNC-insurance` is the single ION Catalogue Resource Category for all OJK-licensed insurance products under FIN-03. It enforces the `schema/extensions/finance/insurance-resource/v1` attribute pack on every insurance product published to the catalog.

Product-type differentiation is carried by `resourceAttributes.productType`:

| `productType` | Indonesian Product | Coverage | Mandatory Fields |
|---|---|---|---|
| `MOTOR_COMPREHENSIVE` | Asuransi Kendaraan All-Risk | Total loss + partial damage + TPL | IDV, tariff zone, vehicle details |
| `MOTOR_THIRD_PARTY` | Asuransi TLO (Total Loss Only) | Total loss ≥ 75% only | IDV, tariff zone, vehicle details |
| `MOTOR_FIRE_THEFT` | Asuransi Kebakaran & Pencurian | Fire, theft, partial loss excluded | Sum insured, storage address |

## Pattern

| Pattern | IRI | Description |
|---|---|---|
| `motor-insurance` | `ion://flow/finance/FIN-03/FNC-insurance/motor-insurance/v1` | Full Beckn transaction flow: catalog → search → select → init → confirm → fulfilment → post-fulfilment |

## Applicable Variants

All variants are shared at the FIN-03 category level:

| Variant | Active For |
|---|---|
| [kyc-verification](../../variants/kyc-verification/v1/variant.yaml) | All product types |
| [underwriting](../../variants/underwriting/v1/variant.yaml) | All product types |
| [claim-settlement](../../variants/claim-settlement/v1/variant.yaml) | All product types |
| [policy-renewal](../../variants/policy-renewal/v1/variant.yaml) | All product types |
| [endorsement](../../variants/endorsement/v1/variant.yaml) | All product types |
| [cross-cutting](../../variants/cross-cutting/v1/variant.yaml) | All product types |

## Reference Path Examples

```
finance / FIN-03 / FNC-insurance / motor-insurance / underwriting
finance / FIN-03 / FNC-insurance / motor-insurance / kyc-verification
finance / FIN-03 / FNC-insurance / motor-insurance / claim-settlement
finance / FIN-03 / FNC-insurance / motor-insurance / policy-renewal
finance / FIN-03 / FNC-insurance / motor-insurance / endorsement
```

## Schema Attribute Pack

`FNC-insurance` enforces `schema/extensions/finance/insurance-resource/v1` at `catalog/publish` time.  
Key mandatory fields on `Resource.resourceAttributes`:

- `productType` — one of `MOTOR_COMPREHENSIVE | MOTOR_THIRD_PARTY | MOTOR_FIRE_THEFT`
- `vehicleType` — `TWO_WHEELER | FOUR_WHEELER | COMMERCIAL_VEHICLE`
- `ojkProductCode` — OJK IKNB product classification code
- `ojkLicenseNumber` — Nomor Izin Usaha Perasuransian from OJK
- `tariffZone` — `ZONE_1` through `ZONE_5` per OJK SE-06/D.05/2013
- `premiumRateRange.min` and `premiumRateRange.max` — OJK tariff floor/ceiling per zone
