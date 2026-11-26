# ION Release 2 Rego Implementation Plan

**Status:** Approved working plan

**Plan date:** 2026-11-25

**Target:** `releases/release2/`

**Objective:** Author, validate, package, sign, publish, and exercise ION Rego
business rules through ONIX as a first-class Release 2 capability.

## Purpose

This plan turns the Rego architecture, authoring guide, and tooling design into
small, reviewable implementation phases. Each phase has an explicit exit gate.
Work proceeds in order unless a later phase is clearly independent and does not
weaken an earlier gate.

The implementation must keep the Release 2 draft valid after every phase. New
normative rules are not added ahead of the instrumentation intended to protect
them.

## Governing documents

- `docs/internal/rego/ION_Rego_Architecture.md`
- `docs/internal/rego/ION_Rego_Authoring_Guide.md`
- `docs/internal/rego/ION_Rego_Tooling_Design.md`
- `docs/ION_Release_Architecture.md`
- `docs/ION_Release_Channel_Policy.md`
- `docs/ION_Schema_Style_Guide.md`
- `docs/ION_Schema_Design_Guide.md`
- current ONIX `opapolicychecker` documentation and implementation

## Delivery rules

- Start each phase by re-reading the current release manifest and affected
  implementation, not only this plan.
- Run the narrowest tests during development and the complete Release 2 gate
  before completing a phase.
- Add or update tests in the same change as validation behavior.
- Do not mark `contentStatus.rules` validated until every required gate is live.
- Do not use production keys during ordinary development or CI.
- Do not remove a schema constraint without a separately reviewed compatibility
  decision and equivalence evidence.
- Do not copy candidate rules from the older conditional-policy document without
  checking current Release 2 names and message paths.
- Record unexpected design changes in these work records before implementing
  behavior that depends on them.

## Phase 0 — Establish the decision record

**Status:** Complete — 2026-11-25

### Deliverables

- Create `docs/internal/rego/`.
- Record release placement, ownership, packaging, signing, and publication
  decisions.
- Record authoring conventions and validation expectations.
- Record the tooling architecture and this implementation sequence.
- Classify the relationship with `docs/ION_ONIX_Conditional_Policy.md`.

### Exit gate

- Documents are internally consistent and link from `docs/internal/README.md`.
- No normative release artifact has changed.

### Suggested commit

```text
docs(rego): record Release 2 policy architecture and plan
```

## Phase 1 — Amend the release architecture and manifest contract

**Status:** Complete — 2026-11-26

### Goal

Make `rules/` a supported release-owned area without changing published Release
1 or prematurely adding production rules.

### Deliverables

1. Amend `docs/ION_Release_Architecture.md` to define `rules/` as the fourth
   release-owned normative area.
2. Amend the Release 2 and root README layouts and terminology.
3. Introduce release manifest schema version 2.
4. Add `contentStatus.rules` to manifest v2 with the existing content-state
   model.
5. Upgrade only Release 2 to manifest schema v2 and initialize rules as
   `review-required` or `validation-pending`, according to the implemented gate.
6. Make manifest validators support both:
   - v1: existing Release 1 contract;
   - v2: Release 2 contract with `rules`.
7. Extend release-scope and artifact-root logic for v2.
8. Add focused manifest, checksum-root, scope, creation, and immutability tests.

### Compatibility checks

- Release 1 manifest remains byte-for-byte unchanged.
- Release 1 validation still passes.
- Creating a future release from v2 preserves the v2 rules area correctly.
- A v2 published manifest cannot omit or leave `rules` unresolved.

### Exit gate

```bash
ruby tools/release/validate_release.rb releases/release1
ruby tools/release/validate_release.rb releases/release2
```

Both pass in their appropriate lifecycle states. The Release 2 publication form
continues to fail only for expected draft/publication reasons.

### Completion evidence

- Release 1 remains on manifest schema v1 and its manifest is unchanged.
- Release 2 uses manifest schema v2 with `rules: review-required` and no runtime
  rules directory yet.
- Manifest, scope, checksum-root, release-creation, and immutability tests cover
  both manifest versions.
- The complete Release 1 and Release 2 gates pass with 122 tool tests and 403
  assertions.
