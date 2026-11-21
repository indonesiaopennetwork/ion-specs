# ION Release 1

> **Status: DRAFT — publication pending.**

Release 1 is the first versioned bundle of the ION Network Specification. It
defines the ION API additions, common attribute packs, Trade and Logistics
extensions, reference flows, errors, and pinned Beckn dependencies included in
this release.

The release remains mutable while [`release.yaml`](release.yaml) has
`status: draft`. Publication assigns it to the `next` channel and makes every
file in this directory immutable. Promotion to `current` is a separate Council
decision after the stabilization period.

## Implementation maturity

Validation and implementation maturity are separate signals. `validated` in the
manifest means the release artifacts pass their structural, reference, registry,
and connection gates; it does not by itself claim production experience.

| Area or profile | Maturity | Adoption guidance |
|---|---|---|
| Trade — Storefront | Implementation-ready | Primary Release 1 starting point; it has the most complete transaction coverage, examples, variants, and guidance. |
| Other Trade profiles | Reference | Validated reference profiles with narrower implementation coverage; adopt after establishing Storefront where applicable. |
| Logistics | Preview | Evaluation and interoperability testing only; not recommended for production use in Release 1. |

Release 1 Logistics is normative and validation-complete, but it has not received
sufficient implementation and interoperability testing to be considered battle
ready. Because a published release is immutable, any normative refinements found
during evaluation will be made in Release 2.

## Release contents

### API contracts

- [`schema/core/api/v2.0.0/ion-beckn.yaml`](schema/core/api/v2.0.0/ion-beckn.yaml)
  is the ION-maintained Beckn Protocol 2.0.0 contract used by this release.
- [`schema/core/api/v2.0.0/ion-additional.yaml`](schema/core/api/v2.0.0/ion-additional.yaml)
  defines ION endpoints that are not part of the Beckn contract. Release 1 adds
  settlement reconciliation through `/reconcile` and `/on_reconcile`.
- Order grievances use Beckn's `/support` and `/on_support` endpoints. The
  `Support.supportAttributes` field carries an `IONGrievance` event.

Implementations use the two API documents above together with the applicable
standalone attribute packs.

### Common attribute packs

[`schema/common/`](schema/common/) contains eight reusable v1 packs:

- `Address`
- `BusinessRegistration`
- `Grievance`
- `IdentifiableLocation`
- `IONParticipant`
- `Payment`
- `Settlement`
- `Tax`

### Trade

[`schema/extension/trade/`](schema/extension/trade/) contains ten v1 packs:

- `TradeCommitment`
- `TradeConsideration`
- `TradeContract`
- `TradeOffer`
- `TradeParticipant`
- `TradePerformance`
- `TradePerformanceStates`
- `TradeProvider`
- `TradeResource`
- `TradeSettlement`

[`flows/trade/`](flows/trade/) provides seven v1 reference patterns:
Storefront, Made-to-Order, Live Commerce, Digital Goods, Business Procurement,
Marketplace In-house, and Marketplace Listed. It also includes the
During-Transaction and Cancellation v1 variant families. Each flow declares
the schema packs, state machines, and policies it requires.

### Logistics

[`schema/extension/logistics/`](schema/extension/logistics/) contains nine v1
packs:

- `LogisticsCommitment`
- `LogisticsConsideration`
- `LogisticsContract`
- `LogisticsOffer`
- `LogisticsParticipant`
- `LogisticsPerformance`
- `LogisticsProvider`
- `LogisticsResource`
- `LogisticsTracking`

[`flows/logistics/`](flows/logistics/) provides six base transaction patterns,
nine included or scoped variant families, and the shared
`LogisticsPerformanceStates` v1 execution-state registry.

### Errors and policies

[`errors/`](errors/) contains 10 Trade errors and 30 Logistics errors.
`trade.yaml` and `logistics.yaml` are the authoritative sector sources;
`registry.json` is their generated combined index.

