# ION Core Settlement Reconciliation v1

This directory holds two artifacts:

| File | What it is |
|---|---|
| [`reconcile.yaml`](reconcile.yaml) | OpenAPI 3.1.1 network extension to Beckn Protocol v2.0.0: the `/reconcile` and `/on_reconcile` endpoints |
| [`attributes.yaml`](attributes.yaml) | Attribute pack: `IONSettlementReconciliation` on `Settlement.settlementAttributes`, plus the `SettlementBasis`, `SettlementWindow`, and `FinderFee` definitions that `IONTradeContract` references |

Public URLs:

```text
https://schema.ion.id/release1/schema/core/reconcile/v1/reconcile.yaml
https://schema.ion.id/release1/schema/core/reconcile/v1/attributes.yaml
https://schema.ion.id/release1/schema/core/reconcile/v1/context.jsonld
```

Both extend Beckn by `$ref` and do not copy it. Validate them together with
the vendored contract at
`https://schema.ion.id/release1/schema/vendored/beckn/protocol/v2.0.0/beckn.yaml`.

## Endpoints

| Endpoint | Sender | Message | Purpose |
|---|---|---|---|
| `POST /reconcile` | BAP or BPP | `ReconcileAction` | The contracts whose settlement falls due on `settlementDate`, with the sender's figures |
| `POST /on_reconcile` | The counterparty | `OnReconcileAction` | The counterparty's figures and `accord` for each settlement |

`context.bapId` and `context.bppId` are always the BAP and BPP of the original
orders, whoever sends. `context.senderId` and `context.receiverId` identify the
actual sender and receiver. `/on_reconcile` is correlated by
`context.messageId`.

## Message shape

`message.contracts[]` are Beckn `Contract` objects. Each settlement's
`settlementAttributes` is an `IONSettlementReconciliation` bag carrying the
figures:

```json
{
  "reconciliationId": "recon-2026-09-30T170000Z-bpp.example.id",
  "settlementDate": "2026-09-30",
  "contracts": [{
    "id": "0f8b6d3e-2c4a-4b8e-9d1f-6a7b8c9d0e1f",
    "commitments": [ … minimal … ],
    "settlements": [{
      "id": "PAY-2026-00012345",
      "settlementAttributes": {
        "@context": "https://schema.ion.id/release1/schema/core/reconcile/v1/context.jsonld",
        "@type": "ion:IONSettlementReconciliation",
        "collectedBy": "BAP",
        "currency": "IDR",
        "settlementBasis": "AFTER_DELIVERY",
        "settlementWindow": "P1D",
        "finderFee": { "feeType": "PERCENT", "feeValue": 3, "appliesTo": "ITEM_TOTAL", "feeAmount": 2670 },
        "orderAmount": { "value": 98900 },
        "commission": { "value": 2670 },
        "withholdingAmount": { "value": 0 },
        "refundAmount": { "value": 0 },
        "netPayable": { "value": 96230 },
        "settlementAccounts": [ … BAP and BPP accounts … ]
      }
    }]
  }],
  "settlementSummary": { … batch totals … }
}
```

- `contract.id` identifies the contract and `settlements[].id` identifies the
  payment record whose PJP-held funds are paid out.
- A contract in these messages is a snapshot that carries reconciliation
  figures; it does not update the contract. Beckn requires at least one
  `commitments` entry, so include a minimal one (id, status, resource with
  quantity, offer with `resourceIds`). Receivers MUST NOT treat it as a change.

## Flow

ION has no separate settle or report API; reconciliation, agreement, and the
payout trigger all run through these two endpoints.

```text
Sender (BAP or BPP)                     Counterparty
  ── /reconcile (figures) ─────────────▶
  ◀──────────── /on_reconcile ─────────  accord per settlement
       accord: true  → agreed by both; SEAM instructs the PJP payout
       accord: false → counterparty figures + diffValue + dispute
  ── /reconcile (revised figures) ─────▶  next round for disputed settlements
  ◀──────────── /on_reconcile ─────────
```

