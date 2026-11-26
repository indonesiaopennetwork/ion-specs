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

## Run the optional ONIX integration

The direct ONIX integration is deliberately separate from
`tools/release/validate_release.rb` and the normal release-validation workflow.
It is intended for Rego changes, bundle/tooling changes, ONIX compatibility
checks, and pre-publication evidence; schema-only changes do not need to pay its
dependency or runtime cost.

Prerequisites are Git, Ruby, Go `1.26.1`, and a checkout of `beckn-onix` at the
revision recorded in [`onix-revision`](onix-revision). Docker, an OPA CLI, open
ports, and a running ONIX deployment are not required. The first Go run may need
network access to download ONIX module dependencies.

```bash
git clone https://github.com/beckn/beckn-onix.git /tmp/beckn-onix
git -C /tmp/beckn-onix checkout bbfb517114e1cefc63b72423d8dfdc4ad13c0191
ruby tools/rego/test_onix_integration.rb --onix-root /tmp/beckn-onix
```

Alternatively, set `ONIX_ROOT` instead of passing `--onix-root`. The command
fails when the checkout is not at the exact pinned revision. It uses a Go
overlay, so it does not copy files into or modify the ONIX checkout.

The test exercises the actual ONIX `opapolicychecker` package and verifies:

- signed bundle loading with the committed release public key;
- valid, invalid, unrelated-action, exact-network, and no-match inputs;
- exact structured rule codes and messages;
- multiple simultaneous violations;
- fail-closed behavior for an incorrect query; and
- startup rejection for a wrong key or tampered bundle.

It asserts ONIX's HTTP-400 plugin error contract without starting a full adapter.
Schema-before-policy ordering is deployment configuration and is documented in
the operator guide at `docs/rego/ONIX_Rego_Integration.md`.

Maintainers can also run the GitHub Actions workflow **Optional Rego ONIX
integration** manually with `workflow_dispatch`. It has no pull-request or push
trigger and is not a prerequisite for ordinary specification validation.

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

Preview construction with a generated ephemeral key pair:

```bash
ruby tools/rego/build_bundle.rb --ephemeral-sign releases/release2
```

Refresh the canonical bundle and public key, replacing each artifact atomically
after verification:

```bash
ruby tools/rego/build_bundle.rb --write --ephemeral-sign releases/release2
```

The private key exists only in a temporary directory during that command. It is
never copied into the repository. The committed public key is
`ion-release2-policy-public.pem`; it cannot create signatures. The signed bundle
and public key are the canonical pair for local tests, CI, ONIX integration,
and Release 2 publication. A rebuild rotates both artifacts together.

Verify freshness, archive safety, the 10 MiB ONIX limit, the logical source
inventory, ES256 signature with key ID `default`, and the public query:

```bash
ruby tools/rego/verify_bundle.rb releases/release2
```

OPA's ES256 signature is non-deterministic. Consequently, freshness compares
the committed archive's logical module and data bytes with source and verifies
its signed inventory; it does not require a rebuilt gzip archive to have the
same bytes.

### Optional external-key interface

The selected Release 2 publication model uses `--ephemeral-sign`. The builder
also retains an external-key interface so a future architecture decision can
supply both key paths from controlled storage:

```bash
ruby tools/rego/build_bundle.rb --write \
  --signing-key /controlled/path/ion-production-private.pem \
  --verification-key /controlled/path/ion-production-public.pem \
  releases/release2
```

The tool reads these paths only for OPA signing and immediate verification. It
does not print or copy either external key. This interface is not the current
Release 2 publication path and does not imply a DeDi key record.

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

- The registry contains only the three starter rules; comprehensive Trade and
  Logistics coverage is not yet implemented.
- The bundle and public key share one GitHub-backed publication origin; this is
  operationally simple but is not an independent trust channel.
- Direct ONIX plugin integration is optional and proven at the pinned revision;
  deployed `schema.ion.id` retrieval and full deployment testing belong to the
  Release 2 publication exercise because those public rule URLs do not yet
  exist.
