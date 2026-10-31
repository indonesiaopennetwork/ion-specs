# Release 1 core API scope

Release 1 does not include the unreconciled ION-native `ion.yaml` aggregate.
Its core API contracts are `api/v2.0.0/ion-beckn.yaml`, the ION-maintained
Beckn Protocol contract, and `api/v2.0.0/ion-additional.yaml`, which contains
ION endpoints that Beckn does not define. The
manifest records `ionApi: review-required` while this draft work remains incomplete.

| File | What it is |
|---|---|
| [`api/v2.0.0/ion-beckn.yaml`](api/v2.0.0/ion-beckn.yaml) | OpenAPI 3.1.1: the Beckn Protocol v2.0.0 contract maintained by ION |
| [`api/v2.0.0/ion-additional.yaml`](api/v2.0.0/ion-additional.yaml) | OpenAPI 3.1.1: every ION endpoint that Beckn does not define. New ION endpoints are added to this file |

`ion-beckn.yaml` was initially copied without changes from Beckn's
`api/v2.0.0/beckn.yaml` at commit
`df1ade0c6610d4160968177a706f32df680e4758` (upstream SHA-256
`5afc7586ef1fbc378ea6abb139292dbe85750e4c5ea1a2fd410a40479aadc0f0`). It is
now ION-maintained so protocol fixes need not wait for a new upstream release.
ION corrected `DiscoverAction.matchType.default` from `any` to the permitted enum
value `ANY` and corrected the `/catalog/publish` example's offer validity dates
to RFC 3339 date-time values. ION then integrated the `beckn.yaml` changes
proposed in Beckn PR #202, making asynchronous callback envelopes carry exactly
one of `message` or `error`. The unmodified vendored file is retained temporarily
for consumers of the old URL. New references, including those in
`ion-additional.yaml`, use the core contract. Validate the two core contracts
together:

```text
https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-beckn.yaml
https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-additional.yaml
```

## Endpoints in `ion-additional.yaml`

| Endpoint | Sender | Message | Purpose |
|---|---|---|---|
| `POST /reconcile` | BAP or BPP | `ReconcileAction` | The contracts whose settlement falls due on `settlementDate`, with the sender's figures |
| `POST /on_reconcile` | The counterparty | `OnReconcileAction` or `AsyncError` | The counterparty's figures and `accord`, or an asynchronous processing failure |

## Settlement reconciliation

`context.bapId` and `context.bppId` are always the BAP and BPP of the original
orders, whoever sends. `context.senderId` and `context.receiverId` identify the
actual sender and receiver.

| Identifier | Meaning |
|---|---|
| `context.transactionId` | The reconciliation exchange. Either participant may start one and creates it; resends of unresolved settlements keep it |
| `context.messageId` | One `/reconcile` and its `/on_reconcile`. A plain retransmission repeats it and is processed once; each new `/reconcile` gets a new one |
| BAP–BPP pair + `Contract.id` + `Settlement.id` | The settlement itself. An agreed settlement is never paid twice, whichever message repeats it |
| `relatedSettlementId` | On a correction settlement, the earlier `Settlement.id` it adjusts |

There is no separate reconciliation ID.

### Message shape

`message.contracts[]` are Beckn `Contract` objects. Each settlement's
`settlementAttributes` is an
[`IONSettlementReconciliation`](../common/Settlement/v1/README.md) bag carrying
the figures:

```json
{
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
        "orderDate": "2026-09-28",
        "dueDate": "2026-10-01",
        "orderAmount": { "value": 98900 },
        "commission": { "value": 2670 },
        "withholdingAmount": { "value": 0 },
        "refundAmount": { "value": 0 },
        "netPayable": { "value": 96230 },
        "settlementAccounts": [ … BAP, BPP and the BPP's recipients … ],
        "collections": [ { "method": "PREPAID", "status": "COLLECTED", "collectorRole": "PJP" } ]
      }
    }]
  }],
  "settlementSummary": { … totals, optional orderDayCounts … }
}
```

- `contract.id` identifies the contract and `settlements[].id` a settlement
  obligation, whether prepaid, cash on delivery or credit.
- `commission` is the BAP's entitlement and `netPayable` the BPP's. The
  commission is the contract consideration's `buyerFinderFee.feeAmount`
  ([`IONTradeConsideration`](../extension/trade/TradeConsideration/v1/README.md)),
  the sum of the offers' buyer finder fees;
  the payout terms (`settlementBasis`, `settlementWindow`) are the
  commitments' offers' `policies.settlement`
  ([`IONTradeOffer`](../extension/trade/TradeOffer/v1/README.md)). Neither is
  repeated in the settlement object.
- Each settlement states its own `orderDate` (creation date in Asia/Jakarta
  time) and `dueDate`. A request holds the settlements due on
  `settlementDate`, whatever their order dates.
