# ION Rego Authoring Guide

**Status:** Accepted

**Guide date:** 2026-11-25

**Current target:** `releases/release2/rules/`

## Purpose

This guide defines how ION Rego rules are selected, written, identified,
documented, tested, and reviewed for an integer ION release. Examples use
Release 2, the current draft. For a later release, substitute its release
number consistently in source paths, package names, rule identifiers, public
query, fixtures, registry, and bundle artifacts.

## Authoring principles

1. A rule enforces one explainable business invariant.
2. Applicability is explicit; a rule must not infer its sector or action from an
   ambiguous property name.
3. Valid inputs produce no violation; invalid inputs produce a stable,
   actionable violation.
4. Missing optional parent objects do not cause accidental evaluation failures.
5. Normative values are consistent for every participant on the same network.
6. A rule is not complete without tests, metadata, traceability, and a recorded
   compatibility decision.
7. Rules remain understandable without relying on undocumented ONIX behavior.

## Decide whether Rego is the correct layer

Use Rego when at least one of these is true:

- validity depends on two or more fields;
- validity depends on the Beckn action or message shape;
- a value must agree across multiple objects or collections;
- arithmetic, aggregation, or comparison is required;
- timestamps or durations must be related;
- a controlled lookup or policy data table determines validity;
- the rule spans schema packs; or
- an equivalent schema expression is materially harder to review and diagnose.

Prefer JSON Schema for direct type, enum, format, range, pattern, object-shape,
and unconditionally required-field constraints. Prefer prose or a shared policy
term when there is no executable yes/no invariant.

Before adding a Rego rule, record whether related enforcement already exists in
OpenAPI, a schema pack, a flow, an error definition, another Rego module, or an
external operational control.

## Source organization

Production modules use this hierarchy:

```text
rego/ion/release2/
  policy.rego
  helpers.rego
  common/
    <concern>.rego
  trade/
    <concern>.rego
  logistics/
    <concern>.rego
```

Organize by action or structural concern, such as `catalog`, `order`,
`performance`, `settlement`, or `tracking`. Do not create files named only by a
sequence number or place hundreds of unrelated rules in one module.

Package declarations mirror paths:

```rego
package ion.release2.trade.order

import rego.v1
```

`package ion.release2` is reserved for the public router and result.

## Public result contract

Only `data.ion.release2.result` is public. Internal packages export violation
sets to the router, but are not configuration contracts for NPs.

The router returns:

```rego
result := {
    "valid": count(violations) == 0,
    "violations": violations,
}
```

The result must be defined for all inputs. Internal rules must not create an
alternate public result for a sector or action.

Each violation is an object:

```rego
{
    "code": "POL_ELIGIBILITY_NOT_MET",
    "message": "[ION-R2-TRD-0001] order.items[2]: requested quantity exceeds the offer limit",
}
```

`code` must be a supported Beckn `POL_*` value. Do not invent an error code in
Rego. If no precise existing code applies, use the agreed generic policy code
and record the taxonomy gap for later protocol work.

The message must:

- start with the stable ION rule ID;
- identify the relevant input location;
- state the violated invariant, not merely say `invalid`;
- avoid secrets or unnecessary personal data; and
- include a regulatory citation only when that citation is an approved basis
  for the rule.

## Rule identifiers

Every blocking rule has an ID:

```text
ION-R2-COM-0001
ION-R2-TRD-0001
ION-R2-LOG-0001
```

The components are release, area, and a zero-padded number. IDs are never
reused within a release, even if a draft rule is withdrawn. Renaming a Rego
helper does not change the rule ID. Splitting one business invariant into two
independently actionable failures requires two IDs.

Rule IDs are release-local. A semantically equivalent Release 3 rule receives a
Release 3 ID so diagnostics identify the enforced release unambiguously.

## Rule metadata

Each rule carries OPA metadata immediately above its declaration. The minimum
metadata is:

```rego
# METADATA
# title: Order item quantity does not exceed the selected offer limit
# description: Enforces the quantity agreed during selection when an order is initialized or confirmed.
# scope: rule
# custom:
#   ion_rule_id: ION-R2-TRD-0001
#   sector: trade
#   actions:
#     - init
#     - confirm
#   error_code: POL_ELIGIBILITY_NOT_MET
#   status: active
#   schema_paths:
#     - schema/extension/trade/TradeOffer/v1/attributes.yaml
#   flow_paths:
#     - flows/trade/patterns/storefront/v1/pattern.yaml
```

`scope: rule` binds the annotation to the declaration immediately below it.
`status` is `active` or `withdrawn`; withdrawn IDs remain reserved. Additional
metadata may use `error_paths`, `policy_iris`, `config_keys`, and `data_paths`.
Policy IRIs in YAML flow collections must be quoted. Metadata paths are
release-relative, must stay below the release root, and must resolve. The
generated rule registry derives from these annotations and is never edited
directly. The machine-readable contract is
`tools/rego/rule-metadata.schema.json`.

## Applicability and evaluation structure

Place the cheapest reliable guard first. Common gates include:

```rego
input.context.action == "confirm"
input.message.order
```

Large packages use private helper buckets and a public sector aggregation gate:

