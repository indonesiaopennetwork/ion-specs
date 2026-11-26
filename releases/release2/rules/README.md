# ION Release 2 executable rules

**Status:** Validation pending — packaging instrumentation complete

This directory is the release-owned source and publication area for ION Rego
business rules evaluated by the ONIX OPA Policy Checker. It is distinct from
the independently governed shared policy terms under the repository root
`policies/` directory.

The current scaffold contains no business rule. Its public query always returns
a valid result with an empty violation array so the authoring, testing, and
toolchain contract can be proven before normative rules are added.

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
  registry.json            Generated rule inventory; currently empty
  bundles/                 Canonical test-signed draft bundle and public key
```

`registry.json` is generated deterministically from rule metadata and protected
by a freshness check. The current canonical bundle is test-signed for repository
and ONIX integration work; it is not the production publication signature. The
network-policy manifest is introduced by a later implementation phase.

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
freshness, formatting, strict compilation, unit tests, and the exact public
result for representative Trade and Logistics inputs. Refresh the generated
registry explicitly with:

```bash
ruby tools/rego/generate_registry.rb --write releases/release2
```

## Current limitations

- No ION business rule is implemented yet.
- The generated registry is empty until the first substantive rule is added.
- The committed bundle carries only a test signature and is not publishable.
- No private signing key or network-policy manifest belongs in this release
  tree.
- The rules area is not validated and is not ready for NP adoption.

See `docs/internal/rego/` for the governing architecture and phased plan.