- A contract in these messages is a snapshot that carries reconciliation
  figures; it does not update the contract. Beckn requires at least one
  `commitments` entry, so include a minimal one (id, status, resource with
  quantity, offer with `resourceIds`). Receivers MUST NOT treat it as a change.

### Flow

ION has no separate settle or report API; reconciliation and agreement run
through these two endpoints.

```text
Sender (BAP or BPP)                          Counterparty
  ── /reconcile (transactionId T, messageId M1) ──▶
  ◀──────────── /on_reconcile (T, M1) ─────────────  accord on every settlement
       accord: true                 → agreed; goes on to SEAM
       accord: false, disputed code → disputed
       accord: false, pending code  → pending (not due, or awaiting information)
  ── /reconcile (T, M2): only the disputed and pending settlements ──▶
  ◀──────────── /on_reconcile (T, M2) ─────────────  … until each is agreed
```

Agreement is per settlement: an agreed settlement stays agreed whatever
happens to the others. `reconciliationStatus` summarizes the answer —
`AGREED` when every settlement is agreed, `DISPUTED` when any is disputed,
otherwise `PENDING` — and never overrides a settlement's `accord`.
`SETTLEMENT_WINDOW_NOT_REACHED` and `AWAITING_INFORMATION` make a settlement
pending; every other dispute code makes it disputed. On a differing figure,
`diffValue` is the answering participant's value minus the value it answers.

If reconciliation processing fails before a business answer can be produced,
`/on_reconcile` carries top-level `error` instead of `message`. That
`AsyncError` terminates the callback sequence for the request's
`context.messageId`; retrying requires a new `/reconcile` with a new
`messageId`.

`accord: true` means the two participants agree on their entitlements; it is
not a payout instruction and not proof of funds. SEAM (Settlement Assurance
Mechanism) separately verifies the funds, the accounts in
`settlementAccounts` and that nothing is paid twice, and then has the agreed
settlement paid:

| Recipient | Receives |
|---|---|
| BPP, or the recipients it splits its share among | `netPayable` |
| BAP | `commission` |
| Buyer | `refundAmount` |
| Kept back | `withholdingAmount` |

A prepaid buyer payment is held at the PJP (Penyelenggara Jasa Pembayaran).
For cash on delivery, credit and bank transfer, `collections` records who
collected what, and `settlementObligations` who is expected to pay whom; both
are information, not payment instructions. Payout status reaches the
participants through the PJP's webhook, which is outside this specification.

### The BPP's split

The BPP may split its share among sellers, logistics providers, itself and
other recipients in `settlementAccounts`: each such account has
`allocationFor: BPP` and an `allocatedAmount`, and a complete split adds up to
`netPayable`. The BAP's `accord` covers the BPP's total, not the split or its
accounts; changing the split or an account without changing the total does
not reopen the agreement.

### Summary

`settlementSummary` holds totals over the settlements in the message, from the
sending participant's own figures. In `/on_reconcile` it also has:

| Field | Meaning |
|---|---|
| `agreedCount`, `disputedCount`, `pendingCount` | Contracts by outcome: disputed if any settlement is disputed, otherwise pending if any is pending, otherwise agreed. They add up to `contractCount` |
| `agreedSettlementCount`, `disputedSettlementCount`, `pendingSettlementCount` | Optional, the same per settlement |
| `totalAgreedCommission`, `totalAgreedNetPayable` | Over the settlements with `accord: true` |
| `totalUnreconciledCommission`, `totalUnreconciledNetPayable` | The answering participant's own figures over the others: its claim, not an agreed amount |

Either message may add `orderDayCounts`: for each order day it touches, the
sender's count of the pair's orders created that day (`reportedOrderCount`)
and of those not yet fully reconciled (`remainingOrderCount`), including orders
not yet due. The two participants' counts may differ; that is for them to
investigate.

### Examples

- [`api/v2.0.0/examples/reconcile-request.json`](api/v2.0.0/examples/reconcile-request.json)
  — the BPP reconciles three contracts: a prepaid order whose share it splits
  with a seller, an order with a refund, and a cash-on-delivery order
  collected by a courier.
- [`api/v2.0.0/examples/on-reconcile-response.json`](api/v2.0.0/examples/on-reconcile-response.json)
  — the BAP agrees with the first, disputes the commission on the second and
  leaves the third pending until delivery is confirmed. The answer is
  `DISPUTED`; the first settlement is agreed and goes on to SEAM, and the BPP
  sends the other two again.

### Not in Release 1

- A limit on rounds, or escalation of unresolved disputes to `/raise`.
- Tax withheld from payouts (tax entries in `breakup` only explain the
  figures) and a delay or late-settlement amount.
- `MISC`/`NIL` settlement types.
