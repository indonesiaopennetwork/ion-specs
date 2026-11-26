# ION Release 2 Rego delivery design and roadmap

**Status:** Foundation implemented; sector rule authoring and publication
remain open

**Decision dates:** 2026-11-25 to 2026-11-26

**Target:** `releases/release2/`

## Purpose

This document records the delivery shape, completed foundation, and remaining
release gates for ION-authored Rego rules. It is a design and status record,
not the rule-authoring procedure. Future rule authors should use the
[`ION_Rego_Rule_Creation_Workflow.md`](../../rego/ION_Rego_Rule_Creation_Workflow.md)
and the candidate ledgers.

The durable public decisions are in:

- [`ION_Rego_Architecture.md`](../../rego/ION_Rego_Architecture.md);
- [`ION_Rego_Authoring_Guide.md`](../../rego/ION_Rego_Authoring_Guide.md);
- [`ONIX_Rego_Integration.md`](../../rego/ONIX_Rego_Integration.md); and
- [`ION_Rego_Tooling_Design.md`](ION_Rego_Tooling_Design.md).

## Delivery model

Rego is a release-owned normative artifact. Release 2 owns its sources, test
fixtures, runtime data, generated registry, signed OPA bundle, and matching
public key under `releases/release2/rules/`. Published Release 1 remains
unchanged.

The release exposes one public query:

```text
data.ion.release2.result
```

The query receives the complete Beckn message body and returns a boolean plus
structured `POL_*` violations. ONIX must run schema validation before policy
evaluation.

Each NP explicitly selects the integer release it enforces by configuring the
corresponding direct signed bundle. A network-policy manifest is not used:
current manifest lookup selects one artifact per `networkId` and cannot model
intentional Release 2/Release 3 coexistence on the same network.

## Fixed design decisions

1. **Release boundary.** Rules live inside the integer release and become
   immutable when that release is published.
2. **Validation boundary.** JSON Schema owns ordinary shape, type, enum, format,
   and direct required-field constraints. Rego owns action-specific,
   cross-field, cross-object, calculation, lookup, and workflow invariants.
3. **Source organization.** Modules are grouped by release, area, and concern;
   rule IDs are release-local and never reused.
4. **Public contract.** Only `data.ion.release2.result` is an operator
   configuration contract. Internal packages may change while the release is a
   draft.
5. **Registry.** `rules/registry.json` is generated deterministically from OPA
   metadata and is never edited directly.
6. **Runtime data.** Normative lookup data belongs in the signed bundle.
   Operator-supplied `data.config` is allowed only for explicitly documented
   deployment-specific values.
7. **Bundle.** The runtime unit is one signed OPA bundle containing common,
   Trade, and Logistics rules plus normative data.
8. **Signing.** Release 2 uses ES256 with key ID `default`. Every canonical
   build generates an ephemeral key pair, destroys the private key, and commits
   the signed bundle and matching public key together.
9. **Publication origin.** The bundle and public key are published from the
   GitHub-backed `schema.ion.id` origin. This detects corruption and mismatched
   artifacts but is not an independent trust channel; that limitation is
   accepted for Release 2.
10. **Testing.** OPA validation is part of the ordinary Release 2 gate. Direct
    ONIX integration remains an explicit optional test for rule, bundle, and
    compatibility changes because it requires a separate pinned ONIX checkout
    and Go toolchain.

## Implemented foundation

The following foundation is complete:

- release manifest schema v2 recognizes `rules/` without changing published
  Release 1;
- Release 2 contains the production, test, fixture, data, registry, and bundle
  layout;
- OPA CLI `1.15.2` is pinned to the ONIX runtime version;
- formatting, strict compilation, metadata, ID, action, error-code, source-path,
  configuration, and semantic-test validation are implemented;
- deterministic registry generation and freshness checks are implemented;
- bundle construction allowlists production modules and runtime data and
  excludes tests, documentation, symlinks, unexpected files, and private-key
  material;
- bundle verification checks source correspondence, archive safety, size,
  signature, key ID, and public-query evaluation;
- three starter rules prove common and Trade authoring:
  `ION-R2-COM-0001`, `ION-R2-TRD-0001`, and `ION-R2-TRD-0002`;
- valid, invalid, unrelated-action, missing-parent, collection, and complete
  message fixtures exercise the starter rules;
- the actual ONIX OPA Policy Checker has loaded and enforced the signed bundle,
  including wrong-key, tamper, incorrect-query, and multiple-violation cases;
- ONIX integration is separate from normal spec validation and is available
  locally and through a manual workflow; and
- author, operator, architecture, tooling, and rule-creation documentation is
  present under `docs/rego/`.

Session-close validation on 2026-11-26 passed for both releases. The complete
Release 2 gate passed 155 tool tests with 503 assertions, all 18 Rego tests,
seven smoke fixtures, 44 reference-flow regressions, signed-bundle validation,
and all release connection checks. The complete published Release 1 gate also
passed, confirming the manifest-v1 and immutable-release compatibility boundary.

## Rule inventory status

