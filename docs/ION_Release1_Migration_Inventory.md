# ION Release 1 Migration Inventory

**Status:** Working inventory

**Inventory date:** 2026-08-21

**Target:** `releases/release1/`

**Related decision:** `docs/ION_Release_Architecture.md`

## Purpose

This document inventories the changes required to reorganize the current ION
repository into the permanent integer-release structure defined by the release
architecture decision.

It deliberately separates:

1. **Mechanical migration** — moving files and rewriting paths without changing
   protocol meaning.
2. **Semantic review** — correcting or approving schemas, flows, policies, errors,
   and examples before publication.
3. **Publication** — changing the release manifest from `draft` to `published` and
   making the release immutable.

Moving an artifact into a draft release does not certify that artifact. No schema
whose accuracy is uncertain may become part of a published release merely because
it was mechanically moved.

## Fixed decisions

The following decisions are already accepted:

- Complete ION bundles use integer names: `release1`, `release2`, and so on.
- Release directories live under `releases/` on `main`.
- Published release directories are permanent and immutable.
- Draft release directories may change until publication.
- The public path mirrors the path below `releases/`:
  `https://schema.ion.id/releases/release1/<path>`.
- Published schema `$ref` values use absolute, release-qualified
  `schema.ion.id` URLs.
- JSON-LD semantic IRIs are not blindly rewritten as schema dependencies.
- Beckn validation dependencies are vendored transitively within each release.
- There is no merged `ion-full.yaml`; the two primary API contracts are the
  vendored `beckn.yaml` and ION-native `ion.yaml`.
- Cross-sector extension packs move from the confusing `core` classification to
  `common` in the release structure.
- Common repository documentation remains in the root `docs/` directory.
- Errors, policies, and flows are versioned with the release.
- Repository tooling remains at the root and becomes release-aware.

## Content-confidence model

The initial confidence classification supplied for this migration is:

| Area | Initial status | Release 1 treatment |
|---|---|---|
| Trade schemas | Trusted baseline | Move mechanically, then run full validation |
| Common schemas | Review required | Review at least every pack used by Trade before Trade can be approved |
| Logistics schemas | Review required | Correct and approve separately before publication |
| Hospitality schemas | Review required | Correct and approve separately before publication |
| Finance schemas | Review required | Correct and approve separately before publication |
| Reserved sectors | Documentation only | Do not imply normative support without schemas and approval |
| `ion.yaml` | Mixed content | Reconcile embedded components and registry declarations with approved release scope |
| Flows, policies, errors | Review follows dependencies | Approve only after referenced schemas and identifiers are stable |

`Trusted baseline` does not mean validation may be skipped. It means Trade is the
reference implementation against which migration tooling and release conventions
should first be proven.

The draft release manifest should expose this state explicitly:

```yaml
release: 1
name: release1
status: draft
publishedAt: null
publicBaseUrl: https://schema.ion.id/releases/release1/
sourceBranch: main

contentStatus:
  ionApi: review-required
  trade: validation-pending
  common: review-required
  logistics: review-required
  hospitality: review-required
  finance: review-required
dependencyStatus: incomplete
dependencies: []
artifactChecksums: {}
```

Allowed content states and the transition rules between them must be defined in
the release manifest schema. The content states are `review-required`,
`validation-pending`, `validated`, and `excluded`; publication is a separate
release-level status.

## Phase 1 outputs

Phase 1 establishes migration inputs without moving normative files:

- `tools/release/release-manifest.schema.json` defines the `release.yaml` contract
  and publication gates.
- `tools/release/validate_manifest.rb` enforces cross-field rules, including
  agreement between the integer release, release name, and public base URL.
- `tools/release/release1-path-map.json` records 15 approved mechanical mappings:
  the two primary API files, nine Trade packs, and the four common packs directly
  referenced by Trade (`Address`, `BusinessRegistration`, `Payment`, and `Tax`).
- `tools/release/validate_path_map.rb` verifies that mappings are unique, the
  required pre- or post-migration locations exist, targets stay within Release 1,
  and public URLs mirror target paths.
- `tools/release/tests/` contains focused manifest validation tests and a draft
  fixture. The fixture is not the Release 1 manifest.
- Confirmed `.DS_Store` and Python bytecode artifacts were removed and ignored.

The remaining common-pack public names and all review-required sector names remain
unapproved until their semantic review. The path map must be expanded only after
those decisions are recorded.

## Phase 2 outputs

Phase 2 creates the release envelope without moving normative artifacts:

