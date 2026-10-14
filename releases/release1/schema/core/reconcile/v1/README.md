# ION Core Settlement Reconciliation v1

This directory holds two artifacts:

| File | What it is |
|---|---|
| [`reconcile.yaml`](reconcile.yaml) | OpenAPI 3.1.1 network extension to Beckn Protocol v2.0.0: the `/reconcile` and `/on_reconcile` endpoints |
| [`attributes.yaml`](attributes.yaml) | Attribute pack: `IONSettlementReconciliation`, the order's payment settlement on `Settlement.settlementAttributes` from `init` to reconciliation, with its `SettlementBasis`, `SettlementWindow`, and `FinderFee` definitions |

Public URLs:

```text
https://schema.ion.id/release1/schema/core/reconcile/v1/reconcile.yaml
https://schema.ion.id/release1/schema/core/reconcile/v1/attributes.yaml
https://schema.ion.id/release1/schema/core/reconcile/v1/context.jsonld
```

Both extend Beckn by `$ref` and do not copy it. Validate them together with
the ION Beckn contract at
`https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-beckn.yaml`.

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
       all accord: true  → AGREED; SEAM instructs the PJP payout of all
       any accord: false → DISPUTED; nothing is paid out
       all sent early    → PENDING; each is sent again once due
  ── /reconcile (whole batch again) ───▶  same reconciliationId, next round
  ◀──────────── /on_reconcile ─────────  … until AGREED
```

The buyer's payment is held at the PJP (Penyelenggara Jasa Pembayaran), not in
a participant's account. When a batch is `AGREED`, SEAM
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
outside this specification. A batch is agreed as a whole or not at all: if
any contract has `accord: false`, the batch is `DISPUTED`, none of its
contracts is paid out, and the sender sends all of them again, with the same
`reconciliationId`, until every one has `accord: true`. A contract sent before
its settlement window is answered `accord: false` with the dispute code
`SETTLEMENT_WINDOW_NOT_REACHED`; it doesn't count towards the outcome and is
sent again once due. A batch whose contracts were all sent early is
`PENDING`.

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
| `dispute` | `{code, description}`; required when `accord` is `false` |

Every amount is a `ReconAmount` with `value` and, in `/on_reconcile`, a
`diffValue` (counterparty's value minus the value it is answering) when the two
differ. No tax is withheld from payouts in Release 1.

`reconciliationStatus` summarises the batch: `AGREED` (every contract has
`accord: true`) or `DISPUTED`. `SettlementSummary` carries batch totals for
cross-checking, including `totalNetPayable` (to the BPP) and `totalCommission` (to the BAP).
In `/on_reconcile` it also counts the answer: `agreedCount` (contracts with
`accord: true`) and `disputedCount` (`accord: false`).

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
[`IONPayment`](../../../common/Payment/v1/README.md) definitions and JSON-LD
IRIs, and `orderAmount` takes the place of `IONPayment.amount`.

## Examples

- [`examples/reconcile-request.json`](examples/reconcile-request.json) — the
  BPP reconciles two contracts whose payments are held at the PJP.
- [`examples/on-reconcile-response.json`](examples/on-reconcile-response.json)
  — the BAP agrees with one settlement and disputes the commission on the
  other, so the batch is `DISPUTED` and the BPP sends both again.
- [`examples/settlement-reconciliation.json`](examples/settlement-reconciliation.json)
  — one `IONSettlementReconciliation` bag for a paid QRIS order, with
  `accord: true`.

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
