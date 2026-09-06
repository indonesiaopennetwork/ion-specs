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
```

Release 1 does not include the former cross-cutting branches or the other Trade
patterns. In particular, `raise` and `reconcile` behavior from the excluded
`ion.yaml` aggregate is outside this flow.

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

The earlier `localization`, `identity`, and `product-compliance` declarations were
not retained: Identity is represented by Business Registration, while the copied
Storefront payload carries its relevant localized descriptors and regulatory
properties through Beckn descriptors and TradeResource rather than separate
attribute blocks.

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference. The
`examples/` directory contains the Release 1 example messages.
