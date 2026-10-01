# ION Settlement Reconciliation API v1

`reconcile.yaml` is an OpenAPI 3.1.1 network extension to Beckn Protocol
v2.0.0. It adds two endpoints for end-of-day settlement reconciliation between
a Provider Node (BPP) and a Consumer Node (BAP).

Public URL:

```text
https://schema.ion.id/release1/schema/core/reconcile/v1/reconcile.yaml
```

The file extends Beckn by `$ref` and does not copy it. Validate it together with
the vendored contract at
`https://schema.ion.id/release1/schema/vendored/beckn/protocol/v2.0.0/beckn.yaml`.

## Endpoints

| Endpoint | Sender | Message | Purpose |
|---|---|---|---|
| `POST /reconcile` | BPP to BAP | `ReconcileAction` | Submits every contract whose settlement falls due on `settlementDate`, with the BPP's `SettlementSummary`. |
| `POST /on_reconcile` | BAP to BPP | `OnReconcileAction` | Returns per-contract verdicts, the BAP's own `SettlementSummary`, and the `Payout` once agreed. |

The BPP normally sends `/reconcile` once per settlement date, and again the same
day for contracts that fell due later. `context.transactionId` identifies the
reconciliation batch rather than any one order transaction. The BAP answers with
`/on_reconcile`, correlated by `context.messageId`. It may first answer
`PENDING` and later send an unsolicited `/on_reconcile` for the same
`reconciliationId` once it has agreed and paid.

## Components

| Schema | Purpose |
|---|---|
| `ReconcileAction` | The BPP's claim for one settlement date: the due contracts and their summary. |
| `OnReconcileAction` | The BAP's batch outcome: `PENDING`, `AGREED`, `DISPUTED`, or `ADJUSTED`. |
| `ContractReconciliation` | The BAP's verdict on one contract, with `claimedAmount`, `adjustedAmount`, and a `dispute` descriptor. |
| `SettlementSummary` | Batch totals. `totalSettledAmount = totalPaidAmount − totalGatewayRefundAmount` and `netPayable = totalSettledAmount`. `totalProviderRefundAmount` is informational and does not change `netPayable`. |
| `RefundSource` | Who paid a refund: `PAYMENT_GATEWAY` (from held funds) or `PROVIDER` (after funds were released). Carried as `refund.source` on refund settlements. |
| `Payout` | The gateway's release of `netPayable` to the BPP: `COMMITTED` or `COMPLETE`. |
| `SettlementBasis` | Lifecycle event from which a settlement falls due. |
| `SettlementWindow` | ISO 8601 duration after the `SettlementBasis` event. |

## Relationship to Trade settlements

Each contract in `ReconcileAction.contracts` is a Beckn `Contract` as in
`/confirm`, `/on_cancel`, and `/on_update`. Its settlements carry
reconciliation state on `settlementAttributes`, defined by the
[Trade settlement pack](../../../extension/trade/TradeSettlement/v1/README.md):
`reconciliationId`, `reconciliationStatus`, `refund`, `settlementBasis`, and
`settlementWindow`.

This API owns the settlement due-date value sets:

| Schema | Definition |
|---|---|
| `SettlementBasis` | `ON_CONFIRMATION`, `AFTER_SHIPMENT`, `AFTER_DELIVERY`, or `AFTER_RETURN_WINDOW` — the lifecycle event from which a settlement falls due |
| `SettlementWindow` | ISO 8601 duration measured from the `SettlementBasis` event |

`SettlementSummary` uses them directly. `IONTradeSettlement.settlementBasis` and
`settlementWindow` reference them, so a batch summary and the settlements it
summarizes share one value set. The dependency runs from the Trade pack to this
core API, never the reverse.
