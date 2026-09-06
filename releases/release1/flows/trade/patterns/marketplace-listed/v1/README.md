# Trade Marketplace Listed Pattern v1

This flow specializes Storefront for a third-party marketplace BAP routing an
order to an independent seller BPP. `PLATFORM_FEE` is available in the vendored
RetailConsideration breakup enum, and `collectedBy=BAP` represents marketplace
payment collection. No additional schema pack was required.

The source pattern's post-delivery finder-fee reconciliation is excluded because
the root reconcile pack depends on non-Beckn `reconcile` actions. This flow only
defines transaction-time consideration and the seller-facing Beckn sequence.

See [`pattern.yaml`](pattern.yaml) and
[`docs/01-happy-path.md`](docs/01-happy-path.md).

