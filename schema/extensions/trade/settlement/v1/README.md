# ION Trade Settlement Extension — v1

**Schemas:** `TradeSettlement` and `IONTradeSettlement`

**Attaches to:** `Settlement.settlementAttributes`

**Sector:** Trade

## Purpose

Represents the discharge of a trade consideration. `TradeSettlement` inherits
the canonical `RetailSettlement v2.1` shape, and `IONTradeSettlement` provides
an ION-specific extension point without repeating inherited fields.

The inherited schema defines:

| Field | Meaning |
|---|---|
| `method` | High-level settlement discharge method |
| `paymentRail` | Canonical or market-specific settlement rail |
| `gateway` | Gateway name, transaction identifier, and optional URL |
| `settledAt` | Time at which settlement completed |
| `settledAmount` | Amount discharged by this settlement |
| `currency` | ISO 4217 currency |
| `refund` | Structured refund record |
| `adjustments` | Post-transaction settlement adjustments |
| `reconciliationId` | Cross-party reconciliation identifier |
| `reconciliationStatus` | Reconciliation lifecycle state |

RetailSettlement requires `method`, `settledAt`, `settledAmount`, and
`currency`. These inherited requirements cannot be relaxed through `allOf`.

## Method and rail

Use the inherited high-level method together with `paymentRail`:

| Payment scenario | `method` | `paymentRail` |
|---|---|---|
| QRIS | `QR_CODE` | `QRIS` |
| GoPay or OVO | `DIGITAL_WALLET` | `GOPAY` or `OVO` |
| Virtual account | `BANK_TRANSFER` | `VA_BCA`, `VA_BNI`, etc. |
| Card | `CARD` | `VISA`, `MASTERCARD`, etc. |
| Cash on delivery collection | `COD_COLLECTION` | `COD` |
| BNPL merchant payout | `BNPL_SETTLEMENT` | Market-specific BNPL rail |

`paymentRail` accepts canonical global rails and market-specific values using
`UPPERCASE_UNDERSCORE`. ION does not close this field because government,
cross-border, and domestic flows require rails such as `RTGS`, `SKN`, `SWIFT`,
`QRIS`, and `BI_FAST`.

## Related attribute packs

- `core/payment/v1` owns buyer-facing payment declaration fields such as
  collector, collection timing, payment status, and typed instrument details.
- `core/reconcile/v1` owns reconciliation calculations, settlement basis,
  disputes, tax withholding, and detailed reconciliation adjustments.
- `trade/consideration/v1` owns monetary obligations and price changes,
  including additional charges created by an exchange or contract update.

Those concerns are not repeated in `IONTradeSettlement`.

The two structured refund records serve different stages:

- A completed `IONTradeSettlement` uses the inherited
  `refund.amount`, `refund.method`, `refund.timelineDays`, and `refund.status`.
- A buyer-facing `IONPayment` declaration uses
  `refund.refundAmount`, `refund.refundMethod`, `refund.refundTimeline`,
  and its payment-specific refund metadata.

## Currency policy

Domestic ION transactions normally settle in IDR. This is network policy rather
than a schema `const`, because cross-border trade must remain capable of using
another ISO 4217 currency.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 cleanup | 2026-07-23 | Inherited RetailSettlement v2.1 and removed duplicate payment and reconciliation fields |
