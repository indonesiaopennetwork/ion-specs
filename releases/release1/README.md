# ION Release 1

> **Status: DRAFT — not a published or supported specification release.**

This directory is the working envelope for the first permanent integer release of
the ION Network Specification. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.

## Current state

Migration Phases 3 and 4 moved the two primary API files, all nine Trade packs,
and the four common packs required by Trade into this draft, then vendored the
complete Beckn dependency graph at immutable upstream commits. Active schema
references now use Release 1 public URLs, and the graph resolves offline.

Phase 5 validated the standalone Trade packs and the four common packs required by
Trade, including their JSON-LD documents and all 17 example objects. The separate
`ion.yaml` aggregate remains review-required because its embedded Trade models are
not mechanically equivalent to the standalone packs. Flows, policies, and errors
have been reconciled at the repository root but have not yet been moved into this
directory.

## Primary API contracts

Release 1 will expose two primary OpenAPI contracts:

```text
core/api/v2.0.0/ion.yaml
vendored/beckn/protocol/v2.0.0/beckn.yaml
```

The release will not contain a merged `ion-full.yaml`.

## Planned public namespace

Files in this directory will map to:

```text
https://schema.ion.id/releases/release1/<path>
```

Draft paths may be visible through the backing repository, but consumers must not
depend on them before publication.

## Validation

Validate the draft manifest:

```bash
ruby tools/release/validate_manifest.rb releases/release1/release.yaml
ruby tools/release/validate_offline_refs.rb releases/release1
ruby tools/release/validate_trade_connections.rb
```

The publication gate must reject this draft:

```bash
ruby tools/release/validate_manifest.rb --require-published releases/release1/release.yaml
```

See `docs/ION_Release_Architecture.md` and
`docs/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
