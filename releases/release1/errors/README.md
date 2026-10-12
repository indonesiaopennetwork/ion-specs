# Release 1 Trade errors

Release 1 includes 10 Trade errors whose referenced schemas and flows are present
in the release and whose policy references resolve against the shared root
[policy registry](../../../policies/registry.json). [`trade.yaml`](trade.yaml) is
the authoritative source and [`registry.json`](registry.json) is its deterministic
release-local index.

Seven other working Trade errors were deliberately omitted because they refer to
the excluded `live-commerce`, `digital-goods`, or `returns` flows. They can be
reviewed with those flows for a future integer release.

Regenerate and check the registry with:

```bash
ruby tools/release/generate_error_registry.rb --write releases/release1
ruby tools/release/generate_error_registry.rb releases/release1
```
