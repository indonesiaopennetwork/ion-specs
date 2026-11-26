# ION Release 2 executable rules

**Status:** Validation pending — scaffold only

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
  bundles/                 Generated production bundles from Phase 4 onward
```

`registry.json`, the signed bundle, and network-policy manifest are introduced
by later implementation phases after their generators and freshness validators
exist.

## Validate the scaffold

OPA CLI `1.15.2` is required. From the repository root:

```bash
ruby tools/rego/check_toolchain.rb
ruby tools/rego/validate_scaffold.rb releases/release2
```

Pass `--opa /absolute/path/to/opa` to either command when the pinned CLI is not
on `PATH`.

The scaffold validation is read-only. It checks formatting, strict compilation,
unit tests, and the exact public result for representative Trade and Logistics
inputs.

## Current limitations

- No ION business rule is implemented yet.
- No rule registry or bundle is generated yet.
- No signing key or network-policy manifest belongs in this release tree yet.
- The rules area is not validated and is not ready for NP adoption.

See `docs/internal/rego/` for the governing architecture and phased plan.
