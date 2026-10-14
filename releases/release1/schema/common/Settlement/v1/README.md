# ION Settlement v1

Attribute pack: `IONSettlementReconciliation`, the order's payment settlement
on `Settlement.settlementAttributes` from `init` to reconciliation, with its
`SettlementBasis`, `SettlementWindow`, and `FinderFee` definitions.

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
| `settlementBasis`, `settlementWindow`, `finderFee` | The settlement terms agreed in `init`/`on_init` |
| `orderAmount` | Gross amount the buyer pays, held at the PJP; the amount paid from `confirm` on |
| `commission` | BAP finder fee; paid to the BAP. Equals `finderFee.feeAmount` |
| `withholdingAmount` | Amount the PJP keeps back, for example against returns |
| `refundAmount` | Total the PJP returns to the buyer |
| `netPayable` | Paid to the BPP: `orderAmount − commission − withholdingAmount − refundAmount` |
| `settlementAccounts[]` | Payout accounts: the BAP's in `init` (required when `commission` > 0), the BPP's from `on_init` |
| `accord` | `/on_reconcile` only (required there): `true` agrees with the figures received; `false` disagrees |
| `dueDate` | Payout due date; required when `accord` is `true` |
| `dispute` | `{code, description}`; required when `accord` is `false`. `SETTLEMENT_WINDOW_NOT_REACHED` marks a contract sent before its settlement window |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (counterparty's value minus the value it is answering) when the two
differ. No tax is withheld from payouts in Release 1.

## One settlement object through the order

`IONSettlementReconciliation` is the order's settlement from `init` on, carried
as the `settlementAttributes` of the contract's payment settlement:

| Step | Sender | Adds or changes |
|---|---|---|
| `init` | BAP | `finderFee` terms, its `settlementAccounts` entry, `method`, `paymentRail`, `collectedBy`, `timing`, `status: PENDING`, figures estimated on the quoted price |
| `on_init` | BPP | `settlementBasis`, `settlementWindow`, `finderFee.feeAmount`, its account, the figures on its final price |
| `confirm` | BAP | `status: PAID`, `paidAt`, `gatewayRef`; `orderAmount` is the amount paid |
| `on_cancel`, `on_update` | BPP | `finderFee.feeAmount`, `commission`, `refundAmount`, `netPayable` |
| `/reconcile`, `/on_reconcile` | either | each participant's figures, `accord` in the answer |

The figures are estimates until reconciliation. The payment fields (`method`,
`paymentRail`, `paymentGatewayProvider`, `methodDetail`, `timing`, `status`,
`paidAt`, `gatewayRef`) reuse the `IONPayment` definitions. The BPP account is
required once `status` is not `PENDING`; `paidAt` is required when `status` is
`PAID`.

The settlement terms (`settlementBasis`, `settlementWindow`, `finderFee`) live
only here, on the payment settlement; `IONTradeContract` does not carry them.
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
