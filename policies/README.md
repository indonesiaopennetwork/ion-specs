# ION policy terms

This repository-level registry contains 89 policy terms: 28 Trade, 39
cross-sector, and 22 draft Logistics terms. Policies are governed independently
of integer specification releases. The source YAML documents are authoritative;
[`registry.json`](registry.json) is their deterministic shared index.

The Logistics terms remain `draft`. Their presence in the registry makes their
identifiers reviewable and resolvable; it does not represent Council
ratification or assign an effective date.

Policy IRIs such as `ion://policy/...` are stable semantic identifiers. Policy
documents are published at stable root URLs such as
`https://schema.ion.id/policies/return/v1/standard-7d-sellerpays.yaml`; document
URLs and semantic IRIs serve different purposes.

Ratified policy versions remain stable. Additions, replacements, and
deprecations use the policy document's own version and lifecycle fields rather
than an integer release number. Existing releases therefore continue to refer to
the same semantic IRIs while the policy registry evolves under Council policy
governance.

Regenerate and check the registry from the repository root with:

```bash
ruby tools/policies/generate_registry.rb --write
ruby tools/policies/generate_registry.rb
```
