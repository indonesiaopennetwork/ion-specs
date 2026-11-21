# ION specification tools

Release construction, checksum recording, registry generation, and validation
tools live under [`release/`](release/). Start with
[`release/README.md`](release/README.md) and run the complete Release 1 gate from
the repository root:

```bash
ruby tools/release/validate_release.rb releases/release1
```

Policy registry generation and validation tools live under [`policies/`](policies/).

Integration guidance must be derived from the published API contracts, schema
packs, flows, profiles, policies, and error registries. Repository tooling must
not depend on unpublished contract material.
