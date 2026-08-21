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
- `finalize_vendoring_manifest.rb` records upstream and released checksums only
  after the offline graph passes; it previews changes unless passed `--apply`.
- `sync_schema_pack_jsonld.rb` synchronizes a pack's local JSON-LD types and
  properties with its authoritative `attributes.yaml`; it is dry-run by default.
- `validate_trade_connections.rb` checks Trade flow targets, concrete policy
  references, policy registry uniqueness, and generated Trade error views.

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
ruby tools/release/tests/validate_offline_refs_test.rb
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
left unchanged. It also replaces the four known unresolved internal references
in `ion.yaml` with explicit references to the vendored protocol document.

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
