# ION Finance Sector Extension Packs

**Sector:** `ion:finance`  
**Path:** `schema/extensions/finance/`

These schema packs define ION-specific attributes attached to Beckn 2.0 protocol objects for all Finance (FIN-XX) transactions.

## Extensions

| Extension | Beckn Attachment | Stage | Description |
|---|---|---|---|
| [resource/v1](resource/v1/) | `Resource.resourceAttributes` | on_discover | Credit product template — ranges, eligibility, cost-of-fund, regulatory declarations |
| [offer/v1](offer/v1/) | `Offer.offerAttributes` | on_select | Per-applicant credit decision with exact approved values |
| [contract/v1](contract/v1/) | `Contract.contractAttributes` | on_confirm | Immutable signed loan agreement and SLIK status |
| [participant/v1](participant/v1/) | `Participant.participantAttributes` | on_confirm | Borrower and lender identity (NIK, NPWP, OJK license) |
| [settlement/v1](settlement/v1/) | `Settlement.settlementAttributes` | on_confirm + updates | Amortisation schedule rows |
| [performance/v1](performance/v1/) | `Performance.performanceAttributes` | on_confirm + on_status | Disbursement execution tracking |
| [consideration/v1](consideration/v1/) | `Consideration.considerationAttributes` | on_confirm | Principal, fees, APR equivalent (POJK 6/2022) |

## Applicable To

FIN-02 (Lending & Consumer Credit) — CRC: `FNC-lending`

Product types (`resourceAttributes.productType`): `KTA` · `KPR` · `KKB` · `KUR_UMKM` · `REVOLVING` · `BNPL`

---

## FIN-03 Insurance Extensions

| Extension | Beckn Attachment | Stage | Description |
|---|---|---|---|
| [insurance-resource/v1](insurance-resource/v1/) | `Resource.resourceAttributes` | publish_catalog | Insurance product template — coverage type, tariff zone, OJK license |
| [insurance-offer/v1](insurance-offer/v1/) | `Offer.offerAttributes` | on_select | Per-policyholder premium quote with approved IDV and OJK rate |
| [insurance-contract/v1](insurance-contract/v1/) | `Contract.contractAttributes` | on_confirm | Issued insurance policy — policy number, certificate URL, coverage dates |
| [insurance-participant/v1](insurance-participant/v1/) | `Participant.participantAttributes` | on_confirm | Policyholder (NIK, KYC) and insurer (OJK IKNB license) identity |
| [insurance-consideration/v1](insurance-consideration/v1/) | `Consideration.considerationAttributes` | on_confirm | Premium amounts with itemised breakup |
| [insurance-performance/v1](insurance-performance/v1/) | `Performance.performanceAttributes` | on_confirm + on_status | Coverage period state machine |

FIN-03 (Insurance) — CRC: `FNC-insurance`

Product types (`resourceAttributes.productType`): `MOTOR_COMPREHENSIVE` · `MOTOR_THIRD_PARTY` · `MOTOR_FIRE_THEFT`