- The Release 2 publication form fails only because the draft is unpublished
  and unassigned to a channel, as expected.

### Suggested commit

```text
feat(release): add versioned rules area to release manifests
```

## Phase 2 — Add the source scaffold and pin the toolchain

**Status:** Not started

### Goal

Create the empty Rego feature envelope and a repeatable toolchain without yet
asserting substantive ION business rules.

### Deliverables

1. Create `releases/release2/rules/README.md`.
2. Create the agreed production, test, fixture, data, registry, and bundle
   directories.
3. Add the minimal top-level router returning a defined valid result with no
   violations.
4. Add a smoke test proving the public query is always defined.
5. Pin the supported OPA CLI version or version range.
6. Add `tools/rego/README.md` and a read-only environment/toolchain checker.
7. Decide and document how CI obtains OPA without committing a platform binary.
8. Add ignore rules for temporary bundles, caches, downloaded tools, and key
   material while retaining the canonical committed release bundle path.
9. Add test-only signing material or generation logic with unmistakable
   non-production labeling.

### Exit gate

- The minimal policy formats, compiles, tests, and evaluates through OPA.
- The public query returns `{valid: true, violations: []}` for representative
  structurally valid Trade and Logistics messages.
- Missing or incompatible OPA produces an actionable failure.
- No test key can be confused with or used as the ION production key.
- The complete Release 2 gate passes.

### Suggested commit

```text
chore(rego): scaffold Release 2 policy sources and toolchain
```

## Phase 3 — Implement source, metadata, and registry validation

**Status:** Not started

### Goal

Protect authoring conventions before real rule volume grows.

### Deliverables

1. Implement formatting and strict compilation checks.
2. Validate package-to-path conventions and reserve the public result package.
3. Define the rule metadata schema.
4. Validate rule ID syntax and uniqueness.
5. Validate sectors, actions, source paths, policy IRIs, and config-key
   declarations.
6. Resolve declared `POL_*` codes against the Release 2 protocol taxonomy.
7. Generate `rules/registry.json` deterministically from metadata.
8. Add a freshness check and explicit write command.
9. Detect rule IDs without corresponding semantic tests.
10. Add tool unit tests for valid cases, malformed metadata, duplicate IDs,
    unresolved references, stale output, and unsafe paths.
11. Wire the checks into `validate_release.rb` when a v2 rules area exists.

### Exit gate

- A deliberately malformed module fails with a precise diagnostic.
- Registry generation is byte-stable across repeated runs.
- Validation fails when the committed registry is stale.
- Release 1 validation does not invoke a nonexistent Rego area.
- Release 2 validation passes with the scaffold registry.

### Suggested commit

```text
feat(rego): validate rule metadata and generate registry
```

## Phase 4 — Implement bundle construction and verification

**Status:** Not started

### Goal

Produce a reviewable runtime artifact that corresponds exactly to approved
sources and is accepted by OPA.

### Deliverables

1. Implement allowlisted staging of production modules and runtime data.
2. Exclude tests, fixtures, docs, caches, and secrets.
3. Build `ion-release2-policy.tar.gz`.
4. Inspect safe archive paths, contents, OPA manifest, query, and size.
5. Compare logical bundle contents with source hashes.
6. Support test-key signing using ES256 and key ID `default`.
7. Verify the embedded signature through OPA.
8. Add tampering, wrong-key, missing-module, duplicate-module, unsafe-path,
   unexpected-file, and oversize tests.
9. Add a freshness validator for the committed bundle.
10. Document the controlled production-signing interface without storing a
    production key.

### Exit gate

- A clean source tree produces a bundle that passes all inventory and signature
  checks.
- A one-byte module or data change makes bundle freshness fail.
- Test modules and private-key patterns cannot enter the bundle.
- Tampered bundles fail verification.
- The Release 2 gate validates the committed test-signed draft bundle.

### Suggested commit

```text
feat(rego): build and verify the Release 2 OPA bundle
```

## Phase 5 — Add a minimal rule vertical slice

**Status:** Not started

### Goal

Prove authoring, metadata, registry, tests, packaging, and diagnostics using a
small number of unambiguous rules before broad Trade or Logistics work.

