# trade/consideration/v1

Retail monetary consideration with ION tax-detail refinement, the buyer
finder fee, and the seller's delivery charge.

## Attaches to
`beckn:Consideration.considerationAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

RetailConsideration v2.1 requires:

- `currency`
- `totalAmount`

Each inherited `taxDetail` requires `rate`. ION policy determines when
`taxRegime` and `taxCategory` are required.

## Buyer finder fee

`buyerFinderFee` (`IONBuyerFinderFee`) is the fee the seller (BPP) pays the
buyer app (BAP) for orders of an offer. It is deducted from the seller's
payout; it is not a charge to the buyer and is not part of `breakup` or
`totalAmount`. It appears in two places:

| Where | Fields | Meaning |
|---|---|---|
| An offer's consideration | `feeType`, `feeValue`, `appliesTo` | The fee terms, one fee per offer: `PERCENT` (0-100) of the offer's item value without tax (`appliesTo: ITEM_TOTAL`, the default) or with tax (`ORDER_TOTAL`), or a fixed `AMOUNT` per unit sold |
| The contract's price consideration in force | `feeAmount` | The order's total: each offer's fee on its own items still ordered, summed |

```json
"offer": { "considerations": [{ "considerationAttributes": {
  "totalAmount": 27750, "breakup": [ … ],
  "buyerFinderFee": { "feeType": "PERCENT", "feeValue": 3, "appliesTo": "ITEM_TOTAL" } } }] }

"contract": { "consideration": [{ "considerationAttributes": {
  "totalAmount": 55500, "breakup": [ … ],
  "buyerFinderFee": { "feeAmount": 1500 } } }] }
```

- The BPP sets `feeAmount` in `on_select` and `on_init` and recomputes it in
  `on_cancel` and `on_update` after cancellations and returns.
- At reconciliation the settlement's `commission.value`
  ([`IONSettlementReconciliation`](../../../../common/Settlement/v1/README.md))
  equals `feeAmount`.

The payout terms (when the seller is paid) are the offer's
`policies.settlement` ([`IONTradeOffer`](../../TradeOffer/v1/README.md)).

## Delivery fee

`deliveryFee` (`IONDeliveryFee`) on an offer's consideration is the charge the
buyer pays for the seller's own delivery: `amount` per order, in the
consideration currency, including any tax (`0` is free delivery).

```json
"offer": { "considerations": [{ "considerationAttributes": {
  "totalAmount": 27750, "breakup": [ … ],
  "deliveryFee": { "amount": 10000 } } }] }

"contract": { "consideration": [{ "considerationAttributes": {
  "totalAmount": 65500, "breakup": [ …,
    { "type": "DELIVERY_CHARGE", "title": "Delivery fee", "amount": 10000 } ] } }] }
```

- One charge per order: when the order's `performanceMode` is `DELIVERY`, the
  BPP charges the highest `deliveryFee.amount` among the offers ordered, once,
  as a `DELIVERY_CHARGE` breakup line on the contract's price consideration,
  included in `totalAmount`. There is no charge for `SELF_PICKUP`.
- The line stays while any item is still ordered, through partial
  cancellations and returns, and is refunded once none is.
- It is not part of the buyer finder fee base.

## Examples

- [`examples/pizza-order-breakup.json`](examples/pizza-order-breakup.json) — a price breakup with tax.
- [`examples/offer-buyer-finder-fee.json`](examples/offer-buyer-finder-fee.json) — an offer's price consideration with its buyer finder fee terms (3% of the item value).
- [`examples/contract-buyer-finder-fee.json`](examples/contract-buyer-finder-fee.json) — a contract's price consideration with the order's total buyer finder fee.
- [`examples/offer-delivery-fee.json`](examples/offer-delivery-fee.json) — an offer's price consideration with the seller's delivery charge per order.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

Missing `taxDetail.rate` or an invalid ION `taxRegime` may be rejected. See
the Release 1 [Trade error registry](../../../../../errors/README.md) for included
errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 | 2026-10-22 | `buyerFinderFee` (`IONBuyerFinderFee`): the fee terms on an offer's consideration and the order's total (`feeAmount`) on the contract's price consideration. Replaces the earlier `commission` here and `IONTradeOffer.policies.commission` |
| v1 | 2026-10-23 | `deliveryFee` (`IONDeliveryFee`): the seller's delivery charge per order on an offer's consideration, charged on the contract as a `DELIVERY_CHARGE` breakup line |
