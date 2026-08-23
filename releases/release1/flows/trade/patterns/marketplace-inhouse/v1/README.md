# Trade Marketplace In-house Pattern v1

This flow specializes Storefront for a first-party or consignment marketplace
that holds stock, invoices centrally, and fulfils from its own centres. All wire
fields use existing Release 1 packs; no root schema migration was required.

Brand consignment and payout are internal marketplace relationships and are not
represented. Post-order reconciliation is excluded because its root pack uses
the non-Beckn `reconcile` action.

See [`pattern.yaml`](pattern.yaml) and
[`docs/01-happy-path.md`](docs/01-happy-path.md).

