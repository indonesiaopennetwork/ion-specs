# Trade Live Commerce Pattern v1

This Release 1 flow covers physical-goods purchases initiated from a live stream,
OTT shoppable moment, social-commerce surface, or attributed content link. It
uses only the standard Beckn catalog, `select`, `init`, `confirm`, and status
actions.

## API sequence

```text
BPP -> publish_catalog -> ION Catalogue Service
ION Catalogue Service -> on_discover -> BAP
BAP -> select -> BPP -> on_select
BAP -> init -> BPP -> on_init
BAP -> confirm -> BPP -> on_confirm
BPP -> on_status [PACKED, DISPATCHED, OUT_FOR_DELIVERY, DELIVERED]
```

The Offer carries a Beckn `TimePeriod` validity window plus Release 1 TradeOffer
reservation, stock-cap, per-user-cap, and queue fields. `TradeContract.source`
records channel-neutral session, content, creator, affiliate, and platform
attribution.

Use `source.channel = STREAMING_COMMERCE` for live or OTT content and
`SOCIAL_COMMERCE` for social or affiliate content. The more specific source is
carried by the other `source` fields.

## Release 1 boundary

Group-buy states are excluded because they are not present in the standard Trade
performance state machine. Creator-specific commission breakup enums and
reconciliation amounts are also excluded; `TradeConsideration` supports the
standard Beckn breakup types only. The former cross-cutting variants and the
excluded `ion.yaml` actions are not part of this flow.

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
