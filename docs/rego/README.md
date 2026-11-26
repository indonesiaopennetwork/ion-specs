# ION Rego documentation

These documents describe the durable architecture, authoring conventions, and
ONIX operator configuration for ION-authored executable rules.

- [`ION_Rego_Architecture.md`](ION_Rego_Architecture.md) explains release
  ownership, runtime composition, compatibility, packaging, signing, and
  publication.
- [`ION_Rego_Authoring_Guide.md`](ION_Rego_Authoring_Guide.md) defines source
  layout, packages, rule metadata, diagnostics, tests, and review requirements.
- [`ION_Rego_Rule_Creation_Workflow.md`](ION_Rego_Rule_Creation_Workflow.md)
  is the step-by-step human workflow for creating, testing, bundling, and
  publishing a rule, using `ION-R2-COM-0001` as the example.
- [`ONIX_Rego_Integration.md`](ONIX_Rego_Integration.md) explains how an NP
  configures ONIX to load, verify, and test a release-qualified ION bundle.

Release-specific `rules/README.md` files remain authoritative for the exact
bundle name, query, verification material, supported rules, and maturity of
that release. Internal implementation sequencing and tooling work records stay
under [`../internal/rego/`](../internal/rego/).
