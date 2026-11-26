# ION Release 2 executable rules

**Status:** Draft — initial rules and direct ONIX integration validated

This directory is the release-owned source and publication area for ION Rego
business rules evaluated by the ONIX OPA Policy Checker. It is distinct from
the independently governed shared policy terms under the repository root
`policies/` directory.

The initial vertical slice contains three active business rules. Inputs to which
none applies still return a valid result with an empty violation array.

## Public contract

```text
Query: data.ion.release2.result
Input: complete Beckn JSON message body
Result: {"valid": <boolean>, "violations": <array>}
```

ONIX must run schema validation before policy evaluation. The Rego policy sees
the JSON body, including `input.context` and `input.message`; it does not see
HTTP headers, signature state, or router metadata.

## Layout

```text
rules/
  rego/ion/release2/       Production Rego modules
    common/                Cross-sector rules
    trade/                 Trade rules
    logistics/             Logistics rules
  tests/                   Rego unit tests and full-envelope smoke inputs
  data/data.json           Normative runtime data; currently empty
  registry.json            Generated three-rule inventory
  bundles/                 Canonical signed bundle and public key
```

`registry.json` is generated deterministically from rule metadata and protected
by a freshness check. The canonical bundle and public key are generated and
published together. An ephemeral private key signs each build and is destroyed;
it is never committed. The same artifact pair is used for testing and, once
Release 2 is published, production. NPs select this release explicitly through
direct ONIX `type: bundle` configuration.

## Initial active rules

| Rule ID | Requirement | Applicable actions | Schema source |
|---|---|---|---|
| `ION-R2-COM-0001` | Every settlement with payment status `PAID` declares `paidAt`. | `confirm`, `on_confirm`, `status`, `on_status` | `schema/common/Payment/v1/attributes.yaml` |
| `ION-R2-TRD-0001` | A Trade provider marked `TEMPORARILY_CLOSED` declares the closure end in `until`. | `catalog/publish`, `on_discover` | `schema/extension/trade/TradeProvider/v1/attributes.yaml` |
| `ION-R2-TRD-0002` | A Trade provider using `CENTRAL` invoicing declares its issuing `entityId`. | `catalog/publish`, `on_discover` | `schema/extension/trade/TradeProvider/v1/attributes.yaml` |

These are cross-field, action-gated requirements. Their target fields remain
optional in JSON Schema by design, so no schema constraint was removed or
weakened. Both valid and deliberately rule-invalid attribute objects pass their
Release 2 packs before Rego is evaluated. All three use
`POL_ELIGIBILITY_NOT_MET`: the message is structurally valid but does not meet
an activated ION network-policy precondition.

The rules are intentionally limited to the complete-message locations and
actions listed above. They do not infer applicability from similarly named
fields elsewhere in a message.

## Validate the scaffold

OPA CLI `1.15.2` is required. From the repository root:

```bash
ruby tools/rego/check_toolchain.rb
ruby tools/rego/validate_sources.rb releases/release2
ruby tools/rego/generate_registry.rb releases/release2
ruby tools/rego/validate_scaffold.rb releases/release2
ruby tools/rego/verify_bundle.rb releases/release2
```

Pass `--opa /absolute/path/to/opa` to either command when the pinned CLI is not
on `PATH`.

The checks are read-only. They enforce source layout and metadata, registry
freshness, formatting, strict compilation, unit tests, exact valid and invalid
fixture results, and continued acceptance of every existing Release 2 reference
flow example. Refresh the generated registry explicitly with:

```bash
ruby tools/rego/generate_registry.rb --write releases/release2
```

Run the separate optional ONIX integration when changing rules, bundle tooling,
or the ONIX compatibility pin. It is intentionally not part of the normal
release gate:

```bash
ruby tools/rego/test_onix_integration.rb --onix-root /path/to/pinned/beckn-onix
```

See [`../../../docs/rego/ONIX_Rego_Integration.md`](../../../docs/rego/ONIX_Rego_Integration.md)
for the operator configuration and `tools/rego/README.md` for author
prerequisites. Rule authors can follow the file-by-file
[`rule creation workflow`](../../../docs/rego/ION_Rego_Rule_Creation_Workflow.md)
from requirement approval through bundle and publication handoff.

## Current limitations

- No private signing key belongs in this release tree.
- The bundle and public key are publishable artifacts only when the enclosing
  Release 2 publication gate passes.
- This is a deliberately small starter set. The initial Trade/Storefront
  candidate inventory is documented; broader Trade implementation and the
  Logistics inventory remain future work.
- Direct bundle loading is proven only against the pinned ONIX revision;
  deployed `schema.ion.id` retrieval and NP adoption are publication work
  because those public rule URLs do not yet exist.

See `docs/rego/` for the durable architecture and authoring guidance, and
`docs/internal/rego/` for the delivery design, tooling record, and candidate
rule inventory.
