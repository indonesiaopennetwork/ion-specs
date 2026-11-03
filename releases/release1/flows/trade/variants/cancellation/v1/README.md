# Trade Cancellation Variant v1

This Release 1 variant cancels a confirmed Trade contract, after `on_confirm`
and before delivery. It applies to every included Trade pattern. A delivered
item is returned, not cancelled.

| Sub-branch | Messages | What happens |
|---|---|---|
| `preview` (optional) | `cancel` / `on_cancel` with `context.try: true` | The BPP shows the fee and refund the cancellation would give, and changes nothing |
| `buyer-full` | `cancel` / `on_cancel` | The buyer cancels the whole order |
| `buyer-partial` | `cancel` / `on_cancel` | The buyer cancels some commitments and keeps the rest |
| `rejected` | `on_cancel` with `error` | The BPP refuses a cancellation its policy does not allow |
| `seller-initiated` | proactive `on_update` | The seller cancels, for example when it cannot supply the order |

See [`variant.yaml`](variant.yaml) for the required fields and rules of each
sub-branch, and [`examples/`](examples/) for the messages.

## API sequence

```text
BAP -> cancel (try: true)  -> BPP -> on_cancel (try: true)   optional preview
BAP -> cancel              -> BPP -> on_cancel               contract, or error
BPP -> on_update                                             seller-initiated
```

The BAP names the contract and states the cancellation in
`contractAttributes.cancellation`
([`IONTradeContract`](../../../../../schema/extension/trade/TradeContract/v1/README.md)):
`reason.code`, and `commitmentIds` for a partial cancellation.

## How the outcome is decided

Each cancelled commitment is evaluated against the cancellation terms of its
offer, `offerAttributes.policies.cancellation`: the offer's own `fee` and
`allowedReasons`, and the policy its `policyRef` names in the
[policy registry](../../../../../../../policies/):

- **Allowed:** the policy allows cancellation, its window
  (`cancellationWindowCloses`) has not passed for the performance's current
  state, and the reason is one the offer (`allowedReasons`) and the policy
  (`cancellationReasonsAllowed`) accept. Otherwise the BPP answers with an
  `AsyncError`:

  | Code | When |
  |---|---|
  | `POL_CANCELLATION_NOT_ALLOWED` | The policy forbids cancellation, or its window has passed |
  | `BIZ_INVALID_CANCELLATION_REASON` | The reason is not accepted |
  | `BIZ_ALREADY_CANCELLED` | The contract or a named commitment is already cancelled |

- **Fee:** the offer's `policies.cancellation.fee`: `PERCENTAGE` of the
  amount paid for the commitment, with tax (`value` 10 is 10 percent), or a
  `FIXED` amount. When the offer states no fee, the policy's
  `cancellationFee` applies. The fees are one ACTIVE consideration with a
  `CANCELLATION_FEE` line per commitment charged. A seller cancellation
  charges the buyer no fee.

The contract is never edited in place:

- the cancelled commitments become `CLOSED` (name `Cancelled`);
- the price consideration becomes `CLOSED` and keeps its figures; when items
  remain, a replacement ACTIVE price consideration prices them, with the
  delivery charge, which stays while any item is still ordered;
- the buyer finder fee (`buyerFinderFee.feeAmount`) is recomputed on the
  replacement from the offers' terms, and is 0 when nothing remains;
- the order's payment settlement
  ([`IONSettlementReconciliation`](../../../../../schema/common/Settlement/v1/README.md))
  keeps `orderAmount` and is updated: `commission` follows the buyer finder
  fee, `refundAmount` is what the buyer gets back, itemised by a
  `CANCELLATION` breakup entry, and `netPayable` is the rest, including any
  cancellation fee. The settlement's `considerationId` names the ACTIVE price
  consideration, or the closed one when nothing remains;
- `Contract.status` becomes `CANCELLED` and the performance `CANCELLED` when
  nothing remains.

### Settlement

