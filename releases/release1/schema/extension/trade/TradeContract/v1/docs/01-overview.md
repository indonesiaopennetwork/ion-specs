# Trade Contract Extension — Overview

`TradeContract` carries terms and state that govern the trade Contract as a
whole. Execution, monetary obligations, payment events, tax entries, and
logistics declarations remain on their respective Contract subobjects.

## Schema layers

- `RetailContract v2.1` supplies quote, buyer instruction, delivery preference,
  gift, invoice preference, loyalty, and source structures.
- `TradeContract` adds purchase-order, parent-contract, cancellation, and
  subscription concepts, and refines inherited source and gift structures.
- `IONTradeContract` adds ION invoice-document type and composes verified
  Indonesian buyer business registration.

## Lifecycle

- Buyer preferences and attribution normally enter during select or init.
- Provider-confirmed Contract state is returned through on_init/on_confirm.
- Cancellation and subscription state may be updated through the applicable
  update or cancel lifecycle.
- Monetary or execution changes update Consideration, Settlement, Payment, or
  Performance rather than being copied into Contract attributes.

## Audit and history

The Contract carries current agreed state. Monetary history is represented by
Consideration and Settlement records and reconciliation details by
`IONReconcile`; the former `quoteTrail` duplicate is not retained.
