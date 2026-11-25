# ION Release 2 Rego Architecture

**Status:** Accepted working design

**Decision date:** 2026-11-25

**Target:** `releases/release2/`

**Runtime:** ONIX `opapolicychecker`

## Purpose

This document defines where ION-authored Rego rules belong, how they relate to
schemas and shared policy terms, how ONIX evaluates them, and how they are
packaged and published with Release 2.

ION needs executable rules for requirements that JSON Schema cannot express
well: cross-field consistency, message-action conditions, calculations,
temporal relationships, lookup-driven requirements, and invariants spanning
multiple objects. The rules are authored by ION as the Network Facilitating
Organization and are intended to be enforced locally by participating NPs
through ONIX during message exchange.

## Fixed decisions

### Rego rules are release-owned normative artifacts

Executable rules depend on the exact message, schema, flow, action, and error
contracts in an integer release. They therefore belong inside that release and
become immutable when the release is published.

Release 2 adds a fourth principal release area:

```text
releases/release2/
  schema/
  flows/
  errors/
  rules/
```

The durable release architecture must be amended before publication to
recognize `rules/` as a normative artifact root.

### Rego rules do not belong in root `policies/`

Root `policies/` contains versioned semantic policy terms with an independent
governance lifecycle and stable `ion://policy/...` identifiers. A policy term
can be referenced by more than one integer release.

Release-local Rego modules are executable validation logic over a specific wire
contract. They may enforce or refer to a shared policy term, but they are not a
second copy of that term and must not be placed in the shared policy source
tree.

### Release 1 remains unchanged

Release 1 is published and immutable. Rego support is introduced only in the
Release 2 draft. Repository tools must continue to validate Release 1 under its
existing manifest and artifact-root contract.

### One network bundle is the production unit

ONIX selects one evaluator and one query for a configured `networkId`. Release 2
will therefore publish one canonical ION bundle containing common, Trade, and
Logistics modules. Internal modules remain separated by sector and concern, but
operators do not compose multiple bundles.

The stable query is:

```text
data.ion.release2.result
```

The result must be defined for every structurally valid input, including inputs
to which no ION business rule applies. ONIX treats an undefined result as a
configuration error and rejects the request.

### ONIX receives the complete Beckn message body

Rules are written against the complete JSON request body supplied to ONIX:

```text
input.context
input.message
input.error
```

Rules must not assume that ONIX invokes a different query for each attribute
pack. Applicability is established inside the bundle using action, message
shape, sector, type, and other explicit guards.

HTTP headers, signature state, and router metadata are not available to the
policy. Transport rules that cannot be derived from the body do not belong in
this bundle.

## Proposed release layout

```text
releases/release2/rules/
  README.md

  rego/
    ion/release2/
      policy.rego
      helpers.rego
      common/
      trade/
      logistics/

  tests/
    common/
    trade/
    logistics/
    fixtures/

  data/
    data.json

  registry.json

  bundles/
    ion-release2-policy.tar.gz

  network-policy-manifest.yaml
  network-policy-manifest.yaml.sig
```

`rego/`, `tests/`, and `data/` are reviewed source inputs. `registry.json`, the
bundle, and the final network manifest artifacts are generated or finalized
outputs and must have freshness checks.

The production bundle contains only production Rego modules, normative runtime
data, the OPA bundle manifest, and the embedded OPA signature. Tests, fixtures,
source documentation, build scripts, and private keys are excluded.

## Validation-layer boundary

Schema and Rego enforcement are complementary:

| Layer | Primary responsibility |
|---|---|
| OpenAPI and JSON Schema | Shape, types, formats, enums, locally required fields, and straightforward local constraints |
| Rego | Cross-field and cross-object consistency, action-dependent requirements, calculations, temporal logic, lookup-driven requirements, and business invariants |

Schema validation runs before policy evaluation in ONIX. Rego may assume only
the structural guarantees provided by the configured Release 2 schemas, and
must still use safe access patterns for optional paths.

An existing schema constraint is not removed simply because an equivalent Rego
rule is shorter. Moving enforcement out of JSON Schema is a compatibility
decision because policy enforcement is configured separately and an ONIX
instance can otherwise skip unmatched networks.

Each overlapping constraint must explicitly choose one state:

1. schema-only;
2. temporarily enforced in both layers, with equivalence tests and one named
   source of truth; or
3. moved to Rego through an approved compatibility change that makes the Rego
   bundle part of Release 2 conformance.

Silent weakening of JSON Schema is prohibited.

## Runtime composition

