# Release 1 schemas

All schema contracts and their vendored schema dependencies are contained below
this directory:

- `common/` contains the four common packs required by Trade.
- `extension/trade/` contains the nine Release 1 Trade packs.
- `vendored/beckn/` contains pinned Beckn protocol and schema dependencies.
- `core/` contains release-native API contracts: the settlement
  reconciliation API at `core/reconcile/v1/`. Release 1 explicitly excludes the
  unreconciled `ion.yaml` aggregate.

The public namespace mirrors this structure at
`https://schema.ion.id/release1/schema/`.
