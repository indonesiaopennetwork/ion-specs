# Policy tooling

Policies are maintained in the repository-level `policies/` tree independently
of integer specification releases.

`generate_registry.rb` parses every versioned policy YAML document, rejects
missing required fields and duplicate policy IRIs, and deterministically builds
`policies/registry.json`.

From the repository root, check the committed registry with:

```bash
ruby tools/policies/generate_registry.rb
```

After reviewing policy source changes, regenerate it with:

```bash
ruby tools/policies/generate_registry.rb --write
```

## Import reviewed legacy Logistics policies

`import_legacy_logistics.rb` reads the pinned legacy ION repository, selects
only the individually reviewed baseline Logistics terms, and normalizes them to
the current policy metadata model. Imported terms remain `draft`; the tool does
not invent Council ratification or effective dates. It previews by default:

```bash
ruby tools/policies/import_legacy_logistics.rb --source-root ../ion-specs-ion-launch
ruby tools/policies/import_legacy_logistics.rb --write --source-root ../ion-specs-ion-launch
```

The selection and bilingual display text are explicit in the tool so additions
require review. Enterprise/FWA examples and unsourced IRIs are intentionally not
imported.

`logistics-policy-migration-map.yaml` records the disposition of every policy
IRI found in the pinned legacy Logistics flows. Check registered targets with:

```bash
ruby tools/policies/validate_logistics_policy_map.rb
```

When the pinned legacy checkout is available, also prove that the inventory is
complete and still points at the expected source commit:

```bash
ruby tools/policies/validate_logistics_policy_map.rb --source-root ../ion-specs-ion-launch
```