- `releases/release1/release.yaml` is the canonical draft manifest. It records
  incomplete dependencies and the review state of each content group.
- `releases/release1/README.md` identifies the release as unsupported while it is
  a draft and documents the planned API locations.
- `releases/release1/NOTICES.md` is the placeholder for dependency provenance,
  licenses, modifications, and checksums populated during vendoring.
- `tools/release/validate_manifest.rb --require-published` is the publication
  gate. Ordinary validation accepts the Release 1 draft, while publication-mode
  validation rejects it until all publication requirements are satisfied.

No schema, flow, policy, error, or other normative artifact was moved in Phase 2.

## Phase 3 outputs

Phase 3 mechanically applies the 15 approved mappings:

- the ION and Beckn API files moved to their Release 1 API and vendored paths;
- all nine Trade packs and the four Trade-required common packs moved into the
  Release 1 draft;
- exact repository path literals in connected flows, errors, tools, and
  documentation were updated to the mapped targets;
- relative references affected by the moves were changed to absolute,
  release-qualified `schema.ion.id` URLs;
- schema IDs, context-document URLs, example context URLs, and vocabulary-document
  references affected by the moves were made release-qualified, while semantic
  vocabulary IRIs were left unchanged; and
- the old mapped files and version directories no longer contain normative copies.

All moved YAML, JSON, and JSON-LD files parse. The post-migration path-map gate
confirms all 15 targets exist. Reference inspection resolves 511 local or
release-qualified references and JSON Pointers, except for four pre-existing
internal pointers in `ion.yaml` to absent local components (`Attributes`,
`GeoJSONGeometry`, and `Document`). Those are content defects, not move defects,
and remain review gates. Phase 4 must also close 139 active `schema.beckn.io`
references across 10 upstream documents in the moved draft subset.

Flows, policies, and errors remain at the repository root; only their schema path
literals were updated in this phase.

## Pre-migration repository inventory

The counts and paths below record the inventory used to plan the migration. They
describe the repository before Phase 3 and are retained as the migration baseline.

### Primary API contracts

Before Phase 3, the API directory contained:

```text
schema/core/v2/api/v2.0.0/
  README.md
  beckn.yaml
  ion.yaml
```

`beckn.yaml` is the vendored Beckn Protocol contract. `ion.yaml` is the native ION
contract. The removed `schema/dist/ion-full.yaml` is not part of the target model.

`ion.yaml` currently contains 49 component schemas. Its schema-pack matrix declares:

- 11 common packs under the current `core` key;
- 8 Trade packs;
- 10 Logistics packs; and
- 1 Hospitality pack.

The standalone extension tree contains more packs than this matrix. Publication
therefore requires an explicit reconciliation of embedded `ion.yaml` components,
standalone packs, the schema-pack matrix, sector activation, and the chosen
Release 1 scope.

### Standalone extension packs

The current tree contains 56 versioned pack directories and 577 files:

| Current area | Pack directories | Files | Target classification |
|---|---:|---:|---|
| `schema/extensions/core/` | 13 | 145 | `releases/release1/common/` |
| `schema/extensions/trade/` | 9 | 94 | `releases/release1/extension/trade/` |
| `schema/extensions/logistics/` | 11 | 115 | `releases/release1/extension/logistics/` |
| `schema/extensions/hospitality/` | 10 | 103 | `releases/release1/extension/hospitality/` |
| `schema/extensions/finance/` | 13 | 116 | `releases/release1/extension/finance/` |

Reserved `healthcare`, `mobility`, and `tourism` extension directories currently
contain sector-level README material but no versioned schema packs.

### Flows

The current `flows/` tree contains 270 files:

| Area | Patterns | Variants | Files | Initial status |
|---|---:|---:|---:|---|
| Trade | 13 | 6 | 107 | Review after Trade/common paths stabilize |
| Logistics | 6 | 15 | 82 | Review required with Logistics schemas |
| Hospitality | 1 | 6 | 22 | Review required with Hospitality schemas |
| Finance | 2 | 16 | 55 | Review required with Finance schemas |
| Healthcare | 0 | 0 | 1 | Documentation only |
| Mobility | 0 | 0 | 1 | Documentation only |
| Tourism | 0 | 0 | 1 | Documentation only |

### Policies

The current `policies/` tree contains:

- 129 source YAML files;
- one generated `registry.json`;
- one generator script; and
- supporting README material.

