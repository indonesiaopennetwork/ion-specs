# Release 1 schemas

All schema contracts and their vendored schema dependencies are contained below
this directory:

- `common/` contains the four common packs required by Trade, and the
  Settlement pack (`IONSettlementReconciliation`) used by reconciliation.
- `extension/trade/` contains the nine Release 1 Trade packs.
- `vendored/beckn/` contains the pinned upstream Beckn protocol contract at
  `api/v2.0.0/beckn.yaml` and the separately vendored schema dependencies.
- `core/` contains `api/v2.0.0/ion-additional.yaml`, which holds the ION
  endpoints Beckn does not define. Release 1 explicitly excludes the
  unreconciled `ion.yaml` aggregate.

The public namespace mirrors this structure at
`https://schema.ion.id/release1/schema/`.
