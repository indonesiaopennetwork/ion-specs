# ION Trade Contract Extension — v1

**Schemas:** `TradeContract` and `IONTradeContract`

**Attaches to:** `Contract.contractAttributes`

## Purpose

Carries trade-specific terms and state that apply to the Contract as a whole.
`TradeContract` inherits `RetailContract v2.1`; `IONTradeContract` adds only
Indonesian invoice-type and buyer-business-registration refinements.

## Inherited fields

RetailContract supplies:

- `quoteReference`
- `buyerInstructions`
- `deliveryPreferences`
- `gift`
- `invoicePreferences`
- `loyalty`
- `source`

Local refinements extend inherited `gift` and `source` without replacing their
upstream structures. `IONTradeContract.invoicePreferences` similarly retains
inherited tax ID, company name, and email properties.

## TradeContract fields

| Field | Purpose |
|---|---|
| `purchaseOrderReference` | Buyer-issued procurement reference |
| `parentContractId` | Parent Contract for a child trade transaction |
| `cancellation` | Reason, affected commitments, and forced-cancellation evidence |
| `subscription` | Recurring-contract terms and current lifecycle state |
| `source` | Inherited source with creator/content/affiliate attribution |
| `gift` | Inherited gifting preferences with recipient details |

## IONTradeContract fields

| Field | Purpose |
|---|---|
| `invoicePreferences.invoiceType` | Requested ION invoice-document type |
| `buyerBusinessRegistration` | Composed Indonesian buyer registration |

Use inherited `invoicePreferences.taxId` for an invoice tax identifier:

```json
{
  "scheme": "NPWP",
  "country": "ID",
  "value": "1234567890123456"
}
```

## Ownership boundaries

- Fulfilment centre selection belongs to `TradePerformance`.
- Credit terms, payment due dates, and payment declarations belong to
  `IONPayment` on `Settlement.settlementAttributes`.
- COD and price changes belong to `TradeConsideration`.
- Payment events belong to core Settlement records.
- Cancellation and dispute eligibility remain Offer policy.
- Faktur Pajak references belong to `IONTaxDetail.eFakturRef`.
- Customs declarations belong to the associated `IONLogisticsContract`.
- Detailed reconciliation belongs to `IONReconcile`.

## Conditional requirements

Conditional mandatoriness is enforced by ION network policy rather than this
shared schema. Important policy conditions include:

- procurement may require `purchaseOrderReference`;
- partial cancellation requires `cancellation.commitmentIds`;
- forced cancellation requires supporting timestamps;
- subscription patterns require `subscription.billingCycle`;
- applicable B2B patterns require `buyerBusinessRegistration`;
- tax-invoice requests require an appropriate inherited `taxId`.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 cleanup | 2026-07-23 | Aligned with RetailContract and relocated component-owned fields |
