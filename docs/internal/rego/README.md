# Release 2 Rego work records

**Status:** Active implementation record

**Decision date:** 2026-11-25

**Target:** `releases/release2/`

This directory records the decisions and execution plan for adding ION-authored
Rego business rules to Release 2 and distributing them for enforcement by the
ONIX OPA Policy Checker plugin.

These documents are internal work records. They govern the implementation work
until their durable decisions are incorporated into the repository's public
architecture, contributor, release, and integration documentation. They do not
by themselves make a rule normative or publish Release 2.

## Documents

- [`ION_Rego_Architecture.md`](ION_Rego_Architecture.md) — ownership,
  release placement, runtime composition, compatibility, packaging, signing,
  and publication decisions.
- [`ION_Rego_Authoring_Guide.md`](ION_Rego_Authoring_Guide.md) — source layout,
  packages, rule structure, identifiers, violation results, metadata, data,
  tests, and review requirements.
- [`ION_Rego_Tooling_Design.md`](ION_Rego_Tooling_Design.md) — build inputs and
  outputs, deterministic checks, release-gate integration, bundle and manifest
  validation, and ONIX end-to-end testing.
- [`ION_Rego_Implementation_Plan.md`](ION_Rego_Implementation_Plan.md) — phased
  delivery plan, acceptance gates, validation sequence, and decisions that must
  be closed before production publication.

## Governing inputs

The work is governed by:

- `docs/ION_Release_Architecture.md`;
- `docs/ION_Release_Channel_Policy.md`;
- `docs/ION_Schema_Style_Guide.md`;
- `docs/ION_Schema_Design_Guide.md`;
- `releases/release2/release.yaml`;
- `releases/release2/README.md`; and
- the ONIX OPA Policy Checker documentation at
  `/Volumes/work/work/beckn/repos/beckn-onix/pkg/plugin/implementation/opapolicychecker/README.md`.

## Relationship to the older conditional-policy proposal

`docs/ION_ONIX_Conditional_Policy.md` predates the current ONIX OPA Policy
Checker contract. Its rule examples and three-case testing principle remain
useful review inputs, but its proposed root `policies/onix-conditional/` layout,
pack-fragment input model, `deny` query shape, loading behavior, and error format
are superseded for Release 2 by these records.

The older document must not be used as the implementation contract without a
rule-by-rule review against current Release 2 schemas and complete Beckn message
envelopes.
