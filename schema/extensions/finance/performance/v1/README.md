# performance/v1 — Credit Performance Attributes
> **Schema evolution note (v1.1):** This pack does not yet implement the generic/ION-specific two-schema split pattern (as established in `trade/` and `logistics/` packs). The split — separating a generic `Performance` layer (inheriting from upstream Beckn) from an `IONPerformance` ION-specific layer — is planned for v1.1 of this pack. This pack is pre-production; the split will be applied before any production traffic is carried on the finance sector. Tracked in the ION spec issue register as ION-7.

Attaches to: **`Performance.performanceAttributes`**

Schema: `IONDisbursementPerformance` — tracks the execution of fund disbursement after the loan contract is confirmed.

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `disbursementMethod` | enum | Yes | Transfer mechanism |
| `disbursementDate` | date | No | Actual disbursement date (YYYY-MM-DD) |
| `targetBusinessDays` | integer | No | SLA: target working days to disburse |

## `disbursementMethod` values

| Value | Description |
|---|---|
| `BANK_TRANSFER` | Direct transfer to borrower's savings account |
| `DEVELOPER_TRANSFER` | Transfer directly to property developer (KPR) |
| `DEALER_TRANSFER` | Transfer directly to vehicle dealer (KKB) |
| `CASH` | Cash disbursement at branch |
| `VIRTUAL_ACCOUNT` | Transfer via virtual account |

## Status mapping

`Performance.status.code = COMPLETE` once `disbursementDate` is set and funds confirmed.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
