# Creating and publishing an ION Rego rule

**Audience:** ION rule authors and reviewers

**Example:** `ION-R2-COM-0001` — a paid settlement must declare `paidAt`

This is the practical workflow for taking one approved English rule through
implementation, testing, bundling, and publication handoff. The detailed
conventions remain in the
[Rego authoring guide](ION_Rego_Authoring_Guide.md).

## The example

`ION-R2-COM-0001` says:

> In `confirm`, `on_confirm`, `status`, and `on_status` messages, every
> settlement whose payment status is `PAID` must contain `paidAt`.

The rule is not represented by one file. It has a normative source, executable
source, tests, fixtures, registry entry, signed bundle, public key, and
human-readable documentation.

## Files a rule author works with

Paths are relative to the repository root.

| File | Required action | Example for `ION-R2-COM-0001` |
|---|---|---|
| Normative schema, flow, or policy | Confirm the rule is authoritative. Change this only if the requirement itself needs clarification. | `releases/release2/schema/common/Payment/v1/attributes.yaml` and the Storefront flow |
| Production Rego | Add the rule and its metadata to an appropriate concern module. | `releases/release2/rules/rego/ion/release2/common/payment.rego` |
| Public router | Import and aggregate a newly created module. No change is needed for a module already connected to the router. | `releases/release2/rules/rego/ion/release2/policy.rego` |
| Rego unit tests | Test valid, invalid, inactive, unrelated-action, and missing-parent cases. | `releases/release2/rules/tests/common/payment_test.rego` |
| Valid message fixture | Add a realistic Beckn message that the public query accepts. | `releases/release2/rules/tests/fixtures/common/payment-paid-valid.json` |
| Invalid message fixture | Add a realistic message that activates the rule. | `payment-paid-missing-paid-at.json` |
| Expected result | Record the exact violation returned for the invalid fixture. | `payment-paid-missing-paid-at.expected.json` |
| Runtime data | Change only when the rule needs a normative lookup table. | `releases/release2/rules/data/data.json` |
| Release rules README | Add the rule to the human-readable inventory and document important limitations. | `releases/release2/rules/README.md` |
| Generated registry | Regenerate; never edit manually. | `releases/release2/rules/registry.json` |
| Signed artifact pair | Rebuild and commit both together; never edit manually. | `ion-release2-policy.tar.gz` and `ion-release2-policy-public.pem` |

If the rule changes the authoring, bundle, signing, or ONIX configuration
contract, also update the relevant document under `docs/rego/`.

## Author workflow

Run commands from the repository root.

### 1. Approve and scope the English rule

Before writing Rego, confirm:

- the requirement is normative rather than implementation advice;
- Rego is more appropriate than JSON Schema;
- the ONIX input contains all data needed to decide the rule;
- applicable sectors, patterns, actions, and message paths are unambiguous;
- related schemas, flows, examples, errors, and existing rules were checked;
  and
- the compatibility effect of rejecting previously accepted messages is
  understood.

Resolve disagreements between schemas, flows, and examples before coding. Do
not guess a JSON path or silently make a pattern-specific rule universal.

### 2. Allocate the next stable ID

Use the next unused ID in the correct area:

```text
ION-R2-COM-####   common or cross-sector
ION-R2-TRD-####   Trade
ION-R2-LOG-####   Logistics
```

Search both source and the generated registry:

```bash
rg "ION-R2-(COM|TRD|LOG)-" \
  releases/release2/rules/rego \
  releases/release2/rules/registry.json
```

IDs are never reused, even when a draft rule is withdrawn.

### 3. Write the rule and metadata

For the example, edit:

```text
releases/release2/rules/rego/ion/release2/common/payment.rego
```

The package must mirror the path:

```rego
package ion.release2.common.payment

import rego.v1
```

Place `# METADATA` immediately above the rule. It records the stable ID,
title, description, sector, actions, supported Beckn `POL_*` code, status, and
schema/flow/error/policy/data references.

Gate on the action and applicable parent object before reading deep optional
paths. A violation must have this shape:

```rego
{
    "code": "POL_ELIGIBILITY_NOT_MET",
    "message": "[ION-R2-COM-0001] message.contract.settlements[0].settlementAttributes.paidAt: required when payment status is PAID",
}
```

Diagnostics must be actionable and must not expose secrets or personal data.

If a new module was created, connect its `violations` set to
`releases/release2/rules/rego/ion/release2/policy.rego`. The only public query
remains:

```text
data.ion.release2.result
```

### 4. Add unit tests and message fixtures

For this example, the unit test must prove that:

1. `PAID` without `paidAt` returns the exact rule ID, code, and message;
2. `PAID` with `paidAt` is accepted;
3. `PENDING` is unaffected;
4. an unrelated action is unaffected;
5. a missing optional parent is unaffected; and
6. every invalid settlement is reported when a collection contains several.

Include the rule ID in the semantic test name.

Also create full-message fixtures:

