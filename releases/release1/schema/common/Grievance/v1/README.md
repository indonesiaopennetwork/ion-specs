# ION Grievance v1

Attribute pack: `IONGrievance`, one event of an order-level grievance,
carried as `Support.supportAttributes` in `/support` and `/on_support`.

Public URLs:

```text
https://schema.ion.id/release1/schema/common/Grievance/v1/attributes.yaml
https://schema.ion.id/release1/schema/common/Grievance/v1/context.jsonld
```

## Attaches to

`beckn:Support.supportAttributes`, in the `/support` and `/on_support`
messages of the vendored Beckn contract.

> **Pending Beckn change.** Beckn 2.0.0 `Support` allows only `orderId`,
> `descriptor` and `channels`, with `additionalProperties: false`. This pack
> assumes an optional `supportAttributes` slot of type `Attributes` on
> `Support`, proposed to Beckn. Until that change is released and vendored,
> `/support` and `/on_support` messages carrying this pack fail validation
> against the vendored contract. `Support.channels[]` keeps its Beckn meaning:
> the contact channels (WhatsApp, helpdesk, in-app chat) for the grievance.
>
> Raised with Beckn in
> [protocol-specifications-v2#203](https://github.com/beckn/protocol-specifications-v2/issues/203)
> (draft PR [#204](https://github.com/beckn/protocol-specifications-v2/pull/204))
> and with the Fabric team in
> [fabric-support#116](https://github.com/Networks-for-Humanity/fabric-support/issues/116).

## What a grievance is

A grievance is a problem with **one order**, raised by the buyer through the
BAP or by the seller through the BPP. One order may have several grievances,
and one grievance may cover several order lines.

| Situation | Flow |
|---|---|
| Buyer returns or cancels within the order's policy (button in the app) | `update` / `on_update` for part of the order, `cancel` / `on_cancel` for the whole contract. Not a grievance |
| Seller rejects the return, the return pickup never happens, the QC result is disputed, or the refund never arrives | Grievance, raised by either side, linked to the return, refund or contract in `relatedReferences` |
| Any other problem with the order (damaged, wrong or missing item, late delivery, wrong return) | Grievance |
| BAP and BPP disagree on settlement figures | `reconcile` / `on_reconcile`, not a grievance |
| Formal dispute between participants, over zero, one or many orders | ION SATU portal. No `raise` / `on_raise` API in Release 1 |

Only the material events travel over the network. Conversations, evidence,
staff assignment and ticket handling stay in each participant's own systems.

## Life of a grievance

```text
            originating participant                 responding participant
OPENED            ─────────────────────────────────▶
ACKNOWLEDGED      ◀─────────────────────────────────
RESOLUTION_PROPOSED ◀─────────────────────────────── (version 1, 2, …)
RESOLUTION_DECIDED  ─────────────────────────────────▶ (only for EXPLICIT_AGREEMENT)
ACTION_COMPLETED    ◀─────────────────────────────── (with execution references)
RESOLVED            ◀───────────────────────────────
OBJECTION           ─────────────────────────────────▶ (optional, within the objection period)
CLOSED              ─────────────────────────────────▶ (optional; otherwise deemed)
```

The arrows show the usual direction; a `UNILATERAL` resolution is proposed
and executed by the participant that funds it.

| `caseStatus` | Meaning |
|---|---|
| `OPEN` | Opened or reopened by an objection |
| `IN_PROGRESS` | A resolution is being proposed, decided or executed |
| `RESOLVED` | Every action that moves money or goods is executed |
| `CLOSED` | Closed explicitly by the originating participant |

These statuses are ION-defined and provisional: Beckn 2.0.0 defines no
grievance status. A `RESOLVED` grievance with no objection within the
objection period of the grievance SLA policy (`policyRef`) is **deemed
closed** by both participants without another message.

## `IONGrievance`

| Field | Meaning |
|---|---|
| `grievanceId` | Set by the originating participant on `OPENED`; the same in every event |
| `eventType` | What happened in this message |
| `caseStatus`, `subStatus` | Status after the event, and optional detail |
| `occurredAt`, `openedAt` | Time of this event; time the grievance was opened |
| `originatingNpId` | BAP for a buyer grievance, BPP for a seller grievance. Never changes |
| `raisedBy`, `raisedAgainst` | Who raised it, and who it is about (an allegation, not a finding of fault) |
| `assignedNpId` | Participant expected to respond |
| `category` | Kind of problem, for example `DAMAGED_ITEM`, `WRONG_RETURN`, `REFUND_NOT_RECEIVED` |
| `description` | Short statement of the problem; no contact data or chat transcript |
| `affected[]` | Order lines (`commitmentId`) or performances (`performanceId`) concerned |
| `policyRef` | Grievance SLA policy bound to the order |
| `channelMode` | `LIVE`, `URGENT`, `ASYNC` or `EMERGENCY`. Emergencies use a direct safety channel, never an asynchronous `on_support` |
| `resolution` | The active resolution version and its actions |
| `decision` | Acceptance or rejection of one whole version |
| `execution` | Executed actions with their references |
| `explanation` | Reason for a status change or objection |
| `relatedReferences[]` | Records in other flows the grievance is about: `CONTRACT`, `PERFORMANCE`, `SETTLEMENT`, `RECONCILIATION`, `DISPUTE`, `EVIDENCE`, `OTHER` |

Required by event:

| `eventType` | Required besides the base fields |
|---|---|
| `OPENED` | `openedAt`, `raisedBy`, `raisedAgainst`, `category`, `description`; `caseStatus` is `OPEN` |
| `OPENED` with `RETURN_REJECTED`, `RETURN_PICKUP_FAILED`, `RETURN_QC_DISPUTED` or `REFUND_NOT_RECEIVED` | `relatedReferences` with a `CONTRACT`, `PERFORMANCE` or `SETTLEMENT` entry |
| `RESOLUTION_PROPOSED`, `RESOLUTION_DECIDED`, `ACTION_COMPLETED`, `RESOLVED` | `resolution` |
| `RESOLUTION_DECIDED` | `decision` |
| `ACTION_COMPLETED` | `execution` |
| `RESOLVED` | `caseStatus` is `RESOLVED` |
| `OBJECTION` | `explanation`; `caseStatus` is `OPEN` or `IN_PROGRESS` |
| `CLOSED` | `caseStatus` is `CLOSED` |

### Resolution

One proposal is active at a time. It may hold several actions, and it is
accepted or rejected as a whole; a new `version` of the same `proposalId`
replaces every earlier one.

| `authorizationType` | Who allows the actions | Required |
|---|---|---|
| `EXPLICIT_AGREEMENT` | The counterparty accepts this exact version in `RESOLUTION_DECIDED` | `decision` before execution |
| `POLICY_AUTHORIZED` | A policy bound to the order defines eligibility, verifier, amount and liable party, and the designated verifier confirmed the conditions. A general permission to refund is not enough | `policyRef`, `verification` |
| `UNILATERAL` | The proposing participant funds the actions itself | `fundingNpId` |

Each action states its `type` (`REFUND`, `REPLACEMENT`, `REDELIVERY`,
`CANCELLATION`, `ADJUSTMENT`, `INFORMATION_PROVIDED`, `NO_ACTION`,
`WITHDRAWN`, `OTHER`), the lines it affects, its `executionMethod`
(`CONTRACT_UPDATE`, `SETTLEMENT`, `PERFORMANCE`, `NONE`, `OTHER`) and, when it
moves money, a `financialEffect`:

| Field | Meaning |
|---|---|
| `effectType` | `REFUND`, `ADJUSTMENT`, `EXTRA_CHARGE` or `CREDIT` |
| `amount`, `currency` | Amount, never negative; `IDR` (`IONPayment.currency`) |
| `allocationBasis` | `EXPLICIT`, `POLICY` or `UNILATERAL`; matches `authorizationType` |
| `liablePartyId` | Participant bearing the amount; required for `UNILATERAL` |
| `policyRef` | Allocating policy; required for `POLICY` |
| `settlementRef` | `Settlement.id` the money moves under |

### Linking returns, cancellations and refunds

A grievance about a return, cancellation or refund made through `update` or
`cancel` points at the records that already exist:

- the return is a `Performance` with its own `id` (`PERFORMANCE`);
- a whole-contract cancellation is the contract (`CONTRACT`);
- the refund is a `Settlement` with its own `id` (`SETTLEMENT`).

When the grievance completes a refund already agreed in the order flow, its
refund action reuses that refund's `Settlement.id` in `settlementRef`, so that
SEAM does not count the refund twice. A refund newly created by the grievance
gets a new `Settlement.id`, with `relatedSettlementId` pointing to the earlier
settlement ([Settlement](../../Settlement/v1/README.md)).

## Rules enforced by ONIX

JSON Schema checks one message. These rules need the message's context or
the grievance's earlier events:

1. `context.bapId` and `context.bppId` are always the BAP and BPP of the
   order, whoever starts the grievance. `/support` is sent by the BAP and
   `/on_support` by the BPP.
2. A seller grievance starts with an `/on_support` that follows no `/support`.
   This unsolicited `on_support`, and further events on the same endpoints,
   are an ION profile rule pending approval: Beckn 2.0.0 defines
   `/on_support` only as the callback of an accepted `/support`. Raised in
   [protocol-specifications-v2#205](https://github.com/beckn/protocol-specifications-v2/issues/205)
   and [fabric-support#117](https://github.com/Networks-for-Humanity/fabric-support/issues/117).
3. A direct callback repeats the request's `context.messageId`; every new
   event gets a new one. `context.transactionId` is the order's transaction.
4. `decision.proposalId` and `decision.version` equal the latest
   `resolution` version; a decision on an older version is rejected.
5. `decision.decidedByNpId` is never `resolution.proposedByNpId`.
6. `financialEffect.allocationBasis` matches `authorizationType`
   (`EXPLICIT_AGREEMENT` – `EXPLICIT`, `POLICY_AUTHORIZED` – `POLICY`,
   `UNILATERAL` – `UNILATERAL`). For `UNILATERAL`, `liablePartyId` is the
   `fundingNpId`: a unilateral remedy never makes the counterparty liable.
7. Every `execution.actionExecutions[].actionId` is an action of the
   resolution.
8. `RESOLVED` requires an `executionReference` for every action whose
   `executionMethod` is not `NONE`, and an `ACCEPTED` decision when the
   resolution is `EXPLICIT_AGREEMENT`.
9. When `relatedReferences` holds a `SETTLEMENT`, every `REFUND` effect
   states `settlementRef`.
10. Only the originating participant sends `OBJECTION` or `CLOSED`.
11. A protocol ACK is never a decision, and neither `RESOLVED`, deemed
    closure nor silence is agreement to a financial adjustment: final figures
    are agreed only in `reconcile` / `on_reconcile`.

## Examples

| Example | Shows |
|---|---|
| [`opened-damaged-item.json`](examples/opened-damaged-item.json) | Buyer grievance opened by the BAP |
| [`opened-wrong-return.json`](examples/opened-wrong-return.json) | Seller grievance opened by the BPP about a wrong return |
| [`resolution-rejected.json`](examples/resolution-rejected.json) | Version 1 rejected by the BAP |
| [`resolved.json`](examples/resolved.json) | Version 2 accepted, refund executed, grievance resolved |
| [`refund-not-received-policy.json`](examples/refund-not-received-policy.json) | Refund of an in-policy return never arrived; the BPP retries it on the same settlement under the order's return policy |
| [`unilateral-goodwill-refund.json`](examples/unilateral-goodwill-refund.json) | BAP goodwill refund at its own cost |
| [`objection.json`](examples/objection.json) | The BAP objects after `RESOLVED` |

The Storefront flow carries the complete `/support` and `/on_support`
messages of a buyer grievance:
[grievance phase](../../../../flows/trade/patterns/storefront/v1/README.md#grievance).

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-26 | Initial draft |
