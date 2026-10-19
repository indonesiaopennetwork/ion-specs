# Release 1 core API scope

Release 1 does not include the unreconciled ION-native `ion.yaml` aggregate.
Its core API contract is `api/v2.0.0/ion-additional.yaml`, which contains ION
endpoints that are not defined by the immutable vendored Beckn contract. The
manifest records `ionApi: review-required` while this draft work remains incomplete.

| File | What it is |
|---|---|
| [`api/v2.0.0/ion-additional.yaml`](api/v2.0.0/ion-additional.yaml) | OpenAPI 3.1.1: every ION endpoint that Beckn does not define. New ION endpoints are added to this file |

`ion-additional.yaml` references the vendored `beckn.yaml` and does not copy it.
Validate the two together:

```text
https://schema.ion.id/release1/schema/vendored/beckn/api/v2.0.0/beckn.yaml
https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-additional.yaml
```

## Endpoints in `ion-additional.yaml`

| Endpoint | Sender | Message | Purpose |
|---|---|---|---|
| `POST /reconcile` | BAP or BPP | `ReconcileAction` | The contracts whose settlement falls due on `settlementDate`, with the sender's figures |
| `POST /on_reconcile` | The counterparty | `OnReconcileAction` | The counterparty's figures and `accord` for each settlement |

## Settlement reconciliation

`context.bapId` and `context.bppId` are always the BAP and BPP of the original
orders, whoever sends. `context.senderId` and `context.receiverId` identify the
actual sender and receiver. `/on_reconcile` is correlated by
`context.messageId`.

### Message shape

`message.contracts[]` are Beckn `Contract` objects. Each settlement's
`settlementAttributes` is an
[`IONSettlementReconciliation`](../common/Settlement/v1/README.md) bag carrying
the figures:

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
        "@context": "https://schema.ion.id/release1/schema/common/Settlement/v1/context.jsonld",
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

### Flow

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

`reconciliationStatus` summarises the batch: `AGREED`, `DISPUTED`, or
`PENDING`. `SettlementSummary` carries batch totals for cross-checking,
including `totalNetPayable` (to the BPP) and `totalCommission` (to the BAP).
In `/on_reconcile` it also counts the answer: `agreedCount` (contracts with
`accord: true`) and `disputedCount` (`accord: false`, including contracts sent
early).

### Examples

- [`api/v2.0.0/examples/reconcile-request.json`](api/v2.0.0/examples/reconcile-request.json)
  — the BPP reconciles two contracts whose payments are held at the PJP.
- [`api/v2.0.0/examples/on-reconcile-response.json`](api/v2.0.0/examples/on-reconcile-response.json)
  — the BAP agrees with one settlement and disputes the commission on the
  other, so the batch is `DISPUTED` and the BPP sends both again.

### Not in Release 1

- A limit on rounds, or escalation of unresolved disputes to `/raise`.
- Tax withheld from payouts, a delay or late-settlement amount, and payout legs
  to logistics providers.
- Direct payout to a seller who is not the BPP, `MISC`/`NIL` settlement types,
  and reconciliation after payout.
