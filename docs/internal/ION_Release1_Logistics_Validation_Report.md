# ION Release 1 Logistics Validation Report

**Status:** Phase 8 complete — Logistics validated  
**Validation date:** 2026-10-16  
**Release status:** Draft; this report does not publish or channel Release 1

## Scope closed

Phase 8 closes the Logistics migration described in
`docs/internal/ION_Release1_Logistics_Migration_Plan.md`. The validated scope is:

- nine Logistics schema packs and the common `IdentifiableLocation` pack;
- six Logistics patterns and nine included or scoped variants;
- the shared Logistics performance-state registry under the flow tree;
- 22 draft Logistics policy terms in the independently governed root registry;
  and
- 30 connected Logistics errors in the Release 1 error registry.

Deferred policies, variants, and errors remain outside this scope. Their
machine-readable maps and migration ledgers preserve the reasons; validation of
the included subset does not imply support for a deferred branch.

## Inputs and provenance

| Input | Revision | Role |
|---|---|---|
| Legacy ION Logistics | `33e6b4c40feabecf6b0f6a827b488ff82998c735` | Pinned migration source |
| Beckn Logistics | `4d98c3c9b7244f32f3a900272adc990d870df0bf` | Non-normative alignment comparison |
| Schema v2 validator | `155ba05e7c31f58aafd7606e112ddc1c0ed6a3d0` | External deep validation tool |

Release-owned Logistics artifacts are covered by the repository license. Beckn
protocol and schema dependencies remain pinned in `release.yaml`, with upstream
and released checksums, transformations, licence identifiers, and retained
licence texts under `schema/vendored/beckn/licenses/`. The current Beckn
Logistics repository is not a normative dependency.

## Closure evidence

| Criterion | Evidence | Result |
|---|---|---|
| Every included pack passes deep validation | Staged full Logistics `schema-dir` run | Passed: 9 packs |
| Every example validates | Object validation against the staged extended-schema index | Passed: 9 examples |
| References resolve offline | `validate_offline_refs.rb` | Passed |
| Public URLs map to committed paths | `validate_public_urls.rb` | Passed |
| Pack companion artifacts agree | Schema v2 validation plus generated-schema, JSON-LD, profile, renderer, and release gates | Passed |
| Flows and state-machine targets resolve | Logistics connection and performance-state validators | Passed: 6 patterns, 9 variants, 10 machines, 135 states |
| Policy IRIs resolve | Policy migration-map and Logistics connection validators | Passed: 22 included terms; all 59 legacy strings dispositioned |
| Error targets resolve | Logistics error validator | Passed: 30 included errors; all 97 legacy codes dispositioned |
| Dependency provenance and licensing are complete | Manifest dependency records, checksums, `NOTICES.md`, and vendored licence texts | Passed |
| Generated registries and checksums are current | Registry generators and artifact checksum validators | Passed |
| Complete Release 1 gate passes | `validate_release.rb` | Passed |

The draft schema URLs were staged locally before external validation. The
staging tool rewrote retrieval-only `$ref` locations in a temporary copy; it did
not alter public identifiers or normative release files.

## Commands run

```bash
ruby tools/release/stage_schema_validator_tree.rb \
  releases/release1 /tmp/ion-specs-phase8/release1

cd ../ion-testbed/tools/schemav2validator
go run ./cmd/schemav2validator schema-dir --json \
  /tmp/ion-specs-phase8/release1/schema/extension/logistics

# Repeated for every file below schema/extension/logistics/*/v1/examples/.
go run ./cmd/schemav2validator object --json \
  --extended-local-schema-dir /tmp/ion-specs-phase8/release1/extended-schemas \
  <example.json>

cd ../../../ion-specs
ruby tools/release/validate_path_map.rb --require-sources \
  --source-root ../ion-specs-ion-launch \
  tools/release/release1-logistics-path-map.json
ruby tools/policies/validate_logistics_policy_map.rb \
  --source-root ../ion-specs-ion-launch .
ruby tools/release/validate_logistics_errors.rb \
  --source-root ../ion-specs-ion-launch releases/release1
ruby tools/release/validate_release.rb releases/release1
git diff --check
```

With this evidence, `contentStatus.logistics` is changed from
`review-required` to `validated`. `status: draft` is unchanged. Publication into
`next` remains a separate Council-controlled process and the publication-form
gate is still expected to fail until that decision is made.