### Candidate selection criteria

Choose two or three rules that:

- are already supported by clear Release 2 schemas or flows;
- use fields present in complete message fixtures;
- have no unresolved regulatory interpretation;
- exercise at least one cross-field or action-dependent condition;
- have an existing suitable `POL_*` error code; and
- do not require removing a JSON Schema constraint.

At least one rule should test an inapplicable action and at least one should
iterate over a collection or compare two values. Candidate rules must be
selected through repository evidence; this plan does not pre-approve the older
example rules.

### Deliverables for each rule

1. Record the requirement and enforcement-layer decision.
2. Allocate the rule ID.
3. Add metadata with resolved traceability paths.
4. Implement the smallest clear Rego invariant.
5. Add all required unit cases from the authoring guide.
6. Add valid and invalid full-message fixtures.
7. Confirm schema validation runs before Rego in the test path.
8. Confirm exact structured violation code and message.
9. Regenerate the registry and bundle.
10. Document the rule in the release rules README.

### Exit gate

- Unit and full-message tests pass.
- Every rule is visible in the generated registry.
- The built bundle returns defined results for applicable and unrelated inputs.
- No existing Release 2 example becomes invalid without an explicit correction.
- The complete Release 2 gate passes.

### Suggested commit

```text
feat(rego): add initial Release 2 business rules
```

## Phase 6 — Prove direct ONIX integration

**Status:** Not started

### Goal

Demonstrate that the actual ONIX plugin loads and enforces the bundle exactly as
the repository tooling expects.

### Deliverables

1. Pin the ONIX source revision used by the integration suite.
2. Add a reproducible ONIX test harness or documented test command.
3. Configure schema validation before `checkPolicy`.
4. Load the local bundle using `type: bundle`.
5. Verify the embedded signature using the test public-key response.
6. Send valid and invalid complete message bodies.
7. Assert HTTP/plugin outcome and structured policy errors.
8. Test exact `context.networkId` selection and no-match behavior.
9. Test an incorrect query path and confirm fail-closed behavior.
10. Test multiple simultaneous violations.
11. Capture useful diagnostics without logging sensitive fixture content.

### Exit gate

- ONIX accepts valid fixtures and rejects invalid fixtures for the intended
  rule IDs.
- Unrelated messages are not rejected.
- Wrong query, bad signature, and tampered bundle fail closed.
- The repository documents the exact command and pinned ONIX revision.
- The integration test is part of the applicable CI or an explicitly enforced
  pre-publication gate.

### Suggested commit

```text
test(rego): exercise Release 2 bundle through ONIX
```

## Phase 7 — Implement manifest-backed discovery and publication plumbing

**Status:** Not started

### Goal

Prove the production-recommended ONIX discovery path without inventing final ION
operational identities.

### Deliverables

1. Add a valid non-production network-manifest fixture.
2. Add manifest schema and cross-field validation matching current ONIX.
3. Serve manifest, detached signature, bundle, and public-key responses from a
   controlled local HTTP test server.
4. Exercise `manifestloader` plus `opapolicychecker` end to end.
5. Test invalid manifest signatures, expired governance, network-ID mismatch,
   missing query, bundle tampering, and unreachable artifacts.
6. Test cache and reload behavior, including retention of the last valid
   evaluator after a failed refresh.
7. Add deployed URL/content-type support for `.rego`, `.sig`, and `.tar.gz`.
8. Document the production manifest finalization inputs and owners.
9. Obtain the canonical ION network IDs, publisher domain, DeDi lookup URLs,
   key-custody procedure, and governance timestamps before creating the final
   production manifest.

### Exit gate

- Manifest-backed ONIX evaluation passes entirely with test infrastructure.
- Every failure mode produces the expected startup or reload behavior.
- Publication tooling refuses placeholders for production identity or key data.
- Final production manifest generation remains blocked until approved inputs
  are supplied.

### Suggested commit

```text
feat(rego): validate manifest-backed ONIX policy discovery
```

## Phase 8 — Inventory and implement Trade rules

**Status:** Not started

### Goal

