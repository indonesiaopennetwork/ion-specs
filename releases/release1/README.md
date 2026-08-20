# ION Release 1

> **Status: DRAFT — not a published or supported specification release.**

This directory is the working envelope for the first permanent integer release of
the ION Network Specification. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.

## Current state

Migration Phase 3 mechanically moved the two primary API files, all nine Trade
packs, and the four common packs required by Trade into this draft. Repository
path literals and references affected by those moves now point to their Release 1
locations.

The move does not certify the content. `ion.yaml` and the common packs remain
review-required, Trade remains validation-pending, and Beckn provenance and
transitive vendoring remain incomplete. Flows, policies, and errors have not yet
been moved into this directory.

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
```

The publication gate must reject this draft:

```bash
ruby tools/release/validate_manifest.rb --require-published releases/release1/release.yaml
```

See `docs/ION_Release_Architecture.md` and
`docs/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
