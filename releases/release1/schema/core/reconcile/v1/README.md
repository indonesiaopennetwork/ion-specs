# ION Settlement Reconciliation API v1

`reconcile.yaml` is an OpenAPI 3.1.1 network extension to Beckn Protocol
v2.0.0. It adds two endpoints through which the two participants of an order,
the Consumer Node (BAP) and the Provider Node (BPP), agree each contract's
settlement figures before the payout.

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
| `POST /reconcile` | BAP or BPP | `ReconcileAction` | The sender's figures for every contract whose settlement falls due on `settlementDate` |
| `POST /on_reconcile` | The counterparty | `OnReconcileAction` | `accord` per contract, with the counterparty's own figures and differences |

`context.bapId` and `context.bppId` are always the BAP and BPP of the original
orders, whoever sends. `context.senderId` and `context.receiverId` identify the
actual sender and receiver. `/on_reconcile` is correlated by
`context.messageId`.

## Flow

ION has no separate settle or report API; reconciliation, agreement, and the
payout trigger all run through these two endpoints.

```text
Sender (BAP or BPP)                     Counterparty
  ── /reconcile (figures) ─────────────▶
  ◀──────────── /on_reconcile ─────────  accord per contract
       accord: true  → agreed by both; SEAM instructs the PJP payout
       accord: false → counterparty figures + diffValue + dispute
  ── /reconcile (revised figures) ─────▶  next round for disputed contracts
  ◀──────────── /on_reconcile ─────────
```

1. The buyer's payment is held at the PJP (Penyelenggara Jasa Pembayaran), not
   in a participant's account. When a contract reaches `accord: true`, SEAM
   (Settlement Assurance Mechanism) instructs the PJP to pay it out of the held
   funds into the accounts in `settlementAccounts`:

   | Recipient | Receives |
   |---|---|
   | BPP | `netPayable` |
   | BAP | `commission` |
   | Buyer | `refundAmount` |
   | Stays at the PJP | `withholdingAmount` |

2. SEAM may combine agreed contracts into a single transfer per participant;
   the wire carries the figures per contract only.
3. Payout status reaches the participants through the PJP's webhook, which is
   outside this specification.
4. A batch can be `PARTIALLY_AGREED`: its agreed contracts proceed to payout
   while the rest continue to another round.

## Per-contract figures

The figures split the buyer's payment held at the PJP:
`orderAmount = netPayable + commission + withholdingAmount + Σ taxes + refundAmount`.

| Field | Meaning |
|---|---|
| `contractId` | Beckn `Contract.id` |
| `settlementId` | `Contract.settlements[].id` of the payment record whose held funds are paid out |
| `collectedBy` | Informational: whose checkout collected the payment into the PJP (`IONPayment.collectedBy`) |
| `currency` | ISO 4217 code for all amounts; `IDR` for domestic trade |
| `settlementBasis`, `settlementWindow` | Due-date terms agreed on `IONTradeContract` |
| `orderAmount` | Gross amount the buyer paid, held at the PJP |
| `commission` | BAP finder fee, computed from `IONTradeContract.finderFee`; paid to the BAP |
| `withholdingAmount` | Amount the PJP keeps back, for example against returns |
| `taxes[]` | Taxes withheld from the BPP's proceeds, by `taxRegime` (for example `PPH22`, `PPH23`) |
| `refundAmount` | Total the PJP returns to the buyer |
| `netPayable` | Paid to the BPP: `orderAmount − commission − withholdingAmount − Σ taxes − refundAmount` |
| `settlementAccounts[]` | Payout accounts from `IONPayment.settlementAccounts`: the BPP's always, the BAP's when `commission` > 0 |
| `contract` | Optional copy of the Beckn `Contract` as the sender holds it |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (counterparty's value minus the value it is answering) when the two
differ.

In `/on_reconcile`, each contract also carries:

| Field | Meaning |
|---|---|
| `accord` | `true` agrees with the figures received; `false` disagrees |
| `dueDate` | Payout due date; required when `accord` is `true` |
| `dispute` | Reason (code and text); required when `accord` is `false` |

`reconciliationStatus` summarises the batch: `AGREED`, `PARTIALLY_AGREED`, or
`DISPUTED`. `SettlementSummary` carries batch totals for cross-checking; there
is no batch-level payable.

## Components

| Schema | Purpose |
|---|---|
| `ReconcileAction` | One reconciliation round: batch ID, settlement date, contracts, totals |
| `OnReconcileAction` | The counterparty's answer: batch status, verdicts, its own totals |
| `ContractSettlement` | One participant's figures for one contract |
| `ContractReconciliation` | `ContractSettlement` plus `accord`, `dueDate`, and `dispute` |
| `ReconAmount` | A settlement component: `value` and optional `diffValue` |
| `TaxDeduction` | A tax withheld from the payout under one `taxRegime` |
| `SettlementSummary` | Batch totals for cross-checking |
| `SettlementBasis` | `ON_CONFIRMATION`, `AFTER_SHIPMENT`, `AFTER_DELIVERY`, or `AFTER_RETURN_WINDOW` |
| `SettlementWindow` | ISO 8601 duration measured from the `SettlementBasis` event |

## Where the inputs come from

| Input | Agreed in | Defined by |
|---|---|---|
| `settlementBasis`, `settlementWindow`, `finderFee` | `init` / `on_init` | [`IONTradeContract`](../../../extension/trade/TradeContract/v1/README.md) on `Contract.contractAttributes` |
| `settlementAccounts` (BAP in `init`, BPP in `on_init`) | `init` / `on_init` | [`IONPayment`](../../../common/Payment/v1/README.md) on `Contract.settlements[]` |

This API owns the `SettlementBasis` and `SettlementWindow` definitions;
`IONTradeContract` references them, so the order terms and the reconciliation
figures share one value set.

## Examples

- [`examples/reconcile-request.json`](examples/reconcile-request.json) — the
  BPP reconciles two contracts whose payments are held at the PJP.
- [`examples/on-reconcile-response.json`](examples/on-reconcile-response.json)
  — the BAP agrees with one contract and disputes the commission on the other
  (`PARTIALLY_AGREED`).

## Not in Release 1

- A limit on rounds, or escalation of unresolved disputes to `/raise`.
- A delay or late-settlement amount.
- Payout legs to logistics providers.
