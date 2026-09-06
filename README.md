# ION Network Specification

[ION](https://ion.id) is an open digital-commerce network for Indonesia.

The ION Network Specification defines the technical contracts for participating
in the network and is based on Beckn Protocol 2.0.0.

## Releases

| Lifecycle position | Release | Current state |
|---|---|---|
| LTS | None | No releases are currently under long-term support. |
| Current | None | No release is currently recommended for production integrations. |
| Next | None | No published release is currently undergoing stabilization. |
| Draft | [Release 1](releases/release1/README.md) | Mutable and not yet assigned to a release channel. |

### Release 1 (draft)

Release 1 is limited to the standalone Trade schema packs, the common packs they
require, the scoped Storefront, Made-to-Order, Live Commerce, Digital Goods,
Business Procurement, Marketplace In-house, and Marketplace Listed flows and
connected registries, and pinned vendored Beckn dependencies. It remains mutable
and unchannelled until the Council publishes it into the `next` channel on `main`.

- [`releases/release1/release.yaml`](releases/release1/release.yaml) — scope,
  dependency provenance, checksums, and publication state.
- [`releases/release1/README.md`](releases/release1/README.md) — release-specific
  contents and validation commands.
- [`releases/release1/schema/extension/trade/`](releases/release1/schema/extension/trade/) —
  nine validated Trade packs.
- [`releases/release1/schema/common/`](releases/release1/schema/common/) — Address, Business
  Registration, Payment, and Tax packs required by Trade.
- [`releases/release1/schema/vendored/beckn/`](releases/release1/schema/vendored/beckn/) —
  immutable upstream protocol and schema dependencies.
- [`releases/release1/flows/trade/`](releases/release1/flows/trade/) — the
  seven validated Trade v1 reference flows and the reviewed During-Transaction
  v1 variant.
- [`releases/release1/policies/registry.json`](releases/release1/policies/registry.json)
  — 67 included Trade and cross-sector policy terms.
- [`releases/release1/errors/registry.json`](releases/release1/errors/registry.json)
  — 10 Trade errors with release-local targets.

Release 1 excludes `ion.yaml`, Logistics, Hospitality, and Finance. The repository
does not maintain separate editable `schema/`, `flows/`, `policies/`, or `errors/`
trees at its root. Future normative work belongs in the draft directory for the
release that will publish it.

## Repository structure

```text
releases/
  release1/                    Draft release bundle
    release.yaml
    schema/
      core/                    Reserved; ion.yaml excluded in Release 1
      common/                  Validated common packs used by Trade
      extension/trade/         Validated Trade packs
      vendored/beckn/          Pinned release-local dependencies
    flows/trade/               Seven flows plus reviewed Trade variants
    policies/                  Included policy sources and registry
    errors/                    Included Trade errors and registry

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

## Documentation

| Document | What it covers |
|---|---|
| [Release Architecture](docs/ION_Release_Architecture.md) | How specifications are packaged into immutable releases, addressed through public URLs, and kept independently verifiable. |
| [Release Channel Policy](docs/ION_Release_Channel_Policy.md) | How drafts enter `next`, may advance to `current`, and receive guaranteed LTS after leaving `current`. |
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
- [`docs/ION_Release1_Migration_Inventory.md`](docs/ION_Release1_Migration_Inventory.md)

## License

ION-owned repository content is covered by [`LICENSE.md`](LICENSE.md). Vendored
dependencies retain their upstream licenses and attribution under each release's
`schema/vendored/` directory and `NOTICES.md`.
