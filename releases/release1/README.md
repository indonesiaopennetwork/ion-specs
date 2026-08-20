# ION Release 1

> **Status: DRAFT — not a published or supported specification release.**

This directory is the working envelope for the first permanent integer release of
the ION Network Specification. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.

## Current state

Migration Phase 2 created only the release envelope:

- `release.yaml` — machine-readable release identity and readiness state;
- `README.md` — this draft warning and entry point; and
- `NOTICES.md` — dependency, attribution, and licensing status.

No API contract, schema pack, flow, policy, error registry, or vendored dependency
has been moved into this directory yet.

## Planned primary API contracts

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
```

The publication gate must reject this draft:

```bash
ruby tools/release/validate_manifest.rb --require-published releases/release1/release.yaml
```

See `docs/ION_Release_Architecture.md` and
`docs/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
