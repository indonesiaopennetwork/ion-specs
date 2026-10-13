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

`init` and `on_init` agree the terms that
[settlement reconciliation](../../../../../schema/core/reconcile/v1/README.md)
later uses to compute each contract's payout:

| Step | Sender | Carries |
|---|---|---|
| `init` | BAP | `contractAttributes.settlementBasis`, `settlementWindow`, and `finderFee` (proposed); the BAP's `settlementAccounts` entry for the finder fee |
| `on_init` | BPP | The same terms (accepted) with `finderFee.feeAmount` computed from the final price, plus the BPP's `settlementAccounts` entry next to the BAP's |
| `confirm`, `on_confirm` | BAP, BPP | The agreed terms and both accounts, carried into the binding contract |

The buyer's QRIS payment is held at the PJP, not in either participant's
account. After delivery and the agreed one-day window, the BPP sends
[`reconcile_request.json`](examples/reconcile_request.json) with its figures:
order 98900, a 3% finder fee of 2670 on the 89000 item total, and BPP proceeds
of 96230. The BAP answers with
[`on_reconcile_response.json`](examples/on_reconcile_response.json) and
`accord: true`, so SEAM instructs the PJP to pay 96230 to the BPP and 2670 to
the BAP. Either participant may start reconciliation; a disagreement example is
in the [reconciliation pack](../../../../../schema/core/reconcile/v1/README.md).

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

### Core

- [Settlement reconciliation](../../../../../schema/core/reconcile/v1/README.md)

The earlier `localization`, `identity`, and `product-compliance` declarations were
not retained: Identity is represented by Business Registration, while the copied
Storefront payload carries its relevant localized descriptors and regulatory
properties through Beckn descriptors and TradeResource rather than separate
attribute blocks.

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference. The
`examples/` directory contains the Release 1 example messages.
