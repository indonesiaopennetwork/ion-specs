# trade/consideration/v1

Retail monetary consideration with ION tax-detail refinement, and the
commission the seller pays the buyer app.

## Attaches to
`beckn:Consideration.considerationAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

RetailConsideration v2.1 requires:

- `currency`
- `totalAmount`

Each inherited `taxDetail` requires `rate`. ION policy determines when
`taxRegime` and `taxCategory` are required.

## Commission

`commission` (`IONCommission`) is what the seller (BPP) pays the buyer app
(BAP) for an order. It is deducted from the seller's payout; it is not a charge
to the buyer and is not part of `breakup` or `totalAmount`.

| Field | Meaning |
|---|---|
| `type` | `PERCENT` or `AMOUNT` |
| `value` | Percentage (0-100) for `PERCENT`; an amount for `AMOUNT` |
| `appliesTo` | `PERCENT` only: `ITEM_TOTAL` (item value excluding tax; default) or `ORDER_TOTAL` (including tax) |
| `amount` | Total commission for the items still ordered; contract only |

- **On `Offer.considerations`** — the seller's terms for the offer. `AMOUNT`
  is a fixed amount per unit sold. `amount` is not set.
- **On `Contract.consideration`** — on the price consideration in force. When
  every offer in the order has identical `PERCENT` terms the contract repeats
  them; otherwise `type` is `AMOUNT` and `value` is the order's total.
  `amount` is the total commission: the BPP sets it in `on_select` and
  `on_init` and recomputes it in `on_cancel` and `on_update`. At
  reconciliation the settlement's `commission.value`
  ([`IONSettlementReconciliation`](../../../../common/Settlement/v1/README.md))
  equals it.

The payout terms (when the seller is paid) are the offer's
`policies.settlement` ([`IONTradeOffer`](../../TradeOffer/v1/README.md)).

## Examples

- [`examples/pizza-order-breakup.json`](examples/pizza-order-breakup.json) — a price breakup with tax.
- [`examples/offer-commission.json`](examples/offer-commission.json) — an offer's price with its commission terms.
- [`examples/contract-commission.json`](examples/contract-commission.json) — a contract's price consideration with the commission amount.

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
| v1 | 2026-10-19 | `commission` (`IONCommission`): the commission the seller pays the buyer app, on offer and contract considerations |