Policy source YAML and the generated registry move into the draft release. The
generator script moves to root tooling and must accept an explicit release path.
Duplicate basenames exist across sector and cross-sector directories. They are not
automatically errors, but their policy IRIs and generated registry keys must be
checked for uniqueness before publication.

### Errors

The current `errors/` tree contains:

- 12 source YAML files;
- four generated registry JSON files;
- one generator script; and
- supporting README material.

Error source YAML and generated registries move into the draft release. The
generator script moves to root tooling and must accept an explicit release path.
Existing `schema_ref` values point to current core and extension paths and must be
rewritten only after the final Release 1 paths are established.

### Root documentation and tooling

The root `docs/` directory is retained as the common documentation set. Root
governance, contributor, architecture, and working documents remain outside the
release. Release-specific behavior must not exist only in mutable root prose.

Current tools hard-code paths under `schema/`, `flows/`, `policies/`, and `errors/`.
The principal affected tools are:

- `tools/ion_required_fields.py`;
- `tools/ion_setup.py`;
- `errors/generate_registry.py`; and
- `policies/generate_registry.py`.

The two registry generators should move under `tools/`. All four tools need an
explicit release-root argument and tests against at least `release1`.

## Target Release 1 layout

```text
releases/
  release1/
    release.yaml
    README.md
    NOTICES.md

    core/
      api/
        v2.0.0/
          ion.yaml

    common/
      <SchemaName>/
        v1/
          attributes.yaml
          schema.json
          context.jsonld
          vocab.jsonld
          profile.json
          renderer.json
          README.md
          docs/
          examples/

    extension/
      trade/
        <SchemaName>/v1/
      logistics/
        <SchemaName>/v1/
      hospitality/
        <SchemaName>/v1/
      finance/
        <SchemaName>/v1/

    vendored/
      beckn/
        protocol/v2.0.0/beckn.yaml
        schemas/<SchemaName>/<upstream-version>/attributes.yaml

    flows/
    policies/
    errors/
```

The release does not contain `dist/`. A release-level `docs/` directory is added
only if genuinely release-specific documentation is identified.

## Current-to-target path mapping

### API and normative registries

| Current path | Draft Release 1 path | Transformation |
|---|---|---|
| `releases/release1/core/api/v2.0.0/ion.yaml` | `releases/release1/core/api/v2.0.0/ion.yaml` | Move, then rewrite release references |
| `releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml` | `releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml` | Re-vendor from verified immutable source; record provenance |
| `schema/extensions/core/` | `releases/release1/common/` | Rename classification and approve public schema directory names |
| `schema/extensions/<sector>/` | `releases/release1/extension/<sector>/` | Move; normalize public schema directory names only after review |
| `flows/` | `releases/release1/flows/` | Move normative content; rewrite pack identifiers and links |
| `policies/` | `releases/release1/policies/` | Move sources and registry, excluding generator script |
| `errors/` | `releases/release1/errors/` | Move sources and registries, excluding generator script |

The initial move must preserve file content except where a path must change to
remain resolvable. Semantic corrections belong in later, area-specific changes.

### Common pack mapping

The current folder names are listed below. Target public names are provisional
until common-pack review confirms the canonical schema concept.

| Current pack | Provisional target directory | Publication gate |
|---|---|---|
| `core/address/v1` | `common/Address/v1` | Validate `IONAddress` and Trade references |
| `core/business-registration/v1` | `common/BusinessRegistration/v1` | Resolve duplicate identity with `identity` |
| `core/identity/v1` | `common/Identity/v1` | Resolve duplicate profile ID and scope |
| `core/localization/v1` | `common/Localization/v1` | Decide canonical public name and spelling |
| `core/participant/v1` | `common/Participant/v1` | Validate attachment model |
| `core/payment/v1` | `common/Payment/v1` | Validate Trade dependencies and vocabulary URLs |
| `core/product-compliance/v1` | `common/ProductCompliance/v1` | Resolve duplicate product pack identity |
| `core/product/v1` | `common/Product/v1` | Resolve overlap with `product-compliance` |
| `core/raise/v1` | `common/Raise/v1` | Confirm whether public concept is Raise or Ticket |
| `core/rating/v1` | `common/Rating/v1` | Validate upstream version and attachment |
| `core/reconcile/v1` | `common/Reconcile/v1` | Confirm Reconcile versus Reconciliation naming |
| `core/support/v1` | `common/Support/v1` | Validate attachment and context |
| `core/tax/v1` | `common/Tax/v1` | Validate Trade consideration dependency |