Policies have an independent governance lifecycle and are not copied into the
release. Flow and error documents refer to stable `ion://policy/...` IRIs in the
shared registry published at
[`https://schema.ion.id/policies/registry.json`](https://schema.ion.id/policies/registry.json).

### Vendored dependencies

[`schema/vendored/beckn/`](schema/vendored/beckn/) contains the complete pinned
Beckn dependency closure needed to resolve Release 1 without network access.
Dependency repositories, commits, transformations, licenses, and checksums are
recorded in [`release.yaml`](release.yaml) and [`NOTICES.md`](NOTICES.md). The
upstream provenance and ION transformations for the maintained protocol contract
are recorded under `maintainedArtifacts`; Release 1 exposes only the maintained
`schema/core/api/v2.0.0/ion-beckn.yaml` protocol URL.

## ION protocol changes

The ION-maintained Beckn contract includes these Release 1 changes from its
upstream baseline:

- corrected the `DiscoverAction.matchType` default and the `/catalog/publish`
  offer-validity examples;
- made asynchronous callback envelopes carry exactly one of `message` or
  `error`;
- added optional `Support.supportAttributes` for network-defined support data;
  and
- added `TrackingRequest` to `TrackAction`, keeping the live `Tracking` handle
  on `OnTrackAction`.

[`NOTICES.md`](NOTICES.md) records the exact provenance and modification history.

## Scope

The authoritative scope and validation state are defined by
[`release.yaml`](release.yaml). Trade, Logistics, their common dependencies,
flows, and errors are validated. Hospitality and Finance are excluded. The
standalone core API contracts, `ion-beckn.yaml` and `ion-additional.yaml`, have completed review and
are validated for Release 1.

The contents of this directory define the release boundary. Material elsewhere
in the repository is not part of Release 1 unless a release artifact explicitly
references it, as with the shared policy registry.

## Public URLs

After publication, every file maps to a permanent URL by removing the
repository-only `releases/` path segment:

```text
Repository: releases/release1/<path>
Public URL: https://schema.ion.id/release1/<path>
```

For example:

```text
https://schema.ion.id/release1/schema/extension/trade/TradeResource/v1/attributes.yaml
```

Schema `$ref` values use these absolute, release-qualified URLs. JSON-LD
semantic IRIs identify concepts and may retain their stable Beckn or NFH
namespaces; they are not retrieval dependencies.

## Directory layout

```text
release1/
  release.yaml              Release scope, state, provenance, and checksums
  NOTICES.md                Dependency attribution and modifications
  schema/
    core/                   ION-maintained API contracts
    common/                 Cross-sector ION attribute packs
    extension/trade/        Trade attribute packs
    extension/logistics/    Logistics attribute packs
    vendored/beckn/         Pinned Beckn dependencies and licenses
  flows/
    trade/                  Trade reference patterns and variants
    logistics/              Logistics patterns, variants, and state machines
  errors/                   Sector error sources and generated registry
```

## Validation

Run the complete Release 1 gate from the repository root:

```bash
ruby tools/release/validate_release.rb releases/release1
```

This is also the CI entry point. It runs the release-tool tests and verifies the
manifest, scope, generated registries, artifact checksums, offline references,
public-path mapping, and Trade and Logistics connections.

Before publication, run the stricter publication gate:

```bash
ruby tools/release/validate_release.rb --publication releases/release1
```

The publication form is expected to fail while the manifest remains a draft.
After the release is merged to `main` and deployed, verify the public origin:

```bash
ruby tools/release/validate_deployed_urls.rb releases/release1
```

For tooling details, see [`tools/release/README.md`](../../tools/release/README.md).

## Release policy

- [Release Architecture](../../docs/ION_Release_Architecture.md) defines the
  bundle structure, permanent URL scheme, and immutability rules.
- [Release Channel Policy](../../docs/ION_Release_Channel_Policy.md) defines
  publication into `next`, stabilization, promotion to `current`, and LTS.
