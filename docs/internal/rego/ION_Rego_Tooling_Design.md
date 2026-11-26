# ION Release 2 Rego Tooling Design

**Status:** Accepted working design

**Design date:** 2026-11-25

**Target:** `tools/rego/`, `tools/release/`, and `releases/release2/rules/`

## Purpose

This document defines the tooling required to make Rego sources, generated
registries, bundles, signatures, release checksums, direct ONIX configuration,
and ONIX behavior verifiable as one connected release feature.

The tooling must make the safe path the easy path: contributors edit source and
tests; generators create derived artifacts; validators detect drift; and the
complete Release 2 gate proves both repository consistency and runtime behavior.

## Tooling boundaries

Repository tooling remains at the root and evolves independently of immutable
releases:

```text
tools/rego/
  README.md
  <build, generate, validate, and test entry points>
  tests/
  testdata/
```

Release-owned inputs and outputs remain under `releases/release2/rules/`.
Private keys, downloaded OPA binaries, ONIX binaries, caches, and temporary
staging directories are never release artifacts.

Tools accept an explicit release root. They must not hard-code Release 2 except
where a test fixture deliberately exercises Release 2 behavior.

## External toolchain

The implementation uses the OPA CLI for formatting, strict compilation, unit
tests, evaluation, bundle construction, inspection, and signature operations.
The supported OPA version or version range must be pinned and reported by the
tooling. A missing or incompatible CLI produces an actionable error.

ONIX integration uses the current `opapolicychecker` implementation. The test
must pin or record the ONIX revision so a change in a sibling checkout cannot
silently redefine the release gate.

The initial tooling may be Ruby for integration with the existing release gate,
with shell-free process invocation through argument arrays. A focused Go or
TypeScript helper is acceptable if it materially improves OPA bundle or ONIX
integration. Regardless of language, broad rewrites require report-only or
dry-run behavior by default.

## Source validation

The source validator performs these checks:

1. every production and test module is formatted;
2. every module uses Rego v1 syntax;
3. package declarations match their directory classification;
4. only the top-level router owns `ion.release2.result`;
5. production modules compile together in strict mode;
6. tests compile with production modules;
7. no test module is admitted to the runtime source inventory;
8. rule IDs are present, syntactically valid, and unique;
9. required metadata is present and well typed;
10. referenced schema, flow, error, and policy paths resolve;
11. declared `POL_*` codes exist in the Release 2 protocol taxonomy;
12. declared `data.config` keys are documented; and
13. prohibited files, secrets, and private-key material are absent.

Validation is read-only. A separate formatting command may write after an
explicit `--write` or equivalent option.

## Test execution

The Rego test runner executes all source and tests as one logical policy tree.
It must support:

- verbose failure output;
- machine-readable results for CI;
- an enforceable coverage threshold once the initial scaffold exists;
- targeted test selection for local development; and
- full-bundle tests in the release gate.

Coverage is evidence, not a substitute for the required semantic cases in the
authoring guide. The validator should detect a rule ID with no corresponding
test reference even if line coverage happens to be high.

Representative fixtures are validated against Release 2 schemas before Rego
evaluation. This preserves the intended pipeline and prevents malformed JSON
from being used to prove a business rule.

## Generated rule registry

This contract is implemented by `tools/rego/generate_registry.rb`. The
metadata and output shapes are recorded in JSON Schema, while the validator
also resolves repository-specific relationships that JSON Schema cannot prove.

A generator reads OPA metadata and produces:

```text
releases/release2/rules/registry.json
```

The registry records, at minimum:

- registry schema version;
- release number;
- public query path;
- rule ID, title, description, sector, and actions;
- package and source module;
- Beckn policy error code;
- referenced schema, flow, error, and shared-policy artifacts;
- runtime data or config dependencies; and
- status such as active or withdrawn.

Generation is deterministic. The normal validation command compares generated
bytes with the committed file and fails with an instruction to run the write
form. The registry never becomes an independent editable rule source.

## Bundle construction

This boundary is implemented by `build_bundle.rb`, `verify_bundle.rb`,
and a shared archive model. Construction creates an ephemeral ES256 key,
commits the canonical public key beside its matching bundle, and destroys the
private key with its temporary directory. Because ECDSA signatures are intentionally
non-deterministic, freshness verifies exact logical module/data bytes and OPA's
signed inventory rather than comparing a rebuilt archive byte-for-byte.

The bundle builder creates a temporary staging tree from an allowlist:

- production `.rego` modules;
- normative `data.json`; and
- required OPA bundle metadata.

It refuses test modules, fixtures, Markdown, unexpected executables, symlinks,
private keys, and unrecognized files. It then builds:

```text
releases/release2/rules/bundles/ion-release2-policy.tar.gz
```

The build command must be documented and non-destructive. Temporary output uses
a dedicated temporary directory. An interrupted build must not replace the
last reviewed bundle.

The builder or a companion verifier checks:

- archive paths are safe and normalized;
- only allowlisted entries exist;
- the bundle contains production modules and runtime data expected from source;
- no source module is missing or duplicated;
- the top-level query compiles from the archive;
- bundle size is at most 10 MB;
- the embedded OPA manifest is valid;
- the embedded signature is present for a production candidate;
- the signature key ID is `default`; and
- verification succeeds with the expected public key and algorithm.

If OPA's archive encoding is not byte-for-byte reproducible, validation compares
the canonical inventory and hashes of logical bundle contents in addition to
the committed archive checksum. Publication still records the exact distributed
archive bytes.

