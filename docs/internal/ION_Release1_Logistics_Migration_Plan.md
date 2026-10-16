# ION Release 1 Logistics Migration Plan

**Status:** Approved working plan

**Plan date:** 2026-10-16

**Target:** `releases/release1/`

**Related decisions:**

- `docs/ION_Release_Architecture.md`
- `docs/ION_Release_Channel_Policy.md`
- `docs/ION_Schema_Style_Guide.md`
- `docs/ION_Schema_Design_Guide.md`
- `docs/internal/ION_Release1_Migration_Inventory.md`

## Purpose

This document defines the reviewable sequence for migrating the legacy ION
Logistics specification into the current Release 1 structure. It is an internal
work record, not a normative Logistics specification.

The migration must preserve the primary Logistics concepts from the legacy ION
work while aligning their placement, naming, references, JSON-LD, examples,
flows, policies, and errors with the current ION release architecture and the
pinned Beckn Protocol v2 core.

## Pinned inputs

The migration begins from these repository revisions:

| Input | Repository | Revision | Role |
|---|---|---|---|
| Legacy ION Logistics | `C:/work/ion/repos/ion-specs-ion-launch` | `33e6b4c40feabecf6b0f6a827b488ff82998c735` | Functional and sector-specific input |
| Beckn Logistics | `C:/work/beckn/repos/logistics` | `4d98c3c9b7244f32f3a900272adc990d870df0bf` | Non-normative comparison only |
| Schema v2 validator | `C:/work/ion/repos/ion-testbed` | `155ba05e7c31f58aafd7606e112ddc1c0ed6a3d0` | External deep schema validation |
| ION target baseline | `C:/work/ion/repos/ion-specs` | `84aee5d3eaa1990ba5a1b2f59a07aee5fa6bf120` | Release 1 migration target |

If any input advances during the migration, record the new revision and explain
which decisions or artifacts were re-reviewed.

## Governing decisions

### Migrate directly from legacy ION

The legacy ION Logistics repository is the migration source. The current Beckn
Logistics repository is not a Release 1 dependency because its examples,
semantic mappings, and object placement are not yet consistently aligned with
the Beckn Protocol v2 core used by ION.

Release 1 Logistics schemas must not inherit from, vendor, or contain active
schema references to the current Beckn Logistics domain objects. Those objects
may be inspected as design input, but they are not authoritative for this
migration.

### Build on the pinned Beckn Protocol v2 core

Every Logistics pack must attach to a valid extension point in the pinned ION
Beckn-derived protocol contract:

| ION pack | Beckn v2 extension point |
|---|---|
| `LogisticsResource` | `Resource.resourceAttributes` |
| `LogisticsProvider` | `Provider.providerAttributes` |
| `LogisticsParticipant` | `Participant.participantAttributes` |
| `LogisticsOffer` | `Offer.offerAttributes` |
| `LogisticsCommitment` | `Commitment.commitmentAttributes` |
| `LogisticsConsideration` | `Consideration.considerationAttributes` |
| `LogisticsContract` | `Contract.contractAttributes` |
| `LogisticsPerformance` | `Performance.performanceAttributes` |
| `LogisticsTracking` | `Tracking.trackingAttributes` |

The default schema parent is the release-local vendored Beckn `Attributes/2.0`
schema. A more specific parent may be adopted only after it is an approved,
compatible, pinned dependency.

### Preserve a future upstream-alignment seam

Each pack should separate geography-neutral Logistics concepts from ION- or
Indonesia-specific additions:

```text
Logistics<ResourceType>
  -> inherits from the release-local Beckn Attributes schema
  -> contains geography-neutral Logistics fields

IONLogistics<ResourceType>
  -> inherits from Logistics<ResourceType>
  -> contains Indonesian regulatory and ION-governance fields
```

Both layers are ION-owned in Release 1. A future release may replace the generic
parent with an official Beckn Logistics schema only after a field-by-field
compatibility review. A published release must never be reparented in place.

### Keep `attributes.yaml` authoritative

For each pack, `attributes.yaml` is the primary authoring source. Its
`schema.json`, `context.jsonld`, `vocab.jsonld`, `profile.json`, `renderer.json`,
examples, documentation, and attachment annotations must agree with it.

### Keep the target green

Invalid legacy files must not be bulk-copied into the normative release tree.
Migration proceeds one complete pack or connected flow at a time. Each commit
must leave the migrated target passing the applicable narrow validators and the
complete Release 1 gate.

## Legacy scope inventory

The legacy source contains:

