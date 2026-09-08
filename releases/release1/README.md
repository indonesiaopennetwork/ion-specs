# ION Release 1

> **Status: DRAFT — not published or assigned to a release channel.**

This directory is the working envelope for the first permanent integer release of
the ION Trade specification. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.
Publication will assign Release 1 to the `next` channel and begin its operational
stabilization period; it will not automatically make Release 1 `current`.


## Protocol dependency

Release 1 includes the vendored Beckn Protocol contract used by its schemas:

```text
schema/vendored/beckn/protocol/v2.0.0/beckn.yaml
```

Release 1 does not publish `ion.yaml` or a merged `ion-full.yaml`. Its normative
ION-owned schemas are the standalone packs under `schema/common/` and
`schema/extension/trade/`. Pinned dependencies live under `schema/vendored/`;
the scoped `flows/`, `policies/`, and `errors/` trees remain release-level peers.

```text
release1/
  schema/
    core/
    common/
    extension/
    vendored/
  flows/
  policies/
  errors/
```

## Planned public namespace

Files in this directory will map to:

```text
https://schema.ion.id/release1/<path>
```

For example, TradeResource is available at
`https://schema.ion.id/release1/schema/extension/trade/TradeResource/v1/attributes.yaml`.

Draft paths may be visible through the backing repository, but consumers must not
depend on them before publication.

## Validation

Validate the draft manifest:

```bash
ruby tools/release/validate_manifest.rb releases/release1/release.yaml
ruby tools/release/validate_offline_refs.rb releases/release1
ruby tools/release/generate_release_registries.rb releases/release1
ruby tools/release/validate_trade_connections.rb releases/release1
```

Or run the complete local gate, which includes those checks, tool tests, release
scope enforcement, the path map, generated registries, and complete release
artifact checksums:

```bash
ruby tools/release/validate_release.rb releases/release1
```

GitHub Actions uses the same command. The **Release validation** workflow can be
run manually and optionally includes the publication gate.

For the deeper Trade schema-pack consistency validation maintained in the ION
testbed:

```bash
cd /path/to/ion-testbed/tools/schemav2validator
go run ./cmd/schemav2validator schema-dir /path/to/ion-specs/releases/release1/schema/extension/trade/
```

Before the Council publishes Release 1 into `next`, run the complete publication
gate with:

```bash
ruby tools/release/validate_release.rb --publication releases/release1
```

This command intentionally fails while Release 1 remains a draft.

See `docs/ION_Release_Architecture.md` and
`docs/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
