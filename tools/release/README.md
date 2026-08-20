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
- `validate_path_map.rb` verifies mapping uniqueness, source existence, target
  containment, and exact repository-to-public-URL correspondence.

## Validate a manifest

```bash
ruby tools/release/validate_manifest.rb releases/release1/release.yaml
ruby tools/release/validate_path_map.rb tools/release/release1-path-map.json
```

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
```

The Release 1 manifest is created in Phase 2. The YAML file under
`tests/fixtures/` is test data and is not a release manifest.
