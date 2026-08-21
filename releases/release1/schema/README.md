# Release 1 schemas

All schema contracts and their vendored schema dependencies are contained below
this directory:

- `common/` contains the four common packs required by Trade.
- `extension/trade/` contains the nine Release 1 Trade packs.
- `vendored/beckn/` contains pinned Beckn protocol and schema dependencies.
- `core/` reserves the location for release-native API contracts. Release 1
  explicitly excludes the unreconciled `ion.yaml` aggregate.

The public namespace mirrors this structure at
`https://schema.ion.id/releases/release1/schema/`.
