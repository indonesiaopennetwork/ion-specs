# ION Release 1

> **Status: DRAFT — not published or assigned to a release channel.**

This directory is the working envelope for the first permanent integer release of
the ION Trade specification and the Logistics material under independent review
for this draft. It is mutable while `release.yaml` has
`status: draft`. Its contents and public URLs carry no compatibility guarantee
until the ION Council approves the release and changes its status to `published`.
Publication will assign Release 1 to the `next` channel and begin its operational
stabilization period; it will not automatically make Release 1 `current`.

## Current state

Migration Phases 3 and 4 moved all nine Trade packs and the four common packs
required by Trade into this draft, then vendored the Beckn dependencies at
immutable upstream commits. The Beckn Protocol contract now has an
ION-maintained core copy, while the immutable vendored copy remains available
at its existing URL. Active schema references use Release 1 public URLs, and the
graph resolves offline.

Phase 5 validated the standalone Trade packs and the four common packs required by
Trade, including their JSON-LD documents and all 17 example objects. Phase 6
explicitly excluded the unreconciled `ion.yaml` aggregate and the Logistics,
Hospitality, and Finance sectors from Release 1. On 16 October 2026, Logistics
was reopened as `review-required` so its legacy material can be migrated and
validated independently. Phase 4 now includes the complete `LogisticsResource`,
`LogisticsProvider`, `LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`, `LogisticsConsideration`, `LogisticsContract`, `LogisticsPerformance`, and `LogisticsTracking` v1 vertical slices and the reusable common
`IdentifiableLocation` v1 wrapper. The validated `LogisticsPerformanceStates`
v1 registry completed Phase 4 and now lives under the Logistics flow tree
because it describes execution graphs rather than message shape. Logistics
Phase 5 migrated 22 reviewed baseline policy terms into the
shared root registry as drafts, mapped 10 obsolete legacy IRIs to current terms,
and explicitly deferred 27 unsourced or agreement-specific strings. Logistics
Phase 6 migrated all six patterns and nine included/scoped variants after
reviewing all fifteen legacy variants; six variants remain explicitly deferred.
Logistics Phase 7 reviewed all 97 legacy errors, migrated 30 connected errors,
and explicitly deferred 67 entries without valid Release 1 targets or error
semantics. Logistics Phase 8 then passed the complete schema-directory validator,
all nine example-object validations, source-disposition checks, connection
validators, and the complete Release 1 gate. Logistics is now `validated`.
`ion.yaml`,
Hospitality, and Finance remain excluded, and the repository does not retain
separate root-level normative copies.

Phase 8A added the independently reviewable connected Trade baseline:
Storefront v1 and 8 Trade errors whose schema and flow targets are present in
this release. Its policy references resolve against the shared root policy
registry, which is governed outside the integer release cycle. Phase 8B added the
Made-to-Order v1 flow after reconciling its schema-pack names, category boundary,
MTO state-machine target, and concrete cancellation policy. Phase 8C added the
standard-action subset of Live Commerce v1 and restored its two release-local
errors, bringing the included error count to 10.
Phase 8D added the standard-action, target-free subset of Digital Goods v1 for
electronically delivered vouchers and subscriptions. Push-to-target, account
credit, and digital top-up transactions remain outside Release 1 because no
transaction-level delivery-target schema exists in Release 1.
Phase 8E added Business Procurement, Marketplace In-house, and Marketplace
Listed using the existing Release 1 schema packs. Cross-Border, Government,
Forward Auction, and Reverse Auction were reviewed and deferred because their
defining objects or state semantics are not available within the Trade release
boundary.
Phase 8F began variant migration with the During-Transaction v1 family. Six
sub-branches were included using existing Release 1 objects; four branches were
excluded for callback misuse, missing Contract lifecycle, non-Beckn escalation,
or Logistics dependencies.

ION endpoints that Beckn does not define live in one file,
`schema/core/api/v2.0.0/ion-additional.yaml`, which references the
ION-maintained `schema/core/api/v2.0.0/ion-beckn.yaml` contract. Release 1 adds the settlement reconciliation endpoints
(`/reconcile`, `/on_reconcile`) there, with their `IONSettlementReconciliation`
attribute pack at `schema/common/Settlement/v1`. This does not reintroduce the
`ion.yaml` aggregate.

## Protocol dependency

Release 1 uses this ION-maintained copy of the Beckn Protocol contract:

```text
schema/core/api/v2.0.0/ion-beckn.yaml
```

It was copied from Beckn's `api/v2.0.0/beckn.yaml` at commit
`df1ade0c6610d4160968177a706f32df680e4758` and receives ION fixes. The first
fix corrects `DiscoverAction.matchType.default` from `any` to the declared enum
value `ANY`; the second corrects the `/catalog/publish` example's offer validity
values to RFC 3339 date-times. The unmodified immutable vendored file remains at
`schema/vendored/beckn/api/v2.0.0/beckn.yaml` during the URL migration, but new
references use `ion-beckn.yaml`.

Release 1 does not publish `ion.yaml` or a merged `ion-full.yaml`. Its normative
ION-owned schemas currently present are the API additions under `schema/core/`,
the standalone packs under `schema/common/`, the packs under `schema/extension/trade/`, and the
individually reviewed Logistics packs under `schema/extension/logistics/`.
These currently comprise `LogisticsResource`, `LogisticsProvider`,
`LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`, and
`LogisticsConsideration`, `LogisticsContract`, `LogisticsPerformance`, and
`LogisticsTracking` v1. The standalone `LogisticsPerformanceStates` v1 registry
is flow metadata under `flows/logistics/state-machines/v1/`. Pinned
protocol and schema dependencies live under `schema/vendored/`;
the scoped `flows/` and `errors/` trees remain release-level peers. Policies are
resolved from the repository-level registry at
`https://schema.ion.id/policies/registry.json`.

```text
release1/
  schema/
    core/
    common/
    extension/
    vendored/
  flows/
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
ruby tools/policies/generate_registry.rb
ruby tools/release/generate_error_registry.rb releases/release1
ruby tools/release/validate_trade_connections.rb releases/release1
ruby tools/release/validate_logistics_errors.rb releases/release1
```

Or run the complete local gate, which includes those checks, tool tests, release
scope enforcement, the path map, generated registries, and vendored artifact
checksums. Publication expands the checksum inventory to every normative release
artifact:

```bash
ruby tools/release/validate_release.rb releases/release1
```

GitHub Actions uses the same command. The **Release validation** workflow can be
run manually and optionally includes the publication gate. After a push to
`main`, the workflow also verifies that every non-hidden Release 1 file is live
at `schema.ion.id` with the expected media type and exact repository bytes. The
same post-merge check can be run locally with:

```bash
ruby tools/release/validate_deployed_urls.rb releases/release1
```

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
`docs/internal/ION_Release1_Migration_Inventory.md` for the governing decision and migration
plan.
