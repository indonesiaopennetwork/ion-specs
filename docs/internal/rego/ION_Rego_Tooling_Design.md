# ION Release 2 Rego Tooling Design

**Status:** Accepted working design

**Design date:** 2026-11-25

**Target:** `tools/rego/`, `tools/release/`, and `releases/release2/rules/`

## Purpose

This document defines the tooling required to make Rego sources, generated
registries, bundles, signatures, network manifests, release checksums, and ONIX
behavior verifiable as one connected release feature.

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

Phase 3 implements this contract with `tools/rego/generate_registry.rb`. The
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

Phase 4 implements this boundary with `build_bundle.rb`, `verify_bundle.rb`,
and a shared archive model. Draft construction creates an ephemeral ES256 key,
commits only the unmistakably named public test key, and destroys the private
key with its temporary directory. Because ECDSA signatures are intentionally
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

Three modes are distinct:

| Mode | Key | Purpose |
|---|---|---|
| Local development | Ephemeral or checked-in test-only key | Exercise bundle verification locally |
| CI | Dedicated non-production test key | Prove the signing and ONIX verification path |
| Publication | ION production key outside the repository | Produce the normative bundle and manifest signatures |

The production signing command receives the key through a controlled path or
signing service. It must never print private material or copy it into staging.
The public-key lookup response used for final verification is retained as
publication evidence where governance permits, but not treated as the canonical
DeDi service itself.

## Network manifest validation

The network-manifest validator enforces the ONIX contract:

- `manifestVersion` and `manifestType` are supported;
- `networkId` matches the configured ION network exactly;
- `releaseId` identifies the Release 2 policy publication;
- publisher fields are non-empty and approved;
- `policies.type` is `rego` and source is `bundle`;
- bundle URL is the release-qualified `schema.ion.id` URL;
- query is exactly `data.ion.release2.result`;
- the bundle is declared signed;
- verification lookup URL is present;
- governance timestamps are valid; and
- the detached manifest signature verifies through the manifest-loader path.

Draft development uses a fixture manifest and local HTTP test server. The
production manifest is not generated with invented governance or identity
values.

## ONIX integration testing

Repository-only OPA evaluation is necessary but insufficient. The integration
suite must exercise the actual ONIX plugin contract in increasing depth:

1. load a local directory during development;
2. load the built bundle with `type: bundle`;
3. verify its embedded signature;
4. evaluate valid and invalid full message bodies;
5. verify structured `POL_*` violations;
6. verify undefined or incorrect query paths fail closed;
7. serve bundle and manifest from a local HTTP server;
8. resolve the bundle through a signed manifest and manifest loader; and
9. confirm refresh failure retains the previously compiled evaluator.

The test matrix includes common, Trade, Logistics, unrelated actions, missing
optional shapes, multiple violations, invalid configuration, and an oversized
or tampered bundle.

The initial implementation may invoke tests in the ONIX sibling checkout. The
long-term gate must define how CI obtains the pinned ONIX code without depending
on an unrecorded developer filesystem path.

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
6. network manifest validation when present or required;
7. ONIX bundle smoke test; and
8. existing checksum, URL, reference, flow, and error checks.

Draft checksums retain the existing model for mutable ION-authored files unless
the manifest decision is amended separately. Freshness validators protect draft
generated outputs. At publication, every file under `rules/` is included in the
artifact checksum inventory unless an explicit non-normative exclusion is
defined and documented.

The deployed-URL validator checks `.rego`, `.json`, `.yaml`, `.sig`, and
`.tar.gz` artifacts, including byte checksums and appropriate content types. It
must not decompress and silently accept a deployed archive whose bytes differ
from the released artifact.

## CI behavior

The supported CLI is pinned in `tools/rego/opa-version` and must exactly match
the OPA library version used by ONIX. Phase 2 pins `1.15.2`. CI installs that
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

Tools must not expose private keys, full sensitive message fixtures, or DeDi
credentials in CI logs.

## Documentation requirements

`tools/rego/README.md` documents prerequisites, pinned versions, commands,
inputs, outputs, write modes, exit codes, signing modes, limitations, and an
end-to-end local example. Release 2's README documents only the implementer-facing
entry points and production URLs; it does not duplicate maintainer mechanics.
