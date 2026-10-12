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

## Settlement terms

Agreed between the Consumer Node (BAP) and Provider Node (BPP) in `init` and
`on_init`, and used by [settlement reconciliation](../../../../core/reconcile/v1/README.md)
to compute each contract's payout. These properties are marked
`x-attr-ion-layer: ion`.

| Field | Type | Meaning |
|---|---|---|
| `settlementBasis` | enum | Lifecycle event from which the settlement falls due |
| `settlementWindow` | ISO 8601 duration | Time after the `settlementBasis` event within which the settlement is paid out |
| `finderFee.feeType` | `PERCENT` \| `AMOUNT` | How the BAP's finder fee is expressed |
| `finderFee.feeValue` | number | Percentage (0-100) or fixed amount in the contract currency |
| `finderFee.appliesTo` | `ITEM_TOTAL` \| `ORDER_TOTAL` | Base for a `PERCENT` fee |

`settlementBasis` and `settlementWindow` reference the `SettlementBasis` and
`SettlementWindow` definitions owned by `core/reconcile/v1`.

| `settlementBasis` | Window starts at |
|---|---|
| `ON_CONFIRMATION` | Order confirmation |
| `AFTER_SHIPMENT` | Hand-over to logistics |
| `AFTER_DELIVERY` | Confirmed delivery |
| `AFTER_RETURN_WINDOW` | Close of the applicable return window |

Example — settle within one day of delivery, with a 3% finder fee on the item
total:

```json
{
  "settlementBasis": "AFTER_DELIVERY",
  "settlementWindow": "P1D",
  "finderFee": { "feeType": "PERCENT", "feeValue": 3, "appliesTo": "ITEM_TOTAL" }
}
```

The participants' payout bank accounts are not contract terms; they travel as
`IONPayment.settlementAccounts` on `Contract.settlements[]`.

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
- Detailed reconciliation belongs to `core/reconcile/v1`.

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
| v1 | 2026-10-12 | Added settlement terms `settlementBasis` and `settlementWindow` (moved from `IONTradeSettlement`) and `finderFee` |
