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

## Validate the Phase 2 scaffold

```bash
ruby tools/rego/validate_scaffold.rb releases/release2
```

With an explicit binary:

```bash
ruby tools/rego/validate_scaffold.rb \
  --opa /absolute/path/to/opa \
  releases/release2
```

This read-only command:

1. checks the OPA version;
2. checks that all current modules and tests are formatted;
3. strictly compiles production modules;
4. runs the Rego unit tests with `--fail-on-empty`; and
5. evaluates `data.ion.release2.result` against every JSON smoke fixture and
   requires the exact scaffold result.

The command does not build a bundle, generate a registry, or modify source.
Those behaviors are introduced with freshness tests in later phases.

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
ruby tools/rego/tests/check_toolchain_test.rb
ruby tools/rego/tests/generate_test_key_test.rb
```

## Current limitations

- Only the rule-free Phase 2 scaffold is validated.
- Metadata and generated registry validation begin in Phase 3.
- Bundle construction and signature verification begin in Phase 4.
- ONIX integration begins in Phase 6.