Systematically convert approved Trade business invariants into tested Rego
without treating every prose condition as automatically normative.

### Inventory

Inspect, at minimum:

- Trade `attributes.yaml` constraints and annotations;
- generated schemas and examples;
- Trade flow patterns and variants;
- Trade error definitions;
- shared policy references;
- the older conditional-policy candidates; and
- constraints currently expressed through complex JSON Schema composition.

For each candidate, record:

- requirement and source;
- applicable actions and message shapes;
- owning schema/flow/policy artifact;
- current enforcement layer;
- proposed enforcement layer;
- compatibility impact;
- required data/config;
- `POL_*` code;
- implementation status; and
- deferral reason, if not included.

### Implementation waves

Implement in small connected waves rather than one large policy file:

1. catalog and publication invariants;
2. discovery and selection invariants;
3. initialization and confirmation invariants;
4. contract, payment, settlement, and reconciliation invariants;
5. performance, status, tracking, cancellation, and support invariants; and
6. cross-flow consistency and temporal rules.

Each wave updates rules, metadata, tests, fixtures, registry, bundle, release
README, and any connected schema/flow/error documentation.

### Exit gate for each wave

- Candidate ledger dispositions are reviewable.
- All included rules pass unit, schema-plus-policy, bundle, and ONIX tests.
- Existing Trade flows remain valid or are corrected in the same reviewed
  change.
- Schema overlap has an explicit decision and equivalence tests where needed.
- Performance remains acceptable on representative catalog/order sizes.
- The complete Release 2 gate passes.

### Suggested commit form

```text
feat(rego): enforce Trade <concern> rules
```

## Phase 9 — Inventory and implement Logistics rules

**Status:** Not started

### Goal

Add approved Logistics invariants using the same evidence and gates proven for
Trade.

### Inventory

Inspect all nine Logistics packs, patterns, variants, state machines, error
definitions, shared policy references, and candidate rules. Pay particular
attention to:

- dangerous-goods conditional data;
- participant role and credential relationships;
- offer and service-mode compatibility;
- commitment, contract, and performance consistency;
- state transitions and terminal states;
- tracking availability and event ordering;
- cross-border requirements; and
- time, location, capacity, and monetary relationships.

The list is an inspection scope, not advance approval of a rule.

### Implementation waves

1. catalog resource, provider, participant, and offer invariants;
2. selection, commitment, consideration, and contract invariants;
3. performance state and transition invariants;
4. tracking, cancellation, exception, and cross-border invariants; and
5. Trade-to-Logistics cross-sector invariants where Release 2 defines the
   necessary relationship.

### Exit gate for each wave

- Same gates as Trade.
- State rules agree with the validated Logistics state-machine registry.
- Rule errors agree with Logistics error targets.
- Cross-sector rules are gated so standalone Trade or Logistics messages are not
  rejected accidentally.
- The complete Release 2 gate passes.

### Suggested commit form

```text
feat(rego): enforce Logistics <concern> rules
```

## Phase 10 — Harden quality, security, and operations

**Status:** Not started

### Goal

Close non-functional risks before treating the rules area as validated.

### Deliverables

1. Set and enforce an appropriate coverage threshold.
2. Add large-message performance fixtures and regression limits.
3. Fuzz or property-test helpers with high input-shape risk.
4. Audit violation messages and fixtures for sensitive-data leakage.
5. Audit bundle and manifest parsers for path traversal and archive abuse.
6. Verify remote size and timeout behavior against ONIX limits.
7. Test hot reload, last-known-good retention, and rollback procedures.
8. Document monitoring, logging, alerting, and participant support guidance.
9. Document rule-change governance and emergency response.
10. Review whether any temporary duplicated schema constraints can or should
    remain duplicated; do not remove them automatically.

### Exit gate

- Security and operational review findings are closed or explicitly accepted.
- Performance limits and evidence are recorded.
- Rollback does not require modifying an immutable published bundle.
- NP configuration guidance is complete and tested.

### Suggested commit

```text
chore(rego): harden Release 2 policy operations
```

## Phase 11 — Validate the rules area and prepare publication

**Status:** Not started

### Goal

Move from a working draft feature to a publication-ready Release 2 artifact set.

