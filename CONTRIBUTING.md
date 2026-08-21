# Contributing to the ION Network Specification

Changes in this repository affect schemas, validators, SDKs, network services,
and integrators. Keep pull requests small, explicit about compatibility, and
backed by the relevant validation commands.

## Choose the correct target

- A draft release may be edited inside its `releases/releaseN/` directory.
- A published release is immutable. Make every correction in a new integer
  release; never edit or delete the published directory.
- `schema/`, root `flows/`, `policies/`, and `errors/` currently contain
  unreleased work. Moving any of that material into a release requires an
  explicit scope decision and validation.
- `schema/core/v2/api/v2.0.0/ion.yaml` is a non-normative work-in-progress
  aggregate. Release 1 explicitly excludes it.

## Schema changes

Follow [`docs/ION_Schema_Style_Guide.md`](docs/ION_Schema_Style_Guide.md) and
[`docs/ION_Schema_Design_Guide.md`](docs/ION_Schema_Design_Guide.md).

For every changed pack:

1. keep `attributes.yaml`, `schema.json`, `context.jsonld`, `vocab.jsonld`,
   `profile.json`, examples, renderer metadata, and README content aligned;
2. preserve public schema names, property names, enum values, JSON-LD terms, and
   IRIs unless the change is explicitly breaking;
3. use absolute release-qualified `schema.ion.id` dependency references in
   released `attributes.yaml` and `schema.json` files;
4. keep semantic IRIs stable and separate from document locations;
5. do not edit vendored Beckn files except through the reviewed vendoring
   workflow; and
6. explain any changes to required fields or object openness.

## Flows, policies, and errors

Treat these artifacts as connected to the schemas they reference:

- flow profile targets and schema paths must resolve;
- policy references must be concrete registered IRIs;
- policy IRIs and error codes must be unique and stable; and
- generated registries must agree with their source files.

Run the relevant generators when changing registry sources:

```bash
python3 policies/generate_registry.py
python3 errors/generate_registry.py
```

Review generated diffs and include them in the same pull request.

## Validation

Run the complete local gate before opening a pull request:

```bash
ruby tools/release/validate_release.rb releases/release1
```

The command is the same entry point used by GitHub Actions. For a publication
change, also run:

```bash
ruby tools/release/validate_release.rb --publication releases/release1
```

Schema pack changes should additionally be checked with the ION testbed
validator:

```bash
cd /path/to/ion-testbed/tools/schemav2validator
go run ./cmd/schemav2validator schema-dir /path/to/ion-specs/releases/release1/schema/extension/trade/
```

The external validator is not bundled into this repository, so record the exact
command and result in the pull request.

## Pull requests

Include:

- the affected release and content area;
- whether the change is compatible, additive, or breaking;
- schema, flow, policy, error, documentation, and tooling impacts;
- commands actually run and their results; and
- any intentionally deferred work.

Changes to release scope, publication status, vendored dependencies, semantic
IRIs, required fields, or public schema names require ION Council review.
