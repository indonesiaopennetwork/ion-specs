# Trade During-Transaction Variant v1

This Release 1 variant adds six optional branches to an included parent pattern:

- fulfilment-mode selection;
- BAP-collected prepayment;
- BAP-collected cash on delivery;
- BPP-collected cash on delivery;
- multiple Performance records linked by `commitmentIds`; and
- cancellation-policy and fee display before confirm.

The BPP-collected prepayment branch was excluded because it relies on an
unsolicited second `on_init`. The on-network LSP branch requires the excluded
Logistics sector. Both technical-confirm cancellation branches misuse NACK and
`cancel` semantics, and one also depends on non-Beckn `raise`.

No new schema pack was needed. The supported branches use existing Payment,
TradeOffer, TradeCommitment, TradeConsideration, and TradePerformance fields.

See [`variant.yaml`](variant.yaml) for the machine-readable requirements.