The buyer's payment is held at the PJP (Penyelenggara Jasa Pembayaran), not in
a participant's account. When a settlement reaches `accord: true`, SEAM
(Settlement Assurance Mechanism) instructs the PJP to pay it out of the held
funds into the accounts in `settlementAccounts`:

| Recipient | Receives |
|---|---|
| BPP | `netPayable` |
| BAP | `commission` |
| Buyer | `refundAmount` |
| Stays at the PJP | `withholdingAmount` |

SEAM may combine agreed settlements into a single transfer per participant.
Payout status reaches the participants through the PJP's webhook, which is
outside this specification. A batch can be `PARTIALLY_AGREED`: its agreed
settlements proceed to payout while the rest continue to another round.

## `IONSettlementReconciliation`

Invariant:
`orderAmount = netPayable + commission + withholdingAmount + refundAmount`.

| Field | Meaning |
|---|---|
| `collectedBy` | Informational: whose checkout collected the payment into the PJP (`IONPayment.collectedBy`) |
| `currency` | ISO 4217 code for all amounts (`IONPayment.currency`; `IDR`) |
| `settlementBasis`, `settlementWindow`, `finderFee` | The settlement terms agreed on `IONTradeContract` in `init`/`on_init`, repeated so the settlement is self-contained |
| `orderAmount` | Gross amount the buyer paid, held at the PJP |
| `commission` | BAP finder fee; paid to the BAP. Equals `finderFee.feeAmount` |
| `withholdingAmount` | Amount the PJP keeps back, for example against returns |
| `refundAmount` | Total the PJP returns to the buyer |
| `netPayable` | Paid to the BPP: `orderAmount − commission − withholdingAmount − refundAmount` |
| `settlementAccounts[]` | Payout accounts from `IONPayment.settlementAccounts`: the BPP's always, the BAP's when `commission` > 0 |
| `accord` | `/on_reconcile` only (required there): `true` agrees with the figures received; `false` disagrees |
| `dueDate` | Payout due date; required when `accord` is `true` |
| `dispute` | `{code, description}`; required when `accord` is `false` |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (counterparty's value minus the value it is answering) when the two
differ. No tax is withheld from payouts in Release 1.

`reconciliationStatus` summarises the batch: `AGREED`, `PARTIALLY_AGREED`, or
`DISPUTED`. `SettlementSummary` carries batch totals for cross-checking,
including `totalNetPayable` (to the BPP) and `totalCommission` (to the BAP).

## Where the inputs come from

| Input | Agreed in | Defined by |
|---|---|---|
| `settlementBasis`, `settlementWindow`, `finderFee` (terms and `feeAmount`) | `init` / `on_init`; `feeAmount` recomputed in `on_cancel` / `on_update` | [`IONTradeContract`](../../../extension/trade/TradeContract/v1/README.md) on `Contract.contractAttributes` |
| `settlementAccounts` (BAP in `init`, BPP in `on_init`) | `init` / `on_init` | [`IONPayment`](../../../common/Payment/v1/README.md) on `Contract.settlements[]` |

This pack owns the `SettlementBasis`, `SettlementWindow`, and `FinderFee`
definitions; `IONTradeContract` references them, so the order terms and the
reconciliation figures share one definition and one JSON-LD IRI.

## Examples

- [`examples/reconcile-request.json`](examples/reconcile-request.json) — the
  BPP reconciles two contracts whose payments are held at the PJP.
- [`examples/on-reconcile-response.json`](examples/on-reconcile-response.json)
  — the BAP agrees with one settlement and disputes the commission on the other
  (`PARTIALLY_AGREED`).
- [`examples/settlement-reconciliation.json`](examples/settlement-reconciliation.json)
  — one `IONSettlementReconciliation` bag with `accord: true`.

## Not in Release 1

- A limit on rounds, or escalation of unresolved disputes to `/raise`.
- Tax withheld from payouts, a delay or late-settlement amount, and payout legs
  to logistics providers.
- Direct payout to a seller who is not the BPP, `MISC`/`NIL` settlement types,
  and reconciliation after payout.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-12 | Initial release: reconciliation API and `IONSettlementReconciliation` attribute pack |