`package ion.release2` owns the only public `result`. It aggregates internal
violation sets from common, Trade, and Logistics packages.

```text
ion.release2.result
  <- ion.release2.common.violations
  <- ion.release2.trade.violations
  <- ion.release2.logistics.violations
```

Sector routers decide whether their internal rules apply. A Trade rule must not
run merely because a similarly named property appears in a Logistics message.
The cheapest reliable discriminator is evaluated first.

The public result uses the structured format supported by ONIX:

```json
{
  "valid": false,
  "violations": [
    {
      "code": "POL_ELIGIBILITY_NOT_MET",
      "message": "[ION-R2-TRD-0001] order: ..."
    }
  ]
}
```

Only blocking violations are included. The current ONIX contract has no
portable warning channel; advisory findings must not be disguised as failures.

## Configuration and normative data

Normative values that every participant must enforce identically belong in the
signed bundle's data, including controlled lookup sets, network-wide limits,
and approved regulatory thresholds.

ONIX also exposes operator-supplied values as `data.config`. Normative rules
must not use operator-selected thresholds unless the release contract explicitly
defines that value as deployment-specific. Otherwise two NPs could enforce
different behavior while claiming the same Release 2 policy.

Every permitted `data.config` key must be documented with its type, semantics,
default behavior, and consistency requirements. Missing normative configuration
must fail closed rather than silently select a convenient default.

## Versioning and compatibility

- The integer release is the primary compatibility boundary.
- Rego package paths include `release2` and do not change after publication.
- Rule identifiers are stable within the release.
- The production bundle URL is immutable and release-qualified.
- Published bundle bytes, source rules, runtime data, registry, manifest, and
  signature are protected by the Release 2 immutability contract.
- Corrections after Release 2 publication belong in the next integer release.

A mutable `latest` bundle is not published. ONIX hot reload may fetch the
release-qualified bundle repeatedly, but it must receive identical bytes for a
published release.

## Manifest evolution

The current manifest schema knows only the original artifact roots. Release 2
will move to release manifest `schemaVersion: 2`, adding:

```yaml
contentStatus:
  rules: validation-pending
```

The v2 publication inventory covers `schema/`, `flows/`, `errors/`, and
`rules/`. Validators must dispatch by manifest schema version so the published
Release 1 v1 manifest remains valid without alteration.

`rules` follows the same content states as other areas:

```text
review-required -> validation-pending -> validated
                                      -> excluded
```

Release 2 cannot be published with included rule artifacts unless
`contentStatus.rules` is `validated`.

## Packaging and signing

The canonical artifact is an OPA `.tar.gz` bundle. It is signed using an
ION-controlled production key and an ONIX-supported algorithm. ES256 is the
default choice. The bundle signature must use key ID `default`, matching the
current ONIX verifier configuration.

Private signing keys never enter this repository or generated build artifacts.
Local and CI tests use a clearly separate non-production key. The release
process signs the candidate bundle in a controlled environment and verifies it
using the same public-key representation published through DeDi.

The completed bundle must remain below ONIX's 10 MB remote bundle limit.

## Publication and discovery

The production URLs are release-qualified:

```text
https://schema.ion.id/release2/rules/bundles/ion-release2-policy.tar.gz
https://schema.ion.id/release2/rules/network-policy-manifest.yaml
https://schema.ion.id/release2/rules/network-policy-manifest.yaml.sig
```

The network manifest declares the exact bundle URL and query. The DeDi network
registry publishes metadata pointing to the manifest, its detached signature,
and the manifest verification key. NPs configure ONIX using `type: manifest`
for the exact ION `networkId`.

Draft files may be visible from `main`, but they are unsupported until Release 2
is published and assigned to a channel. Development and interoperability tests
use local bundles or an explicitly labelled preview origin; they do not imply
production publication.

## Operational decisions still required

The following values must be supplied by ION governance or operations before
the production manifest is finalized:

- canonical production and non-production `networkId` values;
- manifest `publisher.domain`;
- DeDi records and lookup URLs for bundle and manifest verification keys;
- production key custody and signing procedure;
- `effectiveFrom` and optional `effectiveUntil` timestamps;
- manifest cache and OPA refresh guidance for NPs; and
- emergency response and revocation procedure.

These are unresolved values, not permission to invent placeholders in a
production artifact.

## Superseded assumptions

`docs/ION_ONIX_Conditional_Policy.md` assumed root policy placement, pack-level
inputs, direct loading of all local files, a public `deny` set, and an older
error shape. Release 2 retains its useful conditional-rule examples only as
candidate inputs. Current ONIX behavior and this architecture govern actual
implementation.