- nine schema packs: commitment, consideration, contract, offer,
  participant-logistics, performance, provider, resource, and tracking;
- one separate performance-state registry;
- six patterns: parcel, hyperlocal, freight, Ro-Ro, warehouse, and cross-border;
- fifteen variants;
- Logistics-specific errors; and
- Logistics and cross-sector policy material.

The presence of a legacy artifact does not approve it for Release 1. Every
artifact must have a valid target, compatible semantics, and closed dependency
set before inclusion.

## Execution sequence

### Phase 0 — Establish the work record

1. Add this plan and the `docs/internal/` classification.
2. Record the pinned source revisions.
3. Keep the current Beckn Logistics repository outside the normative dependency
   graph.
4. Commit the planning material independently of normative changes.

### Phase 1 — Reopen Logistics scope safely

**Status:** Complete — 2026-10-16

1. Change `contentStatus.logistics` in `release.yaml` from `excluded` to
   `review-required`.
2. Update the Release 1 README, root README, changelog, and migration inventory
   to record the revised draft scope.
3. Extend release-scope validation to recognize
   `schema/extension/logistics/` and `flows/logistics/`.
4. Keep the release status `draft`. Do not mark Logistics `validated` merely
   because work has begun.

Suggested commit:

```text
chore(release1): reopen Logistics for review
```

### Phase 2 — Add migration and connection tooling

1. Add approved source-to-target mappings for Logistics packs.
2. Extend local validation so unpublished release-qualified public URLs can map
   to the local Release 1 tree.
3. Add Logistics connection validation for pack declarations, flow targets,
   state-machine references, error targets, and policy IRIs.
4. Add focused tests for every new validation rule.
5. Add a separate validator for the performance-state registry, which is not a
   normal schema pack.

Tooling changes must precede the artifacts they are intended to protect.

### Phase 3 — Produce the field and ownership inventory

**Status:** Complete — `LogisticsResource`, `LogisticsProvider`,
`LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`,
`LogisticsConsideration`, `LogisticsContract`, `LogisticsPerformance`, and
`LogisticsTracking` plus the `LogisticsPerformanceStates` registry inventoried
on 2026-10-16

Before moving a pack, classify every legacy field as one of:

- inherited from the Beckn v2 core object;
- geography-neutral Logistics extension;
- Indonesia-specific or ION-governed extension;
- existing ION common-pack concept;
- policy rather than schema;
- flow-conditional requirement;
- obsolete or incompatible v1 concept; or
- deferred pending a named decision.

Record the result in an upstream-alignment ledger. The ledger must explain, for
each future Beckn Logistics candidate, whether it is absent, incompatible, under
review, or suitable for a later release.

### Phase 4 — Migrate schema packs as vertical slices

**Status:** In progress — `LogisticsResource`, common `IdentifiableLocation`, `LogisticsProvider`, `LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`, `LogisticsConsideration`, and `LogisticsContract` v1 complete

Use this order so that catalog, selection, contracting, and execution concepts
become available progressively:

1. `LogisticsResource` — complete
2. `LogisticsProvider` — complete
3. `LogisticsParticipant` — complete
4. `LogisticsOffer` — complete
5. `LogisticsCommitment` — complete
6. `LogisticsConsideration` — complete
7. `LogisticsContract` — complete
8. `LogisticsPerformance`
9. `LogisticsTracking`
10. `LogisticsPerformanceStates`

Each schema-pack commit must include the complete pack fileset, documentation,
and at least one valid example. `LogisticsPerformanceStates` is a registry, not
a schema pack; its commit must instead include the registry, documentation,
validator coverage, and graph/flow-reference tests. Do not commit placeholder
generated artifacts.

For each pack:

1. Inventory the legacy fields without changing them.
2. Confirm the public pack name and extension point.
3. Remove fields already owned by the Beckn core object or an approved common
   pack.
4. Separate generic Logistics fields from ION-specific fields.
5. Replace v1 object terminology and references with pinned v2 concepts.
6. Author or update `attributes.yaml`.
7. Synchronize JSON Schema and JSON-LD artifacts.
8. Update profile, renderer, README, docs, and examples.
9. Run the pack-level schema directory validator.
10. Run the complete Logistics schema directory validator.
11. Run offline-reference and public-URL validation.
12. Refresh release artifact checksums.
13. Run the complete Release 1 gate.

Suggested commit form:

```text
feat(logistics): add LogisticsResource v1
```

### Phase 5 — Migrate shared policies deliberately