- **Before payout:** the refund is part of the order's one payment
  settlement. SEAM has the PJP pay `refundAmount` to the buyer, from the
  funds it holds, `commission` to the BAP and `netPayable` to the BPP once the
  settlement is agreed (see the
  [reconciliation API docs](../../../../../schema/core/README.md#settlement-reconciliation)).
- **After payout:** when the payment settlement has already been paid out,
  the refund is a separate correction settlement: its own `Settlement.id`,
  `relatedSettlementId` naming the payment settlement, `adjustmentType`
  `REFUND`, and what the BPP owes back in `recoveryAmount`.
- **Due date:** a fully cancelled contract never reaches its offers'
  `settlementBasis` event (for example `AFTER_DELIVERY`), so the cancellation
  takes its place: the settlement's `dueDate` is `settlementWindow` after the
  cancellation. A partial cancellation leaves the basis unchanged.

## Seller reason codes

A seller cancellation states one of these codes in `cancellation.reason.code`.
Without a valid cause, the cancellation policy's
`sellerPenaltyOnCancelWithoutCause` applies at reconciliation.

| Code | Meaning | Valid cause |
|---|---|---|
| `ITEM_OUT_OF_STOCK` | The item is out of stock | No |
| `ITEM_DAMAGED_BEFORE_DISPATCH` | The item was damaged before dispatch | No |
| `PRICING_ERROR` | The item was listed at a wrong price | No |
| `UNABLE_TO_FULFIL` | The seller cannot prepare or dispatch the order in time | No |
| `UNDELIVERABLE_ADDRESS` | The delivery address cannot be served | Yes |
| `BUYER_UNREACHABLE` | The buyer cannot be reached to complete the order | Yes |
| `BUYER_FRAUD_SUSPECTED` | The order is suspected to be fraudulent | Yes |
| `FORCE_MAJEURE` | Events beyond the seller's control | Yes |

## The example order

The examples cancel one order, `ORD-2026-00020001`, while it is `PACKED`:

| Line | Item | Value | Cancellation policy |
|---|---|---|---|
| `L01` | 1 Kemeja Batik Tulis Parang | 150000 | `cancel.partial.refund-packed-threshold`, offer fee 10 `PERCENTAGE` (window closes at DISPATCHED) |
| `L02` | 2 Keripik Singkong Balado | 50000 | `cancel.standard.until-dispatched`, no fee (window closes at DISPATCHED) |
| | Delivery | 10000 | |
| | PPN 11% on items | 22000 | |
| | **Total paid** | **232000** | Buyer finder fee 3% of items: 6000; payout `AFTER_DELIVERY` + `P1D` |

| Example | Fee | Refund | Commission | Net payable to BPP |
|---|---|---|---|---|
| Before cancellation | | 0 | 6000 | 226000 |
| [Full cancellation](examples/on_cancel_response.json) (reason `CHANGE_OF_MIND`) | 16650 (10% of L01's 166500 with tax) | 215350 | 0 | 16650 |
| [Partial: L02](examples/on_cancel_partial_response.json) (reason `ITEM_NO_LONGER_NEEDED`) | 0 | 55500 | 4500 | 172000 |
| [Seller cancels](examples/on_update_seller_cancellation.json) (reason `ITEM_OUT_OF_STOCK`) | 0 | 232000 | 0 | 0 |

In each case `orderAmount` = `netPayable` + `commission` + `refundAmount`.
The full and seller cancellations happen on 20 April, so their `dueDate` is
2026-04-21.
The [preview](examples/on_cancel_preview_response.json) of the full
cancellation returns the same figures with `context.try: true`. The
[rejected](examples/on_cancel_rejected_response.json) example answers the same
cancel sent after the order was `DISPATCHED`.

## Excluded

- Cancelling some units of a commitment: an update of the commitment's
  quantity, for a later Trade update variant.
- Technical cancellation after a failed confirm: no contract exists to cancel.
- Forced cancellation for a missed provider SLA: `IONTradeContract.cancellation`
  carries the evidence fields, and `penalty.seller-late-dispatch.standard`
  auto-cancels an order dispatched 72 hours late, but no Trade policy states
  the dispatch deadline that lateness is measured from.

## Open points

- **Reason codes in the schema:** the seller codes are listed in this variant;
  `cancellation.reason.code` itself stays a free code. Moving the buyer and
  seller codes into one registered list is left for a later release.
