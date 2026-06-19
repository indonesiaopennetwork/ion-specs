# motor-insurance — Reference Pattern

**Sector:** finance  
**Category:** FIN-03 Insurance  
**CRC:** FNC-insurance  
**Pattern IRI:** `ion://flow/finance/FIN-03/FNC-insurance/motor-insurance/v1`  
**Status:** Draft  
**Version:** 1.0.0

## Overview

The `motor-insurance` pattern is the reference transaction flow for standalone insurance purchase on the ION network. A policyholder (BAP) discovers motor vehicle insurance products from an OJK-licensed insurer (BPP), submits a vehicle + KYC application, receives an underwriting decision and premium quote, pays the premium, and receives a digital policy certificate.

This pattern covers:
- **MOTOR_COMPREHENSIVE** (Asuransi All-Risk) — partial + total loss + TPL
- **MOTOR_THIRD_PARTY** (Asuransi TLO) — total loss ≥ 75% only
- **MOTOR_FIRE_THEFT** (Asuransi Kebakaran & Pencurian) — fire, theft

## Participants

| Role | Description |
|---|---|
| BAP | Policyholder App Platform — aggregator, bank app, insurer's own digital channel |
| BPP | Insurer Platform — OJK IKNB-licensed general insurance company |
| ION_CATALOG | ION Catalogue Service (product discovery) |

## Happy Path Summary

1. **Catalog** — Insurer publishes products to ION catalog with coverage types, OJK tariff zones, vehicle categories, and license details
2. **Search** — Policyholder searches by vehicle type, coverage type, and tariff zone
3. **on_search** — Insurer returns matching products with indicative premium range
4. **Select** — Policyholder selects product + provides vehicle details (make, model, year, STNK number, IDV)
5. **on_select** — Insurer returns premium quote (OJK tariff-compliant), required documents, inspection requirements
6. **Init** — Policyholder submits full application (KYC, vehicle ownership proof, inspection evidence, payment method)
7. **on_init** — Insurer returns final premium breakdown, policy schedule draft, coverage start/end dates
8. **Confirm** — Policyholder accepts terms + pays premium (full upfront or instalment)
9. **on_confirm** — Insurer issues policy — returns policy number, certificate URL, coverage details

See [docs/01-happy-path.md](docs/01-happy-path.md) for the narrative walkthrough.

## Variant Windows

| Variant | Window | Condition |
|---|---|---|
| kyc-verification | `init → on_init` | When policyholder `kycStatus ≠ APPROVED` |
| underwriting | `select → on_init` | Always — risk classification on every quote |
| claim-settlement | `on_confirm → on_status[EXPIRED]` | Triggered by FNOL notification |
| policy-renewal | `on_status[RENEWAL_DUE] → on_status[RENEWED \| EXPIRED]` | 30 days before expiry |
| endorsement | `on_confirm → on_status[EXPIRED]` | Mid-policy change requests |
| cross-cutting | `on_confirm → contract_COMPLETE` | Always active |

## Schema Packs Required

| Slot | Pack | Stage |
|---|---|---|
| Resource | `schema/extensions/finance/insurance-resource/v1` | publish_catalog |
| Offer | `schema/extensions/finance/insurance-offer/v1` | on_select |
| Contract | `schema/extensions/finance/insurance-contract/v1` | on_confirm |
| Participant | `schema/extensions/finance/insurance-participant/v1` | on_confirm |
| Consideration | `schema/extensions/finance/insurance-consideration/v1` | on_confirm |
| Performance | `schema/extensions/finance/insurance-performance/v1` | on_confirm + on_status |

## Regulatory Basis

- OJK SE-06/D.05/2013 — Motor vehicle insurance premium tariff (zone-based floor/ceiling)
- OJK POJK 23/2023 — Consumer protection disclosures (SPPA, ringkasan polis)
- UU 40/2014 — Insurance law (product licensing, claim obligations)
- OJK SP-30/D.05/2020 — eKYC requirements for insurance distribution