```text
releases/release2/rules/tests/fixtures/common/
  payment-paid-valid.json
  payment-paid-missing-paid-at.json
  payment-paid-missing-paid-at.expected.json
```

A fixture without an `.expected.json` file is expected to return:

```json
{"valid": true, "violations": []}
```

The invalid fixture's expected file records the exact public result. When Rego
intentionally adds a condition beyond JSON Schema, keep that invalid fixture
schema-valid so the boundary between schema and policy enforcement is tested.

### 5. Format, generate, and run the focused checks

The repository pins the OPA version in `tools/rego/opa-version`.

```bash
ruby tools/rego/check_toolchain.rb

opa fmt --write \
  releases/release2/rules/rego/ion/release2/common/payment.rego \
  releases/release2/rules/tests/common/payment_test.rego

ruby tools/rego/generate_registry.rb --write releases/release2
ruby tools/rego/validate_sources.rb releases/release2
ruby tools/rego/validate_scaffold.rb releases/release2
```

Review the generated `rules/registry.json` entry. Fix metadata and regenerate
if it is wrong; never repair the registry directly.

`validate_scaffold.rb` compiles the modules, runs the Rego tests, evaluates all
smoke fixtures through `data.ion.release2.result`, and ensures every existing
Release 2 flow example is still accepted.

Pass `--opa /absolute/path/to/opa` to the Ruby tools when the pinned binary is
not on `PATH`.

### 6. Rebuild and verify the signed bundle

After changing production Rego or runtime data, rebuild the canonical artifact
pair:

```bash
ruby tools/rego/build_bundle.rb \
  --write \
  --ephemeral-sign \
  releases/release2

ruby tools/rego/verify_bundle.rb releases/release2
```

The build creates a temporary ES256 key pair, signs with key ID `default`,
writes the bundle and matching public key atomically, and destroys the private
key. Commit both generated files together:

```text
releases/release2/rules/bundles/ion-release2-policy.tar.gz
releases/release2/rules/bundles/ion-release2-policy-public.pem
```

Every rebuild rotates the public key. Never mix generations and never commit a
private key.

### 7. Run the optional ONIX integration for a rule change

```bash
ruby tools/rego/test_onix_integration.rb \
  --onix-root /path/to/pinned/beckn-onix
```

The checkout must be at the revision in `tools/rego/onix-revision`. This runs
the signed bundle through the actual ONIX OPA Policy Checker. It requires Go,
but not Docker or a running ONIX adapter. The manual **Optional Rego ONIX
integration** GitHub Actions workflow is the alternative.

### 8. Run the complete Release 2 gate

```bash
ruby tools/release/validate_release.rb releases/release2
```

This is the CI entry point. A normal rule change should now include the Rego
source, tests, fixtures, README update, generated registry, bundle, and public
key. It includes the router and runtime data only when those were affected.

While Release 2 is a draft, this command is intentionally expected to fail:

```bash
ruby tools/release/validate_release.rb \
  --publication \
  releases/release2
```

Do not change publication state merely to make the publication command pass.

## Publication handoff

A rule author prepares the complete draft artifact set. Publishing Release 2
is a separate, governed release-maintainer operation.

When all approved rules are complete, release maintainers:

1. run the final bundle build and ONIX interoperability tests;
2. change `contentStatus.rules` from `validation-pending` to `validated` only
   after all rule gates pass;
3. put the release manifest into its reviewed publication form;
4. record the complete normative artifact checksum inventory;
5. pass the normal and publication validation gates;
6. deploy the exact committed artifacts; and
7. verify the deployed bytes and test the public URLs from ONIX.

The publication commands include:

```bash
ruby tools/release/record_artifact_checksums.rb \
  --write \
  releases/release2

ruby tools/release/validate_release.rb releases/release2
ruby tools/release/validate_release.rb \
  --publication \
  releases/release2
```

The checksum command belongs in the controlled publication change. Running it
in an ordinary draft rule pull request does not create the published inventory
for ION-authored files.

After deployment, the canonical configuration values are:

```text
Bundle:     https://schema.ion.id/release2/rules/bundles/ion-release2-policy.tar.gz
Public key: https://schema.ion.id/release2/rules/bundles/ion-release2-policy-public.pem
Query:      data.ion.release2.result
```

Maintainers then run:

```bash
ruby tools/release/validate_deployed_urls.rb releases/release2
```

Files visible on `main` while Release 2 is a draft are not yet a published
contract. After publication, Release 2 is immutable; corrections and new rules
belong in the next integer release.

## Final author checklist

- [ ] Approved English requirement and compatibility decision
- [ ] Unique stable ID and complete metadata
- [ ] Explicit action, sector, and message-shape guards
- [ ] Unit tests and full-message valid/invalid fixtures
- [ ] Existing flow examples still accepted
- [ ] Release rules README updated
- [ ] Registry regenerated and reviewed
- [ ] Bundle and public key rebuilt and committed together
- [ ] Bundle verification and optional ONIX integration passed
- [ ] Complete Release 2 gate passed
- [ ] Publication state left to release maintainers
