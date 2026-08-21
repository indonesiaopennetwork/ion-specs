# ION Release 1

> **Status: DRAFT — not a published or supported specification release.**

This directory is the working envelope for the first permanent integer release of
the ION Trade specification. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.

## Current state

Migration Phases 3 and 4 moved all nine Trade packs and the four common packs
required by Trade into this draft, then vendored the Beckn dependencies at
immutable upstream commits. Active schema references now use Release 1 public
URLs, and the graph resolves offline.

Phase 5 validated the standalone Trade packs and the four common packs required by
Trade, including their JSON-LD documents and all 17 example objects. Phase 6
explicitly excluded the unreconciled `ion.yaml` aggregate and the Logistics,
Hospitality, and Finance sectors from Release 1. Their source material remains
non-normative work in progress outside this release.

Phase 8A adds the independently reviewable subset of the connected Trade
material: the Storefront v1 reference flow, 67 Trade or cross-sector policy
terms, and 8 Trade errors whose schema and flow targets are present in this
release. Other root flows and the errors that depend on them remain
non-normative work in progress for a future integer release.

## Protocol dependency

Release 1 includes the vendored Beckn Protocol contract used by its schemas:

```text
schema/vendored/beckn/protocol/v2.0.0/beckn.yaml
```

Release 1 does not publish `ion.yaml` or a merged `ion-full.yaml`. Its normative
ION-owned schemas are the standalone packs under `schema/common/` and
`schema/extension/trade/`. Pinned dependencies live under `schema/vendored/`;
the scoped `flows/`, `policies/`, and `errors/` trees remain release-level peers.

```text
release1/
  schema/
    core/
    common/
    extension/
    vendored/
  flows/
  policies/
  errors/
```

## Planned public namespace

Files in this directory will map to:

```text
https://schema.ion.id/releases/release1/<path>
```

For example, TradeResource is available at
`https://schema.ion.id/releases/release1/schema/extension/trade/TradeResource/v1/attributes.yaml`.

Draft paths may be visible through the backing repository, but consumers must not
depend on them before publication.

## Validation

Validate the draft manifest:

```bash
ruby tools/release/validate_manifest.rb releases/release1/release.yaml
ruby tools/release/validate_offline_refs.rb releases/release1
ruby tools/release/generate_release_registries.rb releases/release1
ruby tools/release/validate_trade_connections.rb releases/release1
```

Or run the complete local gate, which includes those checks, tool tests, release
scope enforcement, the path map, generated registries, and complete release
artifact checksums:

```bash
ruby tools/release/validate_release.rb releases/release1
```

GitHub Actions uses the same command. The **Release validation** workflow can be
run manually and optionally includes the publication gate.

The publication gate must reject this draft:

```bash
ruby tools/release/validate_manifest.rb --require-published releases/release1/release.yaml
```

See `docs/ION_Release_Architecture.md` and
`docs/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
