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

Invariant:
`orderAmount = netPayable + commission + withholdingAmount + refundAmount`.

| Field | Meaning |
|---|---|
| `collectedBy` | Informational: whose checkout collected the payment into the PJP (`IONPayment.collectedBy`) |
| `currency` | ISO 4217 code for all amounts (`IONPayment.currency`; `IDR`) |
| `method`, `paymentRail`, `timing`, `status`, `paidAt`, `gatewayRef`, ... | The payment (`IONPayment` definitions) |
| `orderAmount` | Gross amount the buyer pays, held at the PJP; the amount paid from `confirm` on |
| `commission` | Commission the BPP pays the BAP; paid to the BAP. Equals `buyerFinderFee.feeAmount` on the contract's price consideration in force |
| `withholdingAmount` | Amount the PJP keeps back, for example against returns |
| `refundAmount` | Total the PJP returns to the buyer |
| `netPayable` | Paid to the BPP: `orderAmount − commission − withholdingAmount − refundAmount` |
| `settlementAccounts[]` | Payout accounts: the BAP's in `init` (required when `commission` > 0), the BPP's from `on_init` |
| `accord` | `/on_reconcile` only (required there): `true` agrees with the figures received; `false` disagrees |
| `dueDate` | Payout due date, from the offers' `policies.settlement`; required when `accord` is `true` |
| `dispute` | `{code, description}`; required when `accord` is `false`. `SETTLEMENT_WINDOW_NOT_REACHED` marks a contract sent before its settlement window |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (counterparty's value minus the value it is answering) when the two
differ. No tax is withheld from payouts in Release 1.

## One settlement object through the order

`IONSettlementReconciliation` is the order's settlement from `init` on, carried
as the `settlementAttributes` of the contract's payment settlement:

| Step | Sender | Adds or changes |
|---|---|---|
| `init` | BAP | its `settlementAccounts` entry, `method`, `paymentRail`, `collectedBy`, `timing`, `status: PENDING`, figures estimated on the quoted price |
| `on_init` | BPP | its account, the figures on its final price (`commission` = the contract consideration's `buyerFinderFee.feeAmount`) |
| `confirm` | BAP | `status: PAID`, `paidAt`, `gatewayRef`; `orderAmount` is the amount paid |
| `on_cancel`, `on_update` | BPP | `commission`, `refundAmount`, `netPayable` |
| `/reconcile`, `/on_reconcile` | either | each participant's figures, `accord` in the answer |

The figures are estimates until reconciliation. The payment fields (`method`,
`paymentRail`, `paymentGatewayProvider`, `methodDetail`, `timing`, `status`,
`paidAt`, `gatewayRef`) reuse the `IONPayment` definitions. The BPP account is
required once `status` is not `PENDING`; `paidAt` is required when `status` is
`PAID`.

## Settlement terms

The terms are not on the settlement object. The seller publishes them with
each offer:

- **Payout terms** — `offerAttributes.policies.settlement` (`IONTradeOffer`):
  `settlementBasis` (a `SettlementBasis` defined here) and `settlementWindow`
  (a `SettlementWindow`). The payout falls due `settlementWindow` after the
  `settlementBasis` event; when an order has several offers, the term giving
  the latest due date applies to the contract.
- **Commission** — the buyer finder fee on each offer's consideration
  (`considerationAttributes.buyerFinderFee`, `IONTradeConsideration`): one fee
  per offer. The BPP states the contract's total, summed over every offer
  still ordered, on the contract's price consideration
  (`buyerFinderFee.feeAmount`), and the settlement's `commission` equals it.

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
| v1 | 2026-10-19 | Settlement terms moved to the offer: `settlementBasis` and `settlementWindow` to `IONTradeOffer.policies.settlement`, the finder fee to `IONTradeConsideration.buyerFinderFee` on each offer's consideration (the order's total in `buyerFinderFee.feeAmount` on the contract's). `finderFee`, `settlementBasis`, `settlementWindow` and `FinderFee` removed from this pack |