### Trade pack mapping

Trade supplies the naming and validation baseline. These public directory names are
still checked during migration, but do not require a prior semantic redesign.

| Current pack | Proposed target directory | Primary schema |
|---|---|---|
| `trade/commitment/v1` | `extension/trade/TradeCommitment/v1` | `IONTradeCommitment` |
| `trade/consideration/v1` | `extension/trade/TradeConsideration/v1` | `IONTradeConsideration` |
| `trade/contract/v1` | `extension/trade/TradeContract/v1` | `IONTradeContract` |
| `trade/offer/v1` | `extension/trade/TradeOffer/v1` | `IONTradeOffer` |
| `trade/performance/v1` | `extension/trade/TradePerformance/v1` | `IONTradePerformance` |
| `trade/performance-states/v1` | `extension/trade/TradePerformanceStates/v1` | State registry |
| `trade/provider/v1` | `extension/trade/TradeProvider/v1` | `IONTradeProvider` |
| `trade/resource/v1` | `extension/trade/TradeResource/v1` | `IONTradeResource` |
| `trade/settlement/v1` | `extension/trade/TradeSettlement/v1` | `IONTradeSettlement` |

The current `ion.yaml` schema-pack matrix omits `trade/settlement/v1`; that mismatch
must be resolved before publication.

### Review-required sector packs

The following packs may be moved mechanically, but their final `SchemaName`,
contents, identifiers, and inclusion in Release 1 remain subject to semantic review.

| Sector | Current packs |
|---|---|
| Logistics | `agent`, `commitment`, `consideration`, `contract`, `offer`, `participant-logistics`, `performance`, `performance-states`, `provider`, `resource`, `tracking` |
| Hospitality | `commitment`, `consideration`, `contract`, `delivery`, `fnb-delivery`, `menu-item`, `offer`, `performance`, `provider`, `restaurant-provider` |
| Finance | `consideration`, `contract`, `insurance-consideration`, `insurance-contract`, `insurance-offer`, `insurance-participant`, `insurance-performance`, `insurance-resource`, `offer`, `participant`, `performance`, `resource`, `settlement` |

If an area cannot be validated before Release 1 publication, it must be marked
`excluded` and moved out of the published release contract into a clearly
non-normative work-in-progress location.

## Reference migration inventory

### Beckn schema dependencies

The current schema tree contains 188 active `schema.beckn.io` `$ref` occurrences
across 70 YAML/JSON files, resolving directly to 24 distinct upstream documents.
The direct document families are:

- Beckn base schemas: `Attributes`, `Commitment`, `Consideration`, `Contact`,
  `Contract`, `Offer`, `Participant`, `Performance`, `Provider`, `Quantity`,
  `Resource`, and `Tracking`;
- retail schemas: `RetailCommitment`, `RetailConsideration`, `RetailContract`,
  `RetailOffer`, `RetailPerformance`, `RetailResource`, and `RetailSettlement`;
- logistics schemas: `LogisticsFare`, `LogisticsOperator`, and `Shipment`; and
- hospitality schemas: `FoodAndBeverageOffer` and `FoodAndBeverageResource`.

This is only the direct dependency set. Release construction must fetch from
immutable upstream commits, recursively discover transitive `$ref` dependencies,
record checksums and licenses, and then rewrite validation references to:

```text
https://schema.ion.id/releases/release1/vendored/beckn/...
```

The current `beckn.yaml` provenance must also be verified rather than assumed from
the existing file header.

### ION schema references

Trade schemas currently contain cross-file relative references to:

- the local `beckn.yaml`;
- common Address;
- common Business Registration;
- common Payment; and
- common Tax.

Both `attributes.yaml` and `schema.json` mirrors contain such references. Published
references must use the approved Release 1 absolute URLs. JSON Pointer fragments
must be checked against the moved target documents.

### Public ION URLs and JSON-LD

Hundreds of schema, flow, example, and documentation files contain existing
`https://schema.ion.id/` URLs. Every occurrence must be classified as one of:

- schema `$ref`;
- JSON Schema `$id`;
- JSON-LD context-document URL;
- ION vocabulary or term IRI;
- example payload value; or
- prose/documentation link.

Schema references, schema IDs, context-document URLs, and public artifact links
must become release-qualified where required by the architecture. Semantic IRIs
must be reviewed separately and must not be changed by global text replacement.

Commented raw GitHub `$ref` examples in `ion.yaml` should be removed or replaced
with release-architecture examples so they do not suggest an unsupported resolution
model.

