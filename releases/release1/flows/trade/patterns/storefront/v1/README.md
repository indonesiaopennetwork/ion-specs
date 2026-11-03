# Trade Storefront Pattern v1

This is the Release 1 reference flow for a consumer purchasing a packaged
physical product for delivery or self-pickup.

## API sequence

```text
BPP -> publish_catalog -> ION Catalogue Service
ION Catalogue Service -> on_discover -> BAP
BAP -> select -> BPP -> on_select
BAP -> init -> BPP -> on_init
BAP -> confirm -> BPP -> on_confirm
BPP -> on_status [PACKED, DISPATCHED, OUT_FOR_DELIVERY, DELIVERED]
BPP -> reconcile -> BAP -> on_reconcile    (after the settlement falls due)
BAP -> support -> BPP -> on_support        (optional grievance, after on_confirm)
```

Release 1 does not include the former cross-cutting branches or the other Trade
patterns. In particular, `raise` behavior from the excluded `ion.yaml`
aggregate is outside this flow.

## Settlement terms

The seller publishes the settlement terms with each offer in the catalog:

- the payout terms in `offerAttributes.policies.settlement`
  ([`IONTradeOffer`](../../../../../schema/extension/trade/TradeOffer/v1/README.md)):
  here `AFTER_DELIVERY` and `P1D`;
- the buyer finder fee it pays the buyer app on the offer's consideration,
  `considerationAttributes.buyerFinderFee`: here 3% of the item value
  (`PERCENT`, `ITEM_TOTAL`).

The BPP states the order's total buyer finder fee on the contract's price
consideration
([`IONTradeConsideration`](../../../../../schema/extension/trade/TradeConsideration/v1/README.md)
`buyerFinderFee.feeAmount`, the sum over the offers ordered) from `on_select`
on; the settlement's `commission` equals it. The order's payment settlement is one
[`IONSettlementReconciliation`](../../../../../schema/common/Settlement/v1/README.md)
object from `init` to reconciliation. It carries the payment, the payout
accounts, and the figures:

| Step | Sender | Carries |
|---|---|---|
| `init` | BAP | The payment method, `status: PENDING`, the BAP's `settlementAccounts` entry for the commission, and figures estimated on the `on_select` quote |
| `on_init` | BPP | The buyer finder fee `feeAmount` on the final price consideration, the figures on that price, the QRIS `methodDetail`, and the BPP's `settlementAccounts` entry next to the BAP's |
| `confirm`, `on_confirm` | BAP, BPP | `status: PAID`, `paidAt`, `gatewayRef`, and `orderAmount` as the amount paid, with both accounts |