### Deliverables

1. Resolve every candidate rule as included, rejected, or deferred with a
   reason.
2. Complete source, metadata, registry, fixture, and bundle review.
3. Obtain approved production network identity, DeDi key records, governance
   dates, and signing authority.
4. Build and sign the production bundle with key ID `default`.
5. Verify the production bundle using the live-format DeDi public-key response.
6. Finalize and sign the production network manifest.
7. Run manifest-backed ONIX tests against a preview deployment.
8. Change `contentStatus.rules` to `validated` only after all rule gates pass.
9. Update public architecture, authoring, integration, and release docs.
10. Record all `rules/` artifacts in the published checksum inventory when the
    release itself is published.
11. Validate deployed URLs and exact bytes after deployment.

### Publication gate

```bash
ruby tools/release/validate_release.rb releases/release2
ruby tools/release/validate_release.rb --publication releases/release2
ruby tools/release/validate_deployed_urls.rb releases/release2
```

The publication command is expected to fail while Release 2 remains a draft. It
must pass only as part of the reviewed release publication and channel
assignment process.

### Exit gate

- Release 2 has no unresolved rule-area validation failures.
- Production bundle and manifest signatures verify.
- ONIX enforces the deployed bytes through manifest discovery.
- Deployed bytes match the Release 2 artifact checksums.
- Participant configuration and rollback guidance are approved.

### Suggested commit

```text
release: validate Release 2 Rego policy artifacts
```

## Phase 12 — Post-publication verification and evidence

**Status:** Not started

### Goal

Confirm that publication, discovery, and participant enforcement work outside
the repository test environment without modifying the immutable release.

### Deliverables

1. Verify public bundle, manifest, signature, and source URLs.
2. Verify DeDi metadata resolves the intended manifest and keys.
3. Run a production-like NP ONIX smoke test using `type: manifest`.
4. Confirm the reported bundle/release identity in logs and diagnostics.
5. Record deployment validation evidence and the exact tested ONIX revision.
6. Track any correction as Release 3 work; do not patch Release 2 in place.

### Exit gate

- At least one representative NP environment demonstrates allow and reject
  behavior for the published bundle.
- Evidence identifies exact URLs, hashes, release ID, network ID, and ONIX
  revision.
- Operational ownership for monitoring and incident response is active.

## Cross-phase validation matrix

| Concern | First required | Remains required through |
|---|---|---|
| Release 1 compatibility | Phase 1 | Publication |
| Manifest v2 validation | Phase 1 | Publication |
| OPA format and compile | Phase 2 | Every rule change |
| Metadata and registry | Phase 3 | Every rule change |
| Bundle correspondence | Phase 4 | Every source/data change |
| Rule semantic tests | Phase 5 | Every rule change |
| Direct ONIX integration | Phase 6 | Every bundle change |
| Manifest-backed ONIX | Phase 7 | Every manifest/bundle change |
| Schema/Rego equivalence | First overlap | Until overlap is removed or retained permanently |
| Performance and security | Phase 10 | Publication and later releases |
| Exact deployed bytes | Phase 11 | Post-publication audit |

## Required decision log

During implementation, append material decisions to the relevant architecture,
authoring, or tooling document. At minimum, record:

- final directory and artifact names;
- OPA version and acquisition method;
- ONIX pinned revision and CI acquisition method;
- registry schema;
- rule ID allocation process;
- coverage and performance thresholds;
- production network IDs and publisher domain;
- signing algorithms, key identifiers, and custody owner;
- manifest release ID format and governance dates;
- refresh/cache recommendations; and
- accepted schema-to-Rego migrations.

## Definition of done

The objective is complete only when:

- Release 2 contains reviewed common, Trade, and Logistics Rego sources;
- every active rule is traceable, registered, and tested;
- generated artifacts are fresh and reproducible at the logical-content level;
- the signed production bundle is published at an immutable Release 2 URL;
- the signed network manifest resolves and verifies through DeDi;
- ONIX enforces the bundle using the documented public query;
- release, CI, deployment, and immutability gates cover `rules/`;
- NP setup and operational guidance are complete; and
- Release 1 remains unchanged and valid.