## Signing model

Release 2 uses one deliberately simple signing model in all environments:

| Mode | Key handling | Published artifacts |
|---|---|---|
| Local development | Generate an ephemeral ES256 key pair for the build | Preview only unless `--write` is used |
| CI and integration | Verify the committed matching pair | Bundle and PEM public key from the release tree |
| Publication | Generate an ephemeral ES256 key pair in the publication build | Bundle and PEM public key through `schema.ion.id` |

The private key exists only in the temporary build directory, is used by OPA to
sign one bundle, and is destroyed. The builder atomically replaces each of the
signed bundle and `ion-releaseN-policy-public.pem` files after verification; it
never writes the private key. The two files must be committed and deployed as
one reviewed change.
Both public artifacts are hosted by the same GitHub-backed origin. This loses
the independent trust channel a DeDi key record would provide, but has been
accepted for operational simplicity. The optional external-key interface is
retained for a future signing-model change, not used by the current Release 2
publication path.

## Direct bundle configuration validation

The operator-configuration validator enforces the direct ONIX contract:

- the network-policy entry uses `type: bundle`;
- the configuration key is the explicitly selected ION `networkId`;
- bundle URL is the release-qualified `schema.ion.id` URL;
- query is exactly the selected release's public query;
- signature verification is enabled with the selected release's algorithm;
- the public-key URL is the release-qualified `schema.ion.id` PEM artifact; and
- bundle URL, query, and verification key belong to the same integer release.

Draft development uses a checked configuration fixture and local HTTP test
server. Production configuration values are not generated with invented
network identities. A network-policy manifest is deliberately not
generated because current ONIX manifest selection cannot represent concurrent
Release 2 and Release 3 adoption under one `networkId`.

## ONIX integration testing

Repository-only OPA evaluation is necessary but insufficient. The integration
suite must exercise the actual ONIX plugin contract in increasing depth:

1. load a local directory during development;
2. load the built bundle with `type: bundle`;
3. verify its embedded signature;
4. evaluate valid and invalid full message bodies;
5. verify structured `POL_*` violations;
6. verify undefined or incorrect query paths fail closed;
7. serve the bundle and public-key response from a local HTTP server;
8. load them through remote `type: bundle` configuration; and
9. confirm refresh failure retains the previously compiled evaluator.

The test matrix includes common, Trade, Logistics, unrelated actions, missing
optional shapes, multiple violations, invalid configuration, and an oversized
or tampered bundle.

The implemented harness accepts an explicit pinned ONIX checkout and the manual
optional workflow checks out that revision itself. ONIX compilation remains
outside the ordinary release-validation job; authors and publication reviewers
run it when rules, bundles, the ONIX pin, or distribution behavior changes.

## Release-tool integration

Release manifest schema v2 adds `rules` to `contentStatus`. Release tooling
dispatches by manifest schema version:

| Manifest | Published checksum roots |
|---|---|
| v1 | `schema`, `flows`, `errors` |
| v2 | `schema`, `flows`, `errors`, `rules` |

The complete release validator adds ordered gates:

1. Rego source and metadata validation;
2. rule registry freshness;
3. OPA unit and integration tests;
4. bundle source correspondence and archive validation;
5. signature validation when required by release state;
6. direct operator-configuration validation when present or required;
7. existing checksum, URL, reference, flow, and error checks.

The ONIX bundle smoke test is a separate optional author and pre-publication
command. It is not invoked by the ordinary release validator.

Draft checksums retain the release-manifest model for mutable ION-authored
files. Freshness validators protect draft generated outputs. At publication,
every file under `rules/` is included in the artifact checksum inventory unless
an explicit non-normative exclusion is defined and documented.

The deployed-URL validator checks `.rego`, `.json`, `.yaml`, `.pem`, and
`.tar.gz` artifacts, including byte checksums and appropriate content types. It
must not decompress and silently accept a deployed archive whose bytes differ
from the released artifact.

## CI behavior

The supported CLI is pinned in `tools/rego/opa-version` and must exactly match
the OPA library version used by ONIX. The current pin is `1.15.2`. CI installs that
source version with Go into a job-local directory; no platform-specific OPA
binary is committed. The read-only checker rejects a missing executable or any
version mismatch before evaluation begins.

Changes under any of these paths trigger the complete applicable gate:

```text
releases/**/rules/**
releases/**/schema/**
releases/**/flows/**
releases/**/errors/**
tools/rego/**
tools/release/**
docs/rego/**
docs/internal/rego/**
```

Schema, flow, and error changes can invalidate Rego assumptions even when no
Rego file changes. CI therefore cannot scope policy testing only to `rules/**`.

Fast local commands run narrow checks first; the root Release 2 validation
command remains the CI and completion authority:

```bash
ruby tools/release/validate_release.rb releases/release2
```

## Diagnostics

Every tool reports:

- the failing artifact or rule ID;
- the expected condition;
- the observed value or state when safe;
- the command that refreshes a generated artifact, where applicable; and
- a non-zero exit code on failure.

Tools must not expose private keys, full sensitive message fixtures, or registry
credentials in CI logs.

## Documentation requirements

`tools/rego/README.md` documents prerequisites, pinned versions, commands,
inputs, outputs, write modes, exit codes, signing modes, limitations, and an
end-to-end local example. Release 2's README documents only the implementer-facing
entry points and production URLs; it does not duplicate maintainer mechanics.
