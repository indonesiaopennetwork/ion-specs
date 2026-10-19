# ION Settlement v1

Attribute pack: `IONSettlementReconciliation`, the order's payment settlement
on `Settlement.settlementAttributes` from `init` to reconciliation, and the
`SettlementBasis` and `SettlementWindow` definitions used by the offer's
settlement policy (`IONTradeOffer.policies.settlement`).

Public URLs:

```text
https://schema.ion.id/release1/schema/common/Settlement/v1/attributes.yaml
https://schema.ion.id/release1/schema/common/Settlement/v1/context.jsonld
```

## Attaches to

`beckn:Settlement.settlementAttributes`, in the order messages from `init` on
and in the `/reconcile` and `/on_reconcile` messages of
[`core/api/v2.0.0/ion-additional.yaml`](../../../core/README.md#settlement-reconciliation).

## `IONSettlementReconciliation`

The figures are each participant's own calculation of the two entitlements:
`commission` is the BAP's and `netPayable` the BPP's. Balancing rule:
`netPayable = orderAmount − commission − withholdingAmount − refundAmount`,
plus the `effectOnNetPayable` of each `breakup` entry with `includedIn:
ADDITIONAL`.

| Field | Meaning |
|---|---|
| `collectedBy` | Informational: whose checkout collected the payment (`IONPayment.collectedBy`) |
| `currency` | ISO 4217 code for all amounts (`IONPayment.currency`; `IDR`) |
| `method`, `paymentRail`, `timing`, `status`, `paidAt`, `gatewayRef`, ... | The payment (`IONPayment` definitions) |
| `orderDate` | Order creation date in Asia/Jakarta time |
| `orderAmount` | Gross amount the buyer pays for this settlement; the amount paid from `confirm` on |
| `commission` | The BAP's entitlement. Equals `commission.feeAmount` on the contract's price consideration in force |
| `withholdingAmount` | Amount kept back from the BPP's side, for example against returns |
| `refundAmount` | Total refunded to the buyer |
| `netPayable` | The BPP's total entitlement, before it splits it among its recipients |
| `recoveryAmount` | On a correction, an amount owed back; amounts are never negative |
| `breakup[]` | Optional itemization: `{code, includedIn, amount, effectOnNetPayable, referenceId}` |
| `collections[]` | Optional: who collected the buyer's money, how and how much (cash on delivery, credit, transfer, partial or mixed) |
| `settlementObligations[]` | Optional, informational: who is expected to pay whom |
| `settlementAccounts[]` | Payout accounts: the BAP's in `init` (required when `commission` > 0), the BPP's from `on_init`, and the recipients the BPP splits `netPayable` among |
| `relatedSettlementId`, `adjustmentType` | On a correction settlement, the earlier settlement it adjusts and how |
| `accord` | `/on_reconcile` only (required there), per settlement: `true` agrees with the entitlements received; `false` disputes them or leaves the settlement pending |
| `dueDate` | Payout due date, from the offers' `policies.settlement`; either participant may state it, required when `accord` is `true` |
| `dispute` | `{code, field, referenceId, description}`; required when `accord` is `false` |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (the answering participant's value minus the value it answers)
when the two differ. No tax is withheld from payouts in Release 1.

### Dispute codes

| Outcome | Codes |
|---|---|
| Pending — sent again later | `SETTLEMENT_WINDOW_NOT_REACHED`, `AWAITING_INFORMATION` |
| Disputed | `ORDER_AMOUNT_MISMATCH`, `COMMISSION_MISMATCH`, `WITHHOLDING_MISMATCH`, `REFUND_MISMATCH`, `TAX_MISMATCH`, `ADJUSTMENT_MISMATCH`, `MISSING_CONTRACT`, `MISSING_SETTLEMENT`, `DUPLICATE_SETTLEMENT`, `OTHER` |

`dispute.field` names the figure in dispute when there is one, for example
`commission` or a `breakup` code: two participants can match on `netPayable`
yet disagree on what makes it up.

### Breakup

| `includedIn` | Meaning |
|---|---|
| `COMMISSION`, `WITHHOLDING`, `REFUND` | Explains part of that amount; not deducted again |
| `ADDITIONAL` | Not part of those amounts; changes `netPayable` by `effectOnNetPayable` (negative for a fee or penalty charged to the BPP, positive for a credit) |

Codes: `PPN` (value-added tax), `PPH` (income-tax withholding),
`PAYMENT_FEE`, `SELLER_APP_FEE`, `NETWORK_FEE`, `LOGISTICS`,
`SELLER_FUNDED_DISCOUNT`, `BUYER_APP_SUBSIDY`, `PENALTY`, `COMPENSATION`,
`CANCELLATION`, `RETURN`, `FORCED_REFUND`, `CHARGEBACK`, `CORRECTION`,
`OFFSET`, `ROUNDING`, `OTHER`. Tax entries only explain the figures.

### Corrections

A refund, chargeback or reversal after payout is a new settlement with its own
`Settlement.id`, `relatedSettlementId` pointing to the earlier one and an
`adjustmentType` (`CORRECTION`, `REFUND`, `CHARGEBACK`, `REVERSAL`, `PENALTY`,
`OTHER`). The earlier settlement is not sent or paid again. An amount owed back
goes in `recoveryAmount`.

### The BPP's split

`settlementAccounts[]` entries with `allocationFor: BPP` and an
`allocatedAmount` split `netPayable` among the BPP's recipients: `holderRole`
`SELLER`, `LOGISTICS`, `PROVIDER`, `OTHER` (with `holderId`), or `BPP` for the
part it keeps. A complete split adds up to `netPayable`. The BAP's `accord`
covers the BPP's total, not the split or its accounts; SEAM verifies the
accounts before any payout.

## One settlement object through the order

`IONSettlementReconciliation` is the order's settlement from `init` on, carried
as the `settlementAttributes` of the contract's payment settlement:

| Step | Sender | Adds or changes |
|---|---|---|
| `init` | BAP | its `settlementAccounts` entry, `method`, `paymentRail`, `collectedBy`, `timing`, `status: PENDING`, figures estimated on the quoted price |
| `on_init` | BPP | its account, the figures on its final price (`commission` = the contract consideration's `commission.feeAmount`) |
| `confirm` | BAP | `status: PAID`, `paidAt`, `gatewayRef`; `orderAmount` is the amount paid |
| `on_cancel`, `on_update` | BPP | `commission`, `refundAmount`, `netPayable` |
| `/reconcile`, `/on_reconcile` | either | each participant's figures, `accord` in the answer |

The figures are estimates until reconciliation. The payment fields (`method`,
`paymentRail`, `paymentGatewayProvider`, `methodDetail`, `timing`, `status`,
`paidAt`, `gatewayRef`) reuse the `IONPayment` definitions. Once `status` is not
`PENDING`, the BPP's own account or its split is required; `paidAt` is required when `status` is
`PAID`.

## Settlement terms

The terms are not on the settlement object. The seller publishes them with
each offer:

- **Payout terms** — `offerAttributes.policies.settlement` (`IONTradeOffer`):
  `settlementBasis` (a `SettlementBasis` defined here) and `settlementWindow`
  (a `SettlementWindow`). The payout falls due `settlementWindow` after the
  `settlementBasis` event; when an order has several offers, the term giving
  the latest due date applies to the contract.
- **Commission** — `offerAttributes.policies.commission` (`IONTradeOffer`):
  named entries (for example a finder fee) that add up. The BPP states the
  contract's total, summed over every offer still ordered and all its entries,
  on the contract's price consideration
  (`considerationAttributes.commission.feeAmount`, `IONTradeConsideration`), and
  the settlement's `commission` equals it.

Earlier versions carried `settlementBasis`, `settlementWindow` and `finderFee`
on this object. `additionalProperties` is `true`, so orders that still carry
them stay valid; new settlement objects omit them.

Settlement accounts and the payment fields reuse the
[`IONPayment`](../../Payment/v1/README.md) definitions and JSON-LD
IRIs, and `orderAmount` takes the place of `IONPayment.amount`.

## Examples

- [`examples/settlement-reconciliation.json`](examples/settlement-reconciliation.json)
  — one `IONSettlementReconciliation` bag for a paid QRIS order, with
  `accord: true`.
- The reconcile message examples are in
  [`core/api/v2.0.0/examples/`](../../../core/api/v2.0.0/examples/).

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-14 | Initial release: `IONSettlementReconciliation` attribute pack, used by the `/reconcile` and `/on_reconcile` endpoints in `core/api/v2.0.0/ion-additional.yaml` |
| v1 | 2026-10-19 | Settlement terms moved to the offer: `settlementBasis` and `settlementWindow` to `IONTradeOffer.policies.settlement`, the finder fee to `IONTradeOffer.policies.commission` (the order's total in `IONTradeConsideration.commission.feeAmount`). `finderFee`, `settlementBasis`, `settlementWindow` and `FinderFee` removed from this pack |
| v1 | 2026-10-19 | Agreement per settlement. Added `orderDate`, `recoveryAmount`, `breakup`, `collections`, `settlementObligations`, `relatedSettlementId` and `adjustmentType`; `Dispute` gains `field` and `referenceId`, and its codes became an enum separating pending from disputed |
