# trade/consideration/v1

Retail monetary consideration with ION tax-detail refinement, and the
commission an order comes to, on the contract's price consideration.

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

## Examples

- [`examples/pizza-order-breakup.json`](examples/pizza-order-breakup.json) — a price breakup with tax.
- [`examples/offer-buyer-finder-fee.json`](examples/offer-buyer-finder-fee.json) — an offer's price consideration with its buyer finder fee terms (3% of the item value).
- [`examples/contract-buyer-finder-fee.json`](examples/contract-buyer-finder-fee.json) — a contract's price consideration with the order's total buyer finder fee.

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