The initial Trade and Storefront English-rule inventory is in
[`ION_Rego_Trade_Rule_Candidates.md`](ION_Rego_Trade_Rule_Candidates.md). It
separates:

- message-local candidates that can be evaluated by the current policy input;
- constraints already owned by JSON Schema;
- conditions that need normative approval;
- rules needing catalog data, prior messages, a clock, or an external registry;
  and
- pattern or variant rules that should be deferred to their own scope.

The inventory also records a prerequisite for Storefront rules: several
`requiredFields` paths do not match the current Beckn 2 message shape and
examples, and the production message has no authoritative Storefront selector.
Those sources and applicability semantics must be aligned before Storefront-only
rules enter the release-wide query.

No comprehensive Logistics candidate ledger has been created yet.

## Remaining roadmap

The remaining work is intentionally listed at design level. Each rule follows
the separate rule-creation workflow.

1. **Align Storefront sources.** Reconcile the pattern's field paths, examples,
   current Beckn 2 contract, category scope, and pattern-selection mechanism.
2. **Approve Trade candidates.** Resolve each candidate as implement, retain in
   schema, reject, or defer; record the reason and compatibility effect.
3. **Implement Trade rules in reviewable groups.** Prefer catalog/publication,
   selection, initialization/confirmation, settlement/reconciliation,
   fulfilment/support, and finally stateful cross-flow concerns.
4. **Inventory and approve Logistics rules.** Apply the same schema-versus-Rego,
   input-availability, compatibility, and statefulness analysis used for Trade.
5. **Implement approved Logistics rules.** Keep cross-sector rules explicitly
   gated so standalone Trade or Logistics messages are not rejected by accident.
6. **Harden quality and operations.** Add representative large-message
   performance evidence, sensitive-diagnostic review, helper fuzzing where
   valuable, reload and last-known-good tests, monitoring guidance, and incident
   and rollback procedures.
7. **Validate the rules area for publication.** Resolve the candidate ledgers,
   run the final bundle build and ONIX evidence, complete governance review,
   and change `contentStatus.rules` from `validation-pending` to `validated`
   only when all rule gates pass.
8. **Prove the public origin.** When the `schema.ion.id` paths exist, test remote
   bundle and PEM retrieval, content types, size limits, caching/refresh,
   unreachable and malformed responses, key mismatch, tampering, and retention
   of the last valid evaluator.
9. **Publish with Release 2.** Record the complete artifact checksum inventory,
   pass the publication gate, deploy the exact committed bundle and key, and
   publish the release-qualified operator configuration.
10. **Verify after publication.** Validate deployed bytes and URLs, run a
    production-like NP ONIX allow/reject smoke test, record the exact ONIX
    revision and hashes, and direct any correction to Release 3.

The former standalone remote-test phase was deliberately skipped while the
public URLs do not exist. Local ONIX and GitHub-backed loading already prove
the bundle format and signature path; deployed-origin behavior belongs to the
publication work above.

## Validation contract

Every rule change must retain these gates:

| Concern | Required check |
|---|---|
| OPA version | Exact repository pin matches the ONIX runtime |
| Source | Formatting, strict compilation, package/path convention, metadata, IDs, actions, `POL_*` codes, and references |
| Semantics | Applicable-invalid, applicable-valid, inactive, unrelated-action, missing-parent, boundary, and collection tests as relevant |
| Regression | Every checked Release 2 flow example remains accepted or is corrected through an approved specification change |
| Registry | Generated output matches source metadata |
| Bundle | Logical source/data correspondence, safe archive, ONIX size limit, ES256 signature, matching public key, and public query |
| ONIX | Optional but expected for rule, bundle, pinned-version, or interoperability changes |
| Release | Complete active-draft gate passes |

The ordinary gate is:

```bash
ruby tools/release/validate_release.rb releases/release2
```

The ONIX compatibility test is:

```bash
ruby tools/rego/test_onix_integration.rb \
  --onix-root /path/to/pinned/beckn-onix
```

The publication form is expected to fail while Release 2 remains a draft:

```bash
ruby tools/release/validate_release.rb \
  --publication \
  releases/release2
```

## Publication acceptance

The rules area is ready to publish only when:

- every included rule is traceable, registered, reviewed, and tested;
- unresolved candidates are explicitly deferred or rejected;
- schemas, flows, examples, errors, and Rego agree;
- performance and diagnostic-safety evidence is acceptable;
- the final bundle and PEM key verify as one artifact generation;
- direct ONIX evaluation passes at the pinned revision;
- `contentStatus.rules` is `validated`;
- the complete release publication inventory includes `rules/`;
- the immutable public bundle and key URLs serve the exact committed bytes;
- NP configuration, refresh, rollback, monitoring, and support guidance is
  approved; and
- Release 1 remains unchanged and valid.

## Post-publication rule

Release 2 is immutable after publication. A defect, changed requirement, new
rule, or key rotation after that point belongs in the next integer release.
Neither a mutable `latest` bundle nor an in-place Release 2 correction is part
of the design.