The buyer's QRIS payment is held at the PJP, not in either participant's
account. After delivery and the agreed one-day window, the BPP sends
[`reconcile_request.json`](examples/reconcile_request.json) with its figures:
order 98900, a 3% commission of 2670 on the 89000 item total, and BPP proceeds
of 96230. The BAP answers with
[`on_reconcile_response.json`](examples/on_reconcile_response.json) and
`accord: true`, so the settlement is agreed and SEAM, after verifying the funds
and accounts, has the PJP pay 96230 to the BPP and 2670 to the BAP. Either
participant may start reconciliation. Agreement is per settlement; a batch
with agreed, disputed and pending settlements, where only the unresolved ones
are sent again, is shown in the
[reconciliation API docs](../../../../../schema/core/README.md#settlement-reconciliation).

## Grievance

Either participant may raise a grievance about the order after `on_confirm`.
Each `/support` and `/on_support` message carries one event as an
[`IONGrievance`](../../../../../schema/common/Grievance/v1/README.md) in
`message.support.supportAttributes`, which assumes the optional
`Support.supportAttributes` slot proposed to Beckn: until Beckn releases it,
these messages do not validate against the vendored Beckn contract.

Returns and cancellations within the order's policy are not grievances: the
buyer app sends `update` for part of the order or `cancel` for the whole
contract. A grievance is raised when one of them goes wrong (the return is
rejected, the pickup never happens, the QC result is disputed or the refund
never arrives), and it links the return performance, refund settlement or
contract in `relatedReferences`.

The example is a buyer grievance: the pizza arrived crushed, the seller offers
a partial refund and the buyer accepts it.

| Step | Sender | Example | Carries |
|---|---|---|---|
| `support` | BAP | [`support_OPENED.json`](examples/support_OPENED.json) | Grievance `GRV-2026-00004400`, category `DAMAGED_ITEM`, against the seller, on line `L01` |
| `on_support` | BPP | [`on_support_ACKNOWLEDGED.json`](examples/on_support_ACKNOWLEDGED.json) | Acknowledgement; the callback repeats the request's `messageId` |
| `on_support` | BPP | [`on_support_RESOLUTION_PROPOSED.json`](examples/on_support_RESOLUTION_PROPOSED.json) | Version 1: refund 30000 on `L01`, borne by the BPP, `EXPLICIT_AGREEMENT` |
| `support` | BAP | [`support_RESOLUTION_DECIDED.json`](examples/support_RESOLUTION_DECIDED.json) | Version 1 `ACCEPTED` as a whole |
| `on_support` | BPP | [`on_support_ACTION_COMPLETED.json`](examples/on_support_ACTION_COMPLETED.json) | Refund executed on settlement `PAY-RFD-2026-00004400`, with its reference |
| `on_support` | BPP | [`on_support_RESOLVED.json`](examples/on_support_RESOLVED.json) | Grievance `RESOLVED` with the full record |

With no objection within the objection period of
`ion://policy/grievance-sla.consumer.standard`, both participants treat the
grievance as closed without another message. The refund is not settled by the
grievance: its settlement is agreed in `reconcile` like any other. Other
cases (a seller grievance, a rejected version, a policy-authorized retry of a
return refund, a unilateral goodwill refund and an objection) are in the
[Grievance pack examples](../../../../../schema/common/Grievance/v1/README.md#examples).

## Included schema packs

### Trade

- [TradeProvider](../../../../../schema/extension/trade/TradeProvider/v1/README.md)
- [TradeResource](../../../../../schema/extension/trade/TradeResource/v1/README.md)
- [TradeOffer](../../../../../schema/extension/trade/TradeOffer/v1/README.md)
- [TradeCommitment](../../../../../schema/extension/trade/TradeCommitment/v1/README.md)
- [TradeConsideration](../../../../../schema/extension/trade/TradeConsideration/v1/README.md)
- [TradePerformance](../../../../../schema/extension/trade/TradePerformance/v1/README.md)
- [TradeContract](../../../../../schema/extension/trade/TradeContract/v1/README.md)
- [TradeSettlement](../../../../../schema/extension/trade/TradeSettlement/v1/README.md)
- [TradePerformanceStates](../../../../../schema/extension/trade/TradePerformanceStates/v1/README.md)

### Common

- [Address](../../../../../schema/common/Address/v1/README.md)
- [BusinessRegistration](../../../../../schema/common/BusinessRegistration/v1/README.md)
- [Payment](../../../../../schema/common/Payment/v1/README.md)
- [Tax](../../../../../schema/common/Tax/v1/README.md)
- [Settlement](../../../../../schema/common/Settlement/v1/README.md)
- [Grievance](../../../../../schema/common/Grievance/v1/README.md)

The reconcile phase uses the `/reconcile` and `/on_reconcile` endpoints of
[`core/api/v2.0.0/ion-additional.yaml`](../../../../../schema/core/README.md#settlement-reconciliation).

The earlier `localization`, `identity`, and `product-compliance` declarations were
not retained: Identity is represented by Business Registration, while the copied
Storefront payload carries its relevant localized descriptors and regulatory
properties through Beckn descriptors and TradeResource rather than separate
attribute blocks.

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference. The
`examples/` directory contains the Release 1 example messages.
