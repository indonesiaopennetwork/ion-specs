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

## Commission

`commission` (`IONCommission`) is the commission an order comes to: what the
seller (BPP) pays the buyer app (BAP). It is deducted from the seller's payout;
it is not a charge to the buyer and is not part of `breakup` or `totalAmount`.
It is set only on the contract's price consideration in force. The offer's
terms are the named entries of `policies.commission`
([`IONTradeOffer`](../../TradeOffer/v1/README.md)), not a consideration field.

| Field | Meaning |
|---|---|
| `type` | `PERCENT` or `AMOUNT` |
| `value` | The shared percentage (0-100) for `PERCENT`; the order's total for `AMOUNT` |
| `appliesTo` | `PERCENT` only: `ITEM_TOTAL` (item value excluding tax; default) or `ORDER_TOTAL` (including tax) |
| `amount` | Total commission for the items still ordered |

- `amount` is the sum, over every offer still ordered, of all its
  `policies.commission` entries. The BPP sets it in `on_select` and `on_init`
  and recomputes it in `on_cancel` and `on_update` after cancellations and
  returns.
- When every offer still ordered has exactly one commission entry and they all
  share the same `PERCENT` terms, the contract repeats that `type`, `value` and
  `appliesTo`; otherwise `type` is `AMOUNT` and `value` is the total.
- At reconciliation the settlement's `commission.value`
  ([`IONSettlementReconciliation`](../../../../common/Settlement/v1/README.md))
  equals `amount`.

The payout terms (when the seller is paid) are the offer's
`policies.settlement` ([`IONTradeOffer`](../../TradeOffer/v1/README.md)).

## Examples

- [`examples/pizza-order-breakup.json`](examples/pizza-order-breakup.json) — a price breakup with tax.
- [`examples/contract-commission.json`](examples/contract-commission.json) — a contract's price consideration with the order's commission (two entries on the offer, so `type: AMOUNT` with the total).

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
| v1 | 2026-10-19 | `commission` (`IONCommission`): the commission the order comes to, on the contract's price consideration; the offer's terms are `IONTradeOffer.policies.commission` |
