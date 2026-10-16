# LogisticsProvider v1

LogisticsProvider describes the logistics capabilities of an organization that
publishes transport or storage services. It attaches to
`beckn:Provider.providerAttributes` during catalog discovery.

The organization is inspired by the separate Carrier, Operator, and Hub concepts
in Beckn Logistics. Those schemas are not copied or referenced because the
currently available Beckn Logistics artifacts are not aligned with the pinned
Release 1 core.

## Schema layers

| Schema | Purpose |
|---|---|
| `LogisticsProvider` | Geography-neutral roles, coverage, capabilities, hours, closures, fleet sourcing, hubs, and credentials. |
| `IONLogisticsProvider` | Composes Indonesian administrative coverage, `IONBusinessRegistration`, and Indonesian licence or membership credential types. |

## Main properties

| Property | Meaning |
|---|---|
| `providerRoles[]` | Carrier, forwarder, operator/aggregator, marketplace, 3PL/4PL, and warehouse roles. |
| `supportedPatterns[]` | Logistics transaction patterns supported by the provider. |
| `supportedTransportModes[]` | Available transport modes, distinct from individual vehicle types. |
| `serviceCoverage[]` | Pickup or delivery areas represented by geometry, location references, postal codes, radius, or Indonesian subdivisions. |
| `capabilities` | Cold-chain, dangerous-goods, and high-value handling capability. |
| `operatingHours[]`, `closures[]` | Recurring service windows and exceptional closure dates. |
| `fleetProfile` | Sources from which the provider obtains transport capacity. |
| `providerLocations[]` | Stable identifiers paired with unmodified vendored Beckn Locations. |
| `hubs[]` | Site capabilities linked to `providerLocations[]` by identifier. |
| `credentials[]` | Verifiable licences, certifications, and association memberships. |
| `businessRegistration` | Indonesian NIB, SIUP, and other business identity through the common pack. |

## Deliberate migration decisions

- Catalog version, publication, validity, changelog, delta, and rate-card fields
  are not Provider attributes. Core `Catalog.validity` owns catalog validity;
  other publication metadata remains deferred.
- The legacy provider category and aggregator boolean become the multi-valued
  `providerRoles` collection.
- Embedded warehouse addresses are removed. Each `LogisticsHub.locationId`
  references a common flat `IdentifiableLocation` in `providerLocations[]`.
  Its `geo` and `address` paths match Beckn Location so the temporary common
  shape can later be replaced without changing consumer paths.
  This workaround can be retired after an official Beckn Location supplies an ID.
- NIB and SIUP reuse `IONBusinessRegistration`; membership, customs-broker,
  dangerous-goods, cold-chain, and bonded-site evidence use credentials instead
  of booleans. Credential records refer to artifacts in `Provider.descriptor.docs`
  rather than importing `Document` from the temporary core contract.
- Pickup cutoffs and framework-agreement applicability remain with future Offer,
  Contract, flow, or policy work.
- Per-step requirements belong in Logistics flows and are not unconditional
  requirements in this reusable pack.

## Validation

From the external schema validator directory:

```powershell
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics\LogisticsProvider\v1
```

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-16 | Migrated legacy provider concepts into an ION Beckn v2 provider-attributes pack. |

