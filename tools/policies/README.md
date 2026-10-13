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
