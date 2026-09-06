# Release 1 policy terms

Release 1 includes 67 policy terms that were classified as either Trade or
cross-sector in the working registry: 28 Trade terms and 39 cross-sector terms.
The source YAML documents are authoritative; [`registry.json`](registry.json) is
a deterministic release-local index generated from them.

Policy IRIs such as `ion://policy/...` are stable semantic identifiers. They do
not change to `schema.ion.id` URLs when vendored into a release.

The remaining working policy sources outside this directory are not part of
Release 1. Regenerate and check this registry with:

```bash
ruby tools/release/generate_release_registries.rb --write releases/release1
ruby tools/release/generate_release_registries.rb releases/release1
```
