# Rego tooling

This directory contains repository-level tooling for authoring and validating
release-owned ION Rego rules. It is not copied into an integer release.

## Pinned OPA version

[`opa-version`](opa-version) pins OPA CLI `1.15.2`. This exactly matches the OPA
Go SDK version used by the current ONIX `opapolicychecker`, preventing local and
runtime Rego behavior from drifting independently.

The pin is exact rather than a range. Updating it requires checking the ONIX
runtime dependency, formatting output, strict compilation, unit tests, bundle
behavior, and signature verification together.

OPA `1.15.2` requires Go 1.25 or newer when built from source.

## CI acquisition

CI does not commit or cache a platform-specific OPA binary in the repository.
The release-validation workflow uses `actions/setup-go`, then installs the exact
pin through the checksum-verified Go module path:

```bash
go install github.com/open-policy-agent/opa@v1.15.2
```

The toolchain checker rejects any other OPA version. Later phases may replace
the acquisition mechanism with checksum-pinned official binaries, but must not
relax the exact version check.

## Check the toolchain

```bash
ruby tools/rego/check_toolchain.rb
```

If OPA is not on `PATH`:

```bash
ruby tools/rego/check_toolchain.rb --opa /absolute/path/to/opa
```

The command is read-only and returns non-zero when OPA is missing, cannot run,
or does not match the pin.

## Validate sources and metadata

```bash
ruby tools/rego/validate_sources.rb releases/release2
```

This checks package-to-path conventions, the reserved public result, Rego v1
imports, rule metadata, IDs, sectors, protocol actions and `POL_*` codes,
release-local paths, shared policy IRIs, configuration declarations, semantic
test references, formatting, and strict compilation. The metadata and registry
contracts are defined by `rule-metadata.schema.json` and
`rule-registry.schema.json`.

## Generate the rule registry

Check freshness without writing:

```bash
ruby tools/rego/generate_registry.rb releases/release2
```

Refresh after adding or changing rule metadata:

```bash
ruby tools/rego/generate_registry.rb --write releases/release2
```

The output is `releases/release2/rules/registry.json`. Generation is sorted and
deterministic; validation fails with the refresh command when the committed
file is missing or stale.

## Run rule tests and smoke evaluation

```bash
ruby tools/rego/validate_scaffold.rb releases/release2
```

With an explicit binary:

```bash
ruby tools/rego/validate_scaffold.rb \
  --opa /absolute/path/to/opa \
  releases/release2
```

The scaffold command is read-only and:

1. checks the OPA version;
2. checks that all current modules and tests are formatted;
3. strictly compiles production modules;
4. runs the Rego unit tests with `--fail-on-empty`; and
5. evaluates `data.ion.release2.result` against every JSON smoke fixture and
   requires the exact scaffold result.

The command does not build a bundle or modify source.

## Build and verify the signed bundle

Preview construction with a generated ephemeral test key:

```bash
ruby tools/rego/build_bundle.rb --test-sign releases/release2
```

Refresh the canonical draft bundle and its public test key, replacing each
artifact atomically after verification:

```bash
ruby tools/rego/build_bundle.rb --write --test-sign releases/release2
```

The private key exists only in a temporary directory during that command. It is
never copied into the repository. The committed public key is unmistakably
named `TEST-ONLY-ion-release2-policy-public.pem` and cannot create signatures.

Verify freshness, archive safety, the 10 MiB ONIX limit, the logical source
inventory, ES256 signature with key ID `default`, and the public query:

```bash
ruby tools/rego/verify_bundle.rb releases/release2
```

OPA's ES256 signature is non-deterministic. Consequently, freshness compares
the committed archive's logical module and data bytes with source and verifies
its signed inventory; it does not require a rebuilt gzip archive to have the
same bytes.

### Controlled production-signing interface

Publication automation supplies both key paths from controlled storage:

```bash
ruby tools/rego/build_bundle.rb --write \
  --signing-key /controlled/path/ion-production-private.pem \
  --verification-key /controlled/path/ion-production-public.pem \
  releases/release2
```

The tool reads these paths only for OPA signing and immediate verification. It
does not print or copy either external key. Production custody, DeDi public-key
publication, authorization, audit evidence, and invocation environment remain
operations responsibilities and are intentionally not invented in this repo.
The ordinary draft gate continues to require the committed test public key
until the later publication phase deliberately switches verification mode.

## Generate an ephemeral test-only signing key

Preview:

```bash
ruby tools/rego/generate_test_key.rb /tmp/ion-rego-test-keys
```

Generate:

```bash
ruby tools/rego/generate_test_key.rb --write /tmp/ion-rego-test-keys
```

The generator creates an ECDSA P-256 keypair for future local signature tests.
Both filenames begin with `TEST-ONLY`. It refuses to write anywhere below
`releases/`, refuses to overwrite keys, and never produces a production key.
Keep generated key material outside the repository.

## Tests

```bash
ION_OPA=/absolute/path/to/opa ruby -Itools/rego/tests -e \
  'Dir["tools/rego/tests/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

## Current limitations

- The registry is empty because the scaffold has no substantive business rule.
- The canonical draft bundle is test-signed, not production-signed.
- ONIX integration begins in Phase 6.
