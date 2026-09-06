# Trade Made-to-Order Pattern v1

This Release 1 flow covers goods prepared or assembled after confirmation:
custom bakery products, packaged meal kits, tailoring, custom furniture, and
other made-to-order FMCG. Restaurant meals and cloud-kitchen orders belong to
Hospitality and are outside Release 1.

## API sequence

```text
BPP -> publish_catalog -> ION Catalogue Service
ION Catalogue Service -> on_discover -> BAP
BAP -> select -> BPP -> on_select
BAP -> init -> BPP -> on_init
BAP -> confirm -> BPP -> on_confirm
BPP -> on_status [PREPARING, READY, DISPATCHED, OUT_FOR_DELIVERY, DELIVERED]
```

Compared with Storefront, the provider and each resource declare preparation
durations. The concrete cancellation policy
`ion://policy/cancel.mto.nofee-before-prepare` permits free cancellation until
the first `PREPARING` status.

Release 1 does not include the former cross-cutting branches. In particular,
`raise` and `reconcile` behavior from the excluded `ion.yaml` aggregate is
outside this flow.

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

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference.