### Repository-relative links

Current path literals are spread across schemas, flows, errors, tools, and common
documentation. The migration tool must update structured path values and Markdown
links using a mapping table. Structured YAML and JSON must be parsed rather than
rewritten with an unrestricted text replacement.

## Metadata and generated-artifact work

For each pack, migration must inspect and synchronize:

- `attributes.yaml` component names, `$ref`s, `x-jsonld`, and attachment metadata;
- `schema.json` `$id`, root `$ref`, definitions, and external references;
- `context.jsonld` document references and term mappings;
- `vocab.jsonld` vocabulary IRIs;
- `profile.json` pack ID, dependencies, version, and attachment information;
- `renderer.json` schema/property references;
- README and narrative documentation links; and
- examples containing `@context`, `@type`, policy IRIs, or schema-pack identifiers.

Generated files must be regenerated from an identified authoritative source. Where
the repository currently lacks a generator, equivalence checks must be added before
publication.

## Known inconsistencies requiring decisions

These findings are not automatically corrected by the mechanical move:

1. **Duplicate pack IDs.** The following distinct directories declare the same
   profile ID while containing different content:
   - `core/identity` and `core/business-registration`;
   - `core/product` and `core/product-compliance`; and
   - `logistics/participant-logistics` and `logistics/agent`.
2. **Overlapping Hospitality concepts.** `provider` and `restaurant-provider`, and
   `delivery`, `fnb-delivery`, and `menu-item`, require scope and canonical-name
   review.
3. **Incomplete profiles.** Several Hospitality profile files do not expose the
   same identifying metadata as established Trade profiles.
4. **Missing renderers.** Six Finance insurance packs and Hospitality `provider`
   lack `renderer.json` despite the documented standard pack file set.
5. **Unclassified Finance notes.** The files
   `schema/extensions/finance/insurance-resource/v1/cmd` and
   `flows/finance/FIN-03/FNC-insurance/patterns/motor-insurance/v1/examples/voc`
   contain human-authored command and vocabulary notes. Finance review must rename,
   relocate, or remove them; they must not be mistaken for normative artifacts.
6. **Generated debris resolved.** The tracked `.DS_Store` and Python bytecode files
   were removed in Phase 1, and matching ignore rules were added.
7. **Matrix mismatch.** The `ion.yaml` schema-pack matrix does not enumerate every
   pack present in the standalone tree.
8. **Embedded-versus-standalone drift risk.** `ion.yaml` embeds ION component
   schemas while standalone pack documents also define schemas. The authoritative
   source and synchronization method must be explicit.
9. **Policy duplicates.** Repeated policy basenames across scopes require IRI and
   registry-key uniqueness checks.
10. **Legacy terminology and paths.** Root documents still describe semantic
    bundle versioning, current `core` pack terminology, and old repository paths.

Each item should become a separate cleanup or sector-review change. None should be
hidden inside the path-only migration diff.

## Required release-aware tooling

Before publication, root tooling must provide:

1. **Release creation**
   - copy a published release to the next draft;
   - update the manifest and release-qualified URLs safely;
   - refuse to modify published releases.
2. **Reference inventory and validation**
   - parse YAML and JSON;
   - resolve every `$ref` and JSON Pointer locally through the
     `schema.ion.id/releases/releaseN/` mapping;
   - reject cross-release and unapproved external schema dependencies.
3. **Vendoring**
   - fetch from immutable upstream revisions;
   - discover transitive dependencies;
   - preserve provenance, checksums, transformations, and licenses.
4. **Pack consistency**
   - validate required files and unique IDs;
   - compare `attributes.yaml` with `schema.json`;
   - validate JSON-LD documents and examples.
5. **Registry generation**
   - generate policy and error registries for an explicit release root;
   - verify committed generated output is current.
6. **Immutability enforcement**
   - reject modification or deletion of a release whose manifest is published.

## Proposed execution sequence

### Phase 1 — Resolve migration inputs

1. [x] Approve this inventory as the working basis for migration.
2. [x] Remove confirmed generated debris and prevent recurrence.
3. [x] Define and validate the `release.yaml` schema and status vocabulary.
4. [x] Define the public path mapping for every Trade pack and Trade-required
   common pack.
5. [x] Record unresolved names as review gates instead of guessing them.

### Phase 2 — Create the draft skeleton

