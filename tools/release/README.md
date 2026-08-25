# Release tooling

This directory contains repository-level definitions and validation tooling for
permanent integer releases. It is not copied into individual release bundles.

## Files

- `release-manifest.schema.json` defines the machine-readable `release.yaml`
  contract.
- `release1-path-map.json` records approved mechanical source-to-target paths for
  the primary API files, Trade packs, and the common packs directly referenced by
  Trade.
- `validate_manifest.rb` validates cross-field rules that JSON Schema cannot fully
  express, including agreement between `release`, `name`, and `publicBaseUrl`.
- `validate_path_map.rb` verifies mapping uniqueness, the required pre- or
  post-migration locations, target containment, and exact
  repository-to-public-URL correspondence.
- `plan_vendoring.rb` performs network-based dependency discovery and writes a
  review-only `status: proposed` plan outside the release directory. It does not
  vendor files or rewrite release references.
- `approve_vendoring_plan.rb` records an explicit maintainer decision on a clean,
  checksum-pinned proposal.
- `apply_vendoring_plan.rb` re-fetches and verifies every approved file, previews
  changes by default, and writes only when passed `--apply`.
- `validate_offline_refs.rb` maps Release 1 public URLs back to the release tree
  and verifies that every active `$ref`, including its JSON Pointer, resolves
  without network access.
- `validate_public_urls.rb` checks that every release-qualified public document
  URL in release YAML, JSON, JSON-LD, and Markdown maps to an existing file or
  directory in that release.
- `finalize_vendoring_manifest.rb` records upstream and released checksums only
  after the offline graph passes; it rejects transformed protocol files and
  previews changes unless passed `--apply`.
- `sync_schema_pack_jsonld.rb` synchronizes a pack's local JSON-LD types and
  properties with its authoritative `attributes.yaml`; it is dry-run by default.
- `validate_trade_connections.rb` checks Trade flow targets, concrete policy
  references, policy registry uniqueness, and generated Trade error views.
- `generate_release_registries.rb` deterministically generates or checks the
  release-local policy and Trade error registries.
- `record_artifact_checksums.rb` records or checks the complete artifact
  inventory under the release's normative content trees.
- `validate_release_scope.rb` ensures validated content is present and excluded
  content is absent from a release directory.
- `validate_artifact_checksums.rb` verifies every release artifact against the
  manifest and rejects unrecorded or missing artifacts.
- `validate_release_immutability.rb` rejects changes to any release whose
  manifest is already `published`.
- `validate_release.rb` is the complete local and CI entry point.

## Run the complete Release 1 gate

From the repository root:

```bash
ruby tools/release/validate_release.rb releases/release1
```

This is the same command used by `.github/workflows/release-validation.yml`.
The workflow runs automatically for relevant pull requests and changes on
`main`, and it supports manual `workflow_dispatch` runs.

To include the publication-only manifest requirements:

```bash
ruby tools/release/validate_release.rb --publication releases/release1
```

The publication form is expected to fail while the manifest is a draft.

## Validate a manifest

```bash
ruby tools/release/validate_manifest.rb releases/release1/release.yaml
ruby tools/release/validate_path_map.rb --require-targets tools/release/release1-path-map.json
```

Before applying a migration, use `--require-sources`. After applying it, use
`--require-targets`. Source validation is the default for compatibility with the
Phase 1 workflow.

Commands that publish, deploy, or otherwise treat a release as permanent must use
the publication gate:

```bash
ruby tools/release/validate_manifest.rb --require-published releases/release1/release.yaml
```

This command intentionally fails for a draft release, even when the draft manifest
is otherwise structurally valid.

## Run tests

```bash
ruby tools/release/tests/validate_manifest_test.rb
ruby tools/release/tests/validate_path_map_test.rb
ruby tools/release/tests/plan_vendoring_test.rb
ruby tools/release/tests/apply_vendoring_plan_test.rb
ruby tools/release/tests/finalize_vendoring_manifest_test.rb
ruby tools/release/tests/validate_offline_refs_test.rb
ruby tools/release/tests/validate_public_urls_test.rb
ruby tools/release/tests/validate_artifact_checksums_test.rb
ruby tools/release/tests/validate_release_scope_test.rb
ruby tools/release/tests/validate_release_immutability_test.rb
ruby tools/release/tests/generate_release_registries_test.rb
```

## Propose vendored dependencies

```bash
ruby tools/release/plan_vendoring.rb
```

The default output is `tools/release/release1-vendoring-plan.json`. The command
derives direct versions from existing Release 1 `$ref` values, recursively follows
transitive registry references, compares registry bytes with files at immutable
official GitHub commits, and reports provenance conflicts as blocking issues.

The planner refuses to write its output anywhere under `releases/release1/`.
Reviewing and approving the proposal is required before the apply command will
run.

To propose current upstream branch heads, pinning the commits observed during
planning:

```bash
ruby tools/release/plan_vendoring.rb --protocol-selection latest
```

After explicit maintainer review, record the decision with:

```bash
ruby tools/release/approve_vendoring_plan.rb --decision "Use latest upstream snapshots"
```

Preview the approved migration, then apply the same checksum-gated plan:

```bash
ruby tools/release/apply_vendoring_plan.rb
ruby tools/release/apply_vendoring_plan.rb --apply
```

The apply command rewrites only `$ref` lines. Descriptive and semantic IRIs are
left unchanged. The Phase 4 Release 1 plan also replaced four known unresolved
internal references in the then-candidate `ion.yaml`; that aggregate was later
excluded from Release 1 and returned to the non-normative source area.

Verify the resulting dependency graph offline:

```bash
ruby tools/release/validate_offline_refs.rb releases/release1
```

After that succeeds, preview and record the vendoring result in the manifest:

```bash
ruby tools/release/finalize_vendoring_manifest.rb
ruby tools/release/finalize_vendoring_manifest.rb --apply
```

The canonical Release 1 manifest is `releases/release1/release.yaml`. The YAML
file under `tests/fixtures/` is test data and is not a release manifest.
