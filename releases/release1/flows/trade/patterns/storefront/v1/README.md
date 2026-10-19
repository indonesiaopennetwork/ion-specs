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
```

Release 1 does not include the former cross-cutting branches or the other Trade
patterns. In particular, `raise` behavior from the excluded `ion.yaml`
aggregate is outside this flow.

## Settlement terms

The seller publishes the settlement terms with each offer in the catalog:

- the payout terms in `offerAttributes.policies.settlement`
  ([`IONTradeOffer`](../../../../../schema/extension/trade/TradeOffer/v1/README.md)):
  here `AFTER_DELIVERY` and `P1D`;
- the commission it pays the buyer app in `offerAttributes.policies.commission`
  (named entries that add up): here one entry, `Finder fee`, 3% of the item
  value (`PERCENT`, `ITEM_TOTAL`).

The BPP states the order's commission on the contract's price consideration
([`IONTradeConsideration`](../../../../../schema/extension/trade/TradeConsideration/v1/README.md)
`commission.feeAmount`, the sum over every offer and all its entries) from
`on_select` on. Every offer here has the one 3% `ITEM_TOTAL` entry, so the
contract repeats those terms; otherwise it would state `type: AMOUNT` with the
total. The order's payment settlement is one
[`IONSettlementReconciliation`](../../../../../schema/common/Settlement/v1/README.md)
object from `init` to reconciliation. It carries the payment, the payout
accounts, and the figures:

| Step | Sender | Carries |
|---|---|---|
| `init` | BAP | The payment method, `status: PENDING`, the BAP's `settlementAccounts` entry for the commission, and figures estimated on the `on_select` quote |
| `on_init` | BPP | The commission `feeAmount` on the final price consideration, the figures on that price, the QRIS `methodDetail`, and the BPP's `settlementAccounts` entry next to the BAP's |
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

The reconcile phase uses the `/reconcile` and `/on_reconcile` endpoints of
[`core/api/v2.0.0/ion-additional.yaml`](../../../../../schema/core/README.md#settlement-reconciliation).

The earlier `localization`, `identity`, and `product-compliance` declarations were
not retained: Identity is represented by Business Registration, while the copied
Storefront payload carries its relevant localized descriptors and regulatory
properties through Beckn descriptors and TradeResource rather than separate
attribute blocks.

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference. The
`examples/` directory contains the Release 1 example messages.