1. [x] Create `releases/release1/` with `status: draft`.
2. [x] Add `README.md`, `NOTICES.md`, and dependency placeholders.
3. [x] Add tooling that refuses to treat the draft as published.
4. [x] Confirm ordinary validation accepts the draft and the publication gate
   rejects it.

### Phase 3 — Mechanical migration

1. [x] Move files using explicit path mappings.
2. [x] Do not combine sector correctness fixes with the move.
3. [x] Rewrite only paths required for resolvability.
4. [x] Preserve file history where Git can detect the moves.
5. [x] Remove old normative root copies so there is one editable source tree.
6. [x] Validate mapped targets, structured-file parsing, and moved reference
   resolution; record pre-existing content defects for later phases.

### Phase 4 — Vendor and close references

1. [x] Generated a review-only proposal and selected the latest official
   upstream snapshots, pinned at the commits recorded in `release.yaml`.
2. [x] Re-vendored Beckn Protocol and vendored all 17 direct and transitive
   Beckn schema dependencies.
3. [x] Preserved all three upstream license texts and recorded upstream and
   released SHA-256 values.
4. [x] Rewrote active schema references to permanent Release 1 public URLs while
   leaving semantic vocabulary IRIs unchanged.
5. [x] Replaced four pre-existing unresolved internal `ion.yaml` references with
   explicit references to the vendored protocol.
6. [x] Validated the complete graph offline: 86 structured documents and 666
   active references resolved within Release 1.

### Phase 5 — Validate the trusted baseline

1. [x] Validated all nine Trade pack filesets with `schemav2validator`; all
   `attributes.yaml`, `schema.json`, `context.jsonld`, and `vocab.jsonld` files
   pass consistency and reference validation.
2. [x] Validated all four Trade-required common packs after removing stale
   JSON-LD types and synchronizing Payment vocabulary properties.
3. [x] Validated all 17 standalone Trade and common example objects against the
   local Release 1 schemas and corrected stale contexts, types, and shapes.
4. [ ] Reconcile the embedded `ion.yaml` Trade components. The attempted
   structural comparison showed this is not a mechanical sync: TradePerformance
   has 28 standalone-only and 49 aggregate-only property names, TradeResource has
   4 standalone-only and 119 aggregate-only names, and `ion.yaml` has no
   TradeSettlement component. It remains part of the separate `ionApi` review.
5. [x] Reconciled repository-root Trade flows, policies, and errors: repaired 19
   profile file targets, removed non-registry policy placeholders, removed five
   exact duplicate policy files while retaining their canonical Trade copies,
   and aligned `ION-A8001` with `TradeResource.food.classification`.
6. [x] Marked standalone Trade and the four approved common packs `validated`;
   `ionApi` remains `review-required`.

### Phase 6 — Review other sectors independently

Review Logistics, Hospitality, and Finance as separate workstreams. For each area:

1. settle canonical pack names and remove or merge duplicates;
2. correct schema semantics and metadata;
3. validate examples and JSON-LD;
4. reconcile flows, policies, errors, and `ion.yaml` declarations; and
5. mark the area `validated` or `excluded`.

### Phase 7 — Update repository-level material

1. Make root tools release-aware.
2. Update README, CONTRIBUTING, GOVERNANCE, CHANGELOG, LICENSE, style guides, and
   design guides.
3. Retain common root documentation and remove obsolete implementation claims.
4. Add CI for references, generation, content status, and immutability.

### Phase 8 — Publish

Publication is permitted only when:

- every included area is `validated`;
- every unvalidated area is explicitly `excluded` and absent from the normative
  release contract;
- the `ion.yaml` component set, registries, and declared scope agree;
- no schema `$ref` resolves outside Release 1;
- local offline validation passes;
- generated registries are current;
- dependency provenance, checksums, attribution, and licenses are complete;
- all documented public URLs map to committed files on `main`; and
- the ION Council approves the release.

After approval, set `status: published`, record the publication date and checksums,
create the protected `release1` tag, and enable immutable-directory enforcement.

## Inventory completion criteria

This inventory is complete enough to begin migration when:

- every current normative directory has a target classification;
- every current pack is listed as trusted, review-required, or excluded;
- Trade and Trade-required common target names are approved;
- the Release 1 scope decision is recorded;
- the 24 direct Beckn dependency documents have verified upstream sources;
- known duplicates and stray files have assigned cleanup actions; and
- the mechanical move can be reviewed independently of semantic corrections.

This document remains a working inventory until those inputs are approved. It is
not itself evidence that any schema or sector is correct.
