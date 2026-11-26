# ION Network Specification

[ION](https://ion.id) is an open digital-commerce network for Indonesia.

The ION Network Specification defines the technical contracts for participating
in the network and is based on Beckn Protocol 2.0.0.

## Notice
The vendored beckn.yaml has now been replaced by a ion-beckn.yaml. This requires a config change and ONIX will fail without it. Please refer to this [note for details](./docs/notes/ion-beckn-yaml-vs-beckn-yaml.md).

## Releases

| Lifecycle position | Release | Current state |
|---|---|---|
| LTS | None | No releases are currently under long-term support. |
| Current | [Release 1](releases/release1/README.md) | Published, immutable, and recommended for new Storefront implementations. |
| Next | None | No newer published release is undergoing stabilization. |
| Draft | [Release 2](releases/release2/README.md) | Active mutable draft derived from the Release 1 baseline. |

### Release 1 (`current`)

Release 1 currently contains the standalone Trade schema packs, the common packs
they require, the settlement reconciliation API, the scoped Storefront,
Made-to-Order, Live Commerce, Digital Goods, Business Procurement, Marketplace
In-house, and Marketplace Listed flows and connected registries, the ION API
additions, an ION-maintained Beckn protocol contract, and pinned vendored Beckn
schema dependencies. Storefront is the primary, implementation-ready Trade
profile and the recommended starting point; the other Trade profiles are
validated references with narrower implementation coverage.
Release 1 also includes the independently validated `LogisticsResource`,
`LogisticsProvider`, `LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`, `LogisticsConsideration`, `LogisticsContract`, `LogisticsPerformance`, and `LogisticsTracking` v1 packs, plus six reviewed patterns, nine included/scoped variants, the validated `LogisticsPerformanceStates` v1 flow registry, and 30 connected Logistics errors. Release 1 was published directly as the inaugural `current` release on 21 November 2026. Logistics is
validation-complete but has `preview` implementation maturity: it is intended
for evaluation and interoperability testing, not Release 1 production adoption.

- [`releases/release1/release.yaml`](releases/release1/release.yaml) — scope,
  dependency provenance, checksums, and publication state.
- [`releases/release1/README.md`](releases/release1/README.md) — release-specific
  contents and validation commands.
- [`releases/release1/schema/extension/trade/`](releases/release1/schema/extension/trade/) —
  nine validated Trade packs.
- [`releases/release1/schema/extension/logistics/LogisticsResource/v1/`](releases/release1/schema/extension/logistics/LogisticsResource/v1/) —
  the migrated Logistics cargo-resource pack.
- [`releases/release1/schema/extension/logistics/LogisticsProvider/v1/`](releases/release1/schema/extension/logistics/LogisticsProvider/v1/) —
  the migrated Logistics provider-capability pack.
- [`releases/release1/schema/extension/logistics/LogisticsParticipant/v1/`](releases/release1/schema/extension/logistics/LogisticsParticipant/v1/) —
  the migrated Logistics participant-role and licence pack.
- [`releases/release1/schema/extension/logistics/LogisticsOffer/v1/`](releases/release1/schema/extension/logistics/LogisticsOffer/v1/) —
  the migrated Logistics service and rate-card pack.
- [`releases/release1/schema/extension/logistics/LogisticsCommitment/v1/`](releases/release1/schema/extension/logistics/LogisticsCommitment/v1/) —
  the migrated Logistics booking-allocation pack.
- [`releases/release1/schema/extension/logistics/LogisticsConsideration/v1/`](releases/release1/schema/extension/logistics/LogisticsConsideration/v1/) —
  the migrated Logistics monetary-component pack.
- [`releases/release1/schema/extension/logistics/LogisticsContract/v1/`](releases/release1/schema/extension/logistics/LogisticsContract/v1/) —
  the migrated Logistics agreement and compliance pack.
- [`releases/release1/schema/extension/logistics/LogisticsPerformance/v1/`](releases/release1/schema/extension/logistics/LogisticsPerformance/v1/) —
  the migrated Logistics durable execution pack.
- [`releases/release1/schema/extension/logistics/LogisticsTracking/v1/`](releases/release1/schema/extension/logistics/LogisticsTracking/v1/) —
  the migrated Logistics live-tracking pack.
- [`releases/release1/flows/logistics/`](releases/release1/flows/logistics/) —
  the reviewed Logistics patterns, variants, and shared execution-state registry.
- [`releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml`](releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml) —
  the ION-maintained Beckn Protocol contract used by Release 1.
- [`releases/release1/schema/core/api/v2.0.0/ion-additional.yaml`](releases/release1/schema/core/api/v2.0.0/ion-additional.yaml) —
  ION endpoints that Beckn does not define, starting with settlement
  reconciliation (`/reconcile`, `/on_reconcile`).
- [`releases/release1/schema/common/`](releases/release1/schema/common/) — Address, Business
  Registration, Payment, and Tax packs required by Trade, the Settlement
  pack used by reconciliation, the Grievance pack used by `/support` and
  `/on_support`, plus the reusable IdentifiableLocation wrapper introduced for
  Logistics.
- [`releases/release1/schema/vendored/beckn/`](releases/release1/schema/vendored/beckn/) —
  pinned upstream schema dependencies and their license texts.
- [`releases/release1/flows/trade/`](releases/release1/flows/trade/) — the
  seven validated Trade v1 reference flows and the reviewed During-Transaction
  v1 and Cancellation v1 variants.
- [`releases/release1/flows/logistics/`](releases/release1/flows/logistics/) —
  six Logistics v1 patterns, nine included or scoped variants, and their shared
  state-machine registry; six additional variants are explicitly deferred.
- [`policies/registry.json`](policies/registry.json) — 89 shared policy terms
  (28 Trade, 39 cross-sector, and 22 draft Logistics terms) governed outside the
  integer release cycle.
- [`releases/release1/errors/registry.json`](releases/release1/errors/registry.json)
  — 40 connected errors: 10 Trade and 30 Logistics.

Release 1 excludes Hospitality and Finance. Logistics is
`validated`: its included schemas, flows, state machines, policy connections,
errors, and examples have passed the Phase 8 closure gate. The repository does
not maintain separate editable `schema/`, `flows/`, `errors/`, or executable
`rules/` trees at its root. Shared policy terms are the exception: their
canonical sources and generated registry live in root `policies/` and evolve
independently of integer releases. Executable rules tied to a wire contract
belong in that release's `rules/` area.

## Repository structure

```text
policies/                         Shared policy sources and registry

releases/
  release1/                    Published immutable release bundle
    release.yaml
    schema/
      core/api/v2.0.0/ion-beckn.yaml       ION-maintained Beckn contract
      core/api/v2.0.0/ion-additional.yaml ION endpoints Beckn does not define
      common/                  Validated common packs used by Trade
      extension/trade/         Validated Trade packs
      extension/logistics/     Validated Logistics packs
      vendored/beckn/schemas/  Pinned upstream schema dependencies
    flows/trade/               Seven flows plus reviewed Trade variants
    flows/logistics/           Validated Logistics patterns and variants
    errors/                    Included Trade and Logistics errors and registry

  release2/                    Active mutable draft for subsequent changes
    release.yaml               Draft scope, provenance, and checksums
    schema/                    Release 2 API, packs, and vendored dependencies
    flows/                     Release 2 Trade and Logistics flows
    errors/                    Release 2 error sources and registry
    rules/                     Release 2 executable-rules scaffold

docs/                          Architecture and contributor documentation
tools/release/                 Release construction and validation tools
```

Each draft release is developed within its own `releases/releaseN/` directory.
Once published, that directory is permanent and immutable. Schema document
references use release-qualified public URLs such as:

```text
https://schema.ion.id/release1/schema/extension/trade/TradeResource/v1/attributes.yaml
https://schema.ion.id/release1/schema/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml
```

These URLs mirror repository paths below `releases/`; the repository-only
top-level `releases/` segment is omitted from the public URL. JSON-LD semantic
IRIs may continue to use their stable vocabulary namespaces; they are not
dependency locations.

Policy documents use their independent root namespace, for example
`https://schema.ion.id/policies/return/v1/standard-7d-sellerpays.yaml`.

## Documentation

| Document | What it covers |
|---|---|
| [Release Architecture](docs/ION_Release_Architecture.md) | How specifications are packaged into immutable releases, addressed through public URLs, and kept independently verifiable. |
| [Release Channel Policy](docs/ION_Release_Channel_Policy.md) | How releases enter `next` or the inaugural `current` exception, advance through channels, and receive guaranteed LTS after leaving `current`. |
| [Entity Hierarchy Model](docs/ION_Entity_Hierarchy_Model.md) | How participants, roles, sectors, and business classifications fit together across ION. |
| [Resource Categories](docs/ION_Resource_Categories.md) | The draft cross-sector taxonomy and machine-readable codes used to classify products and services. |
| [Transport and HTTP Signing](docs/ION_Transport_and_Signing.md) | The request/callback model, HTTP signatures, acknowledgements, and transport-level errors. |
| [Bu Sari Joins ION](docs/ION_Bu_Sari_Wizard.md) | A plain-language walkthrough of the network for business owners, product teams, regulators, and other non-protocol readers. |
| [Bu Sari's Complete ION Journey](docs/ION_Bu_Sari_Complete_Journey.md) | The developer companion, with API calls, JSON payloads, and field-level details for an end-to-end seller journey. |

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), the
[`ION Schema Style Guide`](docs/ION_Schema_Style_Guide.md), and the
[`ION Schema Design Guide`](docs/ION_Schema_Design_Guide.md). Treat published
schema names, properties, JSON-LD IRIs, policy IRIs, and error codes as public
interfaces.

Architecture and migration decisions are documented in:

- [`docs/ION_Release_Architecture.md`](docs/ION_Release_Architecture.md)
- [`docs/internal/ION_Release1_Migration_Inventory.md`](docs/internal/ION_Release1_Migration_Inventory.md)

## License

ION-owned repository content is covered by [`LICENSE.md`](LICENSE.md). Vendored
dependencies retain their upstream licenses and attribution under each release's
`schema/vendored/` directory and `NOTICES.md`.
