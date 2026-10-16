# Release 1 errors

Release 1 includes 10 Trade errors whose referenced schemas and flows are present
in the release and whose policy references resolve against the shared root
[policy registry](../../../policies/registry.json). It also includes 30
individually reviewed Logistics errors whose schema pointers, callbacks, and
flow or policy targets are connected to migrated Release 1 artifacts.

[`trade.yaml`](trade.yaml) and [`logistics.yaml`](logistics.yaml) are the
authoritative sector sources. [`registry.json`](registry.json) is their combined,
deterministic release-local index.

Seven other working Trade errors were deliberately omitted because they refer to
the excluded `live-commerce`, `digital-goods`, or `returns` flows. They can be
reviewed with those flows for a future integer release.

The Logistics migration reviewed all 97 legacy codes. Sixty-seven were deferred
because they depend on unavailable branches or rules, duplicate cross-sector
errors, or describe informational state rather than an error. The exact
disposition is recorded in
[`../../../tools/release/release1-logistics-error-map.yaml`](../../../tools/release/release1-logistics-error-map.yaml)
and the internal migration ledger.

Regenerate and check the registry with:

```bash
ruby tools/release/generate_error_registry.rb --write releases/release1
ruby tools/release/generate_error_registry.rb releases/release1
ruby tools/release/validate_logistics_errors.rb releases/release1
```
