# consideration/v1 — Credit Consideration Attributes
> **Schema evolution note (v1.1):** This pack does not yet implement the generic/ION-specific two-schema split pattern (as established in `trade/` and `logistics/` packs). The split — separating a generic `Consideration` layer (inheriting from upstream Beckn) from an `IONConsideration` ION-specific layer — is planned for v1.1 of this pack. This pack is pre-production; the split will be applied before any production traffic is carried on the finance sector. Tracked in the ION spec issue register as ION-7.

Attaches to: **`Consideration.considerationAttributes`**

Schema: `IONLoanConsideration` — the monetary value exchanged under the credit contract (principal disbursed plus fees).

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `approvedPrincipal` | number | Yes | Disbursed principal in IDR |
| `currency` | string | Yes | ISO 4217 code (default: IDR) |
| `totalFeesIDR` | number | No | Total upfront fees at akad signing |
| `aprEquivalent` | number | No | All-in annualised cost of credit % |

## Regulatory note

`aprEquivalent` is mandatory for RIPLAY disclosure per **POJK 6/POJK.07/2022**.
It must equal the value in `offer/v1` `CreditOffer.totalFees.aprEquivalent` at the time of offer acceptance.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
