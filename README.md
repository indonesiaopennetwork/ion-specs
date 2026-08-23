# ION Network Specification

ION is an open digital-commerce network specification for Indonesia, built on
Beckn Protocol 2.0.0.

> **Release 1 status: DRAFT.** Release 1 is limited to the standalone Trade
> schema packs, the common packs they require, the scoped Storefront,
> Made-to-Order, Live Commerce, Digital Goods, Business Procurement,
> Marketplace In-house, and Marketplace Listed flows and connected registries,
> and pinned vendored Beckn dependencies. It is not
> permanent or supported until its manifest is marked `published` on `main`.

## Release 1 entry points

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

Release 1 does not publish `ion.yaml`, Logistics, Hospitality, or Finance. Their
files under `schema/`, `flows/`, `policies/`, and `errors/` are work in progress
for a future release unless they are explicitly copied into a validated release
bundle.

## Repository structure

```text
releases/
  release1/                    Draft permanent release bundle
    release.yaml
    schema/
      core/                    Reserved; ion.yaml excluded in Release 1
      common/                  Validated common packs used by Trade
      extension/trade/         Validated Trade packs
      vendored/beckn/          Pinned release-local dependencies
    flows/trade/               Seven flows plus reviewed Trade variants
    policies/                  Included policy sources and registry
    errors/                    Included Trade errors and registry

schema/
  core/v2/api/v2.0.0/ion.yaml  Excluded work-in-progress aggregate
  extensions/                  Unreleased sector and common source work

flows/                         Source flow material under migration
policies/                      Source policy material under migration
errors/                        Source error material under migration
docs/                          Architecture and contributor documentation
tools/release/                 Release construction and validation tools
```

Every published release remains permanently under `releases/releaseN/`. Schema
document references use release-qualified public URLs such as:

```text
https://schema.ion.id/releases/release1/schema/extension/trade/TradeResource/v1/attributes.yaml
https://schema.ion.id/releases/release1/schema/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml
```

These URLs mirror repository paths below `releases/`. JSON-LD semantic IRIs may
continue to use their stable vocabulary namespaces; they are not dependency
locations.

## Validate Release 1 locally

The same command used by CI can be run manually from the repository root:

```bash
ruby tools/release/validate_release.rb releases/release1
```

It runs release-tool tests, manifest and scope checks, registry freshness,
complete artifact checksum verification, offline `$ref` resolution, and Trade
connection checks.

To run the stricter publication gate:

```bash
ruby tools/release/validate_release.rb --publication releases/release1
```

That command intentionally fails while Release 1 is a draft. In GitHub Actions,
the **Release validation** workflow runs for relevant pull requests and `main`
changes and can also be started manually. Its manual form optionally runs the
publication gate.

For the deeper schema-pack consistency validation maintained in the ION testbed:

```bash
cd /path/to/ion-testbed/tools/schemav2validator
go run ./cmd/schemav2validator schema-dir /path/to/ion-specs/releases/release1/schema/extension/trade/
```

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
