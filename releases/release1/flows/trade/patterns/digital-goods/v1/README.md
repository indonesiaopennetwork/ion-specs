# Trade Digital Goods Pattern v1

This Release 1 flow covers digital vouchers and subscriptions delivered to the
buyer using `CODE_TO_BUYER` or `QR_VOUCHER`. It uses only standard Beckn catalog,
`select`, `init`, `confirm`, and status actions.

## API sequence

```text
BPP -> publish_catalog -> ION Catalogue Service
ION Catalogue Service -> on_discover -> BAP
BAP -> select -> BPP -> on_select
BAP -> init -> BPP -> on_init
BAP -> confirm -> BPP -> on_confirm [PENDING_OPERATOR]
BPP -> on_status [DELIVERED or DELIVERY_FAILED]
```

Digital delivery type is carried by `resourceTangibility`; `resourceStructure`
remains `PLAIN`, `VARIANT`, or another structural value. A successful committed
Resource may include an access-controlled `digital.redemptionUrl`. A failed
delivery carries the `DELIVERY_FAILED` performance state and a full refund
record.

## Release 1 boundary

`PUSH_TO_TARGET`, `ACCOUNT_CREDIT`, and `DIGITAL_TOP_UP` transactions are
excluded. Release 1 has no transaction-level object for a mobile number, meter
number, game user ID, wallet account, or similar delivery target. It also has no
operator-reference or general digital-delivery failure-reason field. The root
standalone schema packs do not define these objects, so this flow does not invent
them or reuse unrelated free-form tags.

The legacy target-validation error `ION-3018` / `ION-A3005` is therefore not
included in this subset. Physical shipping, Logistics extensions, recurring
subscription actions, and post-order `raise` or `reconcile` actions are also out
of scope.

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

- [BusinessRegistration](../../../../../schema/common/BusinessRegistration/v1/README.md)
- [Payment](../../../../../schema/common/Payment/v1/README.md)
- [Tax](../../../../../schema/common/Tax/v1/README.md)

Use [`pattern.yaml`](pattern.yaml) as the per-step requirements reference.