```rego
_order_violations contains violation if {
    item := input.message.order.items[i]
    # invariant expressions
    violation := {
        "code": "POL_ELIGIBILITY_NOT_MET",
        "message": sprintf("[ION-R2-TRD-0001] order.items[%d]: ...", [i]),
    }
}

violations contains violation if {
    input.context.action == "confirm"
    input.message.order
    some violation in _order_violations
}
```

Use named helpers for repeated accessors, predicates, parsing, and calculations.
Avoid negation over complex iteration when a positive helper predicate is
clearer. Parse a timestamp once and reuse the parsed value.

Rule order must not affect the decision. Violation collections are sets; callers
must not depend on response ordering unless the tooling explicitly normalizes
the result for tests.

## Safe path access

Schema validation runs first, but many fields remain optional. A rule must not
turn the absence of an inapplicable parent object into a violation.

- Gate on the action and parent shape before deep access.
- Use `object.get` when a missing value needs an explicit default.
- Distinguish missing, `null`, empty string, and empty collection only when the
  release contract distinguishes them.
- Do not accept multiple field spellings unless the selected release actually
  permits each spelling.
- Do not read transport headers or state unavailable in the JSON body.

## Runtime data and configuration

Use bundle data for normative lookup tables and thresholds. For example,
Release 2 uses:

```text
data.ion.release2.<area>.<name>
```

The source is `rules/data/data.json`. Keep it deterministic, documented, and
small enough to review. Do not embed large opaque datasets without provenance
and an explicit update lifecycle.

Use `data.config` only for an approved deployment-specific value. Every use must
declare the key in rule metadata and the selected release's operator
documentation. Convert string values explicitly because ONIX plugin
configuration forwards them as strings.

Rules must not silently choose different normative behavior because a config
key is missing or malformed.

## Relationship to schemas and annotations

An `x-ion-condition` or similar schema annotation is descriptive until an
enforcement mechanism is connected. Adding an annotation does not automatically
authorize or generate a Rego rule.

When a rule implements a documented condition:

- metadata identifies the exact schema path;
- the prose condition and Rego behavior agree;
- examples cover the condition;
- tests show both active and inactive behavior; and
- the compatibility record states whether JSON Schema also enforces it.

Candidate examples in `docs/ION_ONIX_Conditional_Policy.md` must be rechecked
against the selected release's field names, nesting, scope, and complete-message
input before reuse. Hospitality examples remain out of scope while Hospitality
is excluded from the current Release 2 draft.

## Required tests for each rule

At minimum, every rule tests:

1. applicable condition plus invalid or missing value produces the expected ID,
   code, and message;
2. applicable condition plus valid value does not produce the violation;
3. inapplicable condition does not produce the violation;
4. unrelated action does not produce the violation;
5. missing optional parent shape does not produce an accidental violation;
6. boundary values, when the rule compares numbers, dates, durations, or counts;
7. multiple matching collection elements, when iteration is involved; and
8. interaction with another module when the rule shares helpers or data.

Tests should use the smallest input that proves the invariant. In addition,
representative end-to-end tests use actual or deliberately derived flow messages
from the selected release so that simplified unit inputs do not conceal path
mismatches.

For a constraint duplicated temporarily in JSON Schema and Rego, add equivalence
fixtures showing that both layers accept and reject the same boundary cases.

### When to run the optional ONIX integration

The normal active-release gate validates Rego with the pinned OPA CLI and does
not checkout or compile ONIX. Run the separate ONIX integration when a change:

- adds or changes a rule or its result shape;
- changes the bundle, signature, query, fixtures, or bundle tooling;
- changes the pinned OPA or ONIX version;
- prepares a Rego-focused pull request for interoperability review; or
- contributes to pre-publication evidence.

It is normally unnecessary for schema, flow, error, policy-term, or prose-only
changes that do not affect executable rules. The command requires Git, Ruby, Go
1.26.1, and the exact ONIX revision in `tools/rego/onix-revision`; it does not
require Docker or a running adapter:

```bash
ruby tools/rego/test_onix_integration.rb --onix-root /path/to/pinned/beckn-onix
```

See `tools/rego/README.md` for checkout instructions and the full scenario list.
The manual **Optional Rego ONIX integration** GitHub Actions workflow provides
the same test when a suitable local Go environment is unavailable.

## Performance guidelines

- Gate before iterating.
- Prefer set membership to repeated array scans for controlled values.
- Avoid unbounded Cartesian products.
- Cache repeated derived values in helper rules.
- Parse time and numeric strings once per query.
- Keep bundle data indexed by stable keys when direct lookup is possible.
- Add a benchmark or explicit performance fixture for rules that scan catalogs
  or large order collections.

Correctness is the first gate, but an NFO rule must not make ordinary message
exchange unpredictably expensive.

## Review checklist

Before accepting a rule, confirm:

- the requirement is normative and within the selected release's scope;
- Rego is the appropriate enforcement layer;
- sector, actions, and message shapes are correctly gated;
- metadata paths and policy IRIs resolve;
- the identifier is unique and registered;
- the `POL_*` code exists and is suitable;
- violation text is actionable and safe;
- normative data is not operator-selectable by accident;
- overlap with JSON Schema is explicitly classified;
- unit, integration, and negative tests cover the rule;
- the full bundle compiles and evaluates through ONIX; and
- affected schemas, flows, errors, examples, and documentation agree.
