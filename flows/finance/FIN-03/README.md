# FIN-03 — Insurance

**Sector:** finance  
**Category Code:** FIN-03  
**KBLI:** 65 (Asuransi, Reasuransi, dan Dana Pensiun)

---

## Catalogue Resource Category (CRC)

| Code | Name | Status | Pattern | Pattern IRI |
|---|---|---|---|---|
| [FNC-insurance](FNC-insurance/README.md) | Insurance Products | ACTIVE | `motor-insurance` | `ion://flow/finance/FIN-03/FNC-insurance/motor-insurance/v1` |

Product-type differentiation (MOTOR_COMPREHENSIVE, MOTOR_THIRD_PARTY, MOTOR_FIRE_THEFT) is carried by `resourceAttributes.productType` on each published resource — not by separate CRC codes.

---

## Schema Packs Used by This Sector

| Beckn Slot | Pack | Class |
|---|---|---|
| Resource | `schema/extensions/finance/insurance-resource/v1` | `InsuranceProduct` |
| Offer | `schema/extensions/finance/insurance-offer/v1` | `PolicyQuote` |
| Contract | `schema/extensions/finance/insurance-contract/v1` | `InsurancePolicy` |
| Participant | `schema/extensions/finance/insurance-participant/v1` | `Policyholder` / `Insurer` |
| Consideration | `schema/extensions/finance/insurance-consideration/v1` | `PremiumConsideration` |
| Performance | `schema/extensions/finance/insurance-performance/v1` | `PolicyPerformance` |

---

## Shared Variants

All variants live at this category level and are referenced by `FNC-insurance/motor-insurance`:

| Variant | Active For | Description |
|---|---|---|
| [kyc-verification](variants/kyc-verification/v1/variant.yaml) | All | Dukcapil eKYC, liveness detection, face-match |
| [underwriting](variants/underwriting/v1/variant.yaml) | All | Vehicle inspection, risk classification, IDV validation |
| [claim-settlement](variants/claim-settlement/v1/variant.yaml) | All | FNOL, survey, approval, settlement payment |
| [policy-renewal](variants/policy-renewal/v1/variant.yaml) | All | Pre-expiry notice, acceptance, renewal issuance |
| [endorsement](variants/endorsement/v1/variant.yaml) | All | Add-on coverage, mid-policy amendments |
| [cross-cutting](variants/cross-cutting/v1/variant.yaml) | All | Status polling, support, reconcile, rate, cancel |

---

## Regulatory Basis

- OJK POJK 23/2023 — Consumer protection in insurance sector
- OJK POJK 69/2016 — Bancassurance operations (if distributed via bank/lender)
- OJK Circular SE-06/D.05/2013 — Motor vehicle insurance tariff (premium rate ranges per zone)
- OJK Circular SP-30/D.05/2020 — eKYC requirements for insurance
- UU 40/2014 — Perasuransian (Insurance Law)
- POJK 73/POJK.05/2016 — Penyelenggaraan Usaha Perasuransian