Policies remain in the root `policies/` tree and retain their independent
governance lifecycle.

1. Inventory the policy IRIs referenced by each approved Logistics flow.
2. Reuse an existing policy when its semantics match.
3. Review legacy Logistics policies individually; do not copy policy bundles
   wholesale.
4. Add a policy only when its identifier, lifecycle, applicability, and schema
   are approved.
5. Regenerate `policies/registry.json` after every policy-source change.
6. Validate that every flow policy reference resolves to exactly one registered
   term.

### Phase 6 — Migrate patterns and variants

Migrate patterns in dependency order:

1. Parcel as the reference Logistics flow.
2. Hyperlocal as a reviewed specialization.
3. Freight.
4. Ro-Ro.
5. Warehouse.
6. Cross-border after its customs, participant, document, and policy closure is
   available.

Then review variants individually in this order:

1. during-transaction;
2. cancellation;
3. cash-on-delivery;
4. delivery-attempts;
5. multi-stop;
6. cold-chain;
7. reverse;
8. exception;
9. weight-dispute;
10. value-added-services;
11. eKYC;
12. incident;
13. RTS handoff;
14. customs-clearance; and
15. cross-cutting.

A flow or branch must be deferred when its defining schema, protocol action,
state, or policy is unavailable. Do not represent missing concepts with ad hoc
tags merely to preserve a legacy example.

### Phase 7 — Migrate connected errors

Do not copy all legacy Logistics errors as a batch. Add an error only when:

- its schema target exists in Release 1;
- its flow target exists or is legitimately absent;
- its affected API exists in the pinned protocol;
- its affected field path matches the migrated schema;
- its sender and recovery guidance remain accurate; and
- its code and category comply with the current error-registry convention.

Regenerate the release-local error registry and refresh artifact checksums after
every error-source change.

### Phase 8 — Validate and close the scope

Logistics may change from `review-required` to `validated` only when:

- every included pack passes the schema directory validator;
- all example objects validate;
- all release schema references resolve offline;
- public URLs map to committed files;
- schema packs, JSON-LD, profiles, renderers, examples, and prose agree;
- included flows and state-machine targets resolve;
- policy IRIs resolve against the shared registry;
- included error targets resolve;
- dependency provenance and licensing are complete;
- generated registries and artifact checksums are current; and
- the complete Release 1 gate passes.

The release remains a draft until the separate publication process is approved.

## Validation commands

Run the narrowest schema validation first. From the schema validator directory:

```powershell
cd C:\work\ion\repos\ion-testbed\tools\schemav2validator
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics\LogisticsResource\v1
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics
```

Replace `LogisticsResource` with the pack under review. Both commands must exit
successfully before committing a schema pack.

From the ION specification repository root, run:

```powershell
ruby tools/release/validate_offline_refs.rb releases/release1
ruby tools/release/validate_public_urls.rb releases/release1
ruby tools/release/record_artifact_checksums.rb --write releases/release1
ruby tools/release/validate_release.rb releases/release1
git diff --check
```

`schema-dir` validates `attributes.yaml`, `schema.json`, `context.jsonld`, and
`vocab.jsonld`. It does not replace validation of profiles, renderers, examples,
flows, state registries, policies, or errors.

## Commit discipline

- Keep planning, tooling, individual packs, policies, flows, variants, errors,
  and final scope changes in separate commits.
- Do not combine a mechanical move with unrelated semantic cleanup.
- Prefer one complete pack, pattern, or variant per commit.
- Record deferrals explicitly instead of silently dropping legacy behavior.
- Include the validators run and their results in the commit message or pull
  request evidence.
- Never commit a partially synchronized schema pack to the normative release
  tree.

## Future Beckn Logistics alignment

When an official Beckn Logistics model is fully aligned with Beckn Protocol v2:

1. pin an immutable upstream revision;
2. compare every ION generic field with the upstream definition;
3. classify exact matches, compatible differences, conflicts, and missing
   upstream concepts;
4. vendor only the required transitive dependency closure;
5. preserve ION-specific fields in the ION layer; and
6. adopt the upstream parent only in a mutable draft release.

If Release 1 has already been published, upstream adoption belongs in Release 2
or a later integer release. Published Release 1 artifacts must not be changed.

## Out of scope for this migration

- repairing or publishing the external Beckn Logistics repository;
- inventing missing Beckn protocol actions;
- changing published ION releases;
- importing legacy policies or errors without connected Release 1 targets; and
- representing deferred concepts through ungoverned tags or undocumented
  extensions.
