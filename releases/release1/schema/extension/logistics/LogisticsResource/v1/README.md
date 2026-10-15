# LogisticsResource v1

LogisticsResource describes the cargo that a provider is asked to move or
store. It attaches to `beckn:Resource.resourceAttributes` and is produced and
consumed during catalog discovery and transaction formation.

The pack does not copy the legacy shipment object. It separates the model into
stable concepts inspired by Beckn Logistics: a resource contains a consignment,
one or more packages, an optional inventory manifest, or a vehicle carried as
cargo. The pack remains ION-owned until an official Beckn Logistics schema
compatible with the pinned v2 core is available.

## Schema layers

| Schema | Purpose |
|---|---|
| `LogisticsResource` | Geography-neutral cargo, package, consignment, inventory, and vehicle facts. |
| `IONLogisticsResource` | Extends the generic layer with Indonesian and ASEAN certificate-of-origin classifications. This is the schema referenced by `profile.json`. |

## Main properties

| Property | Type | Meaning |
|---|---|---|
| `resourceType` | enum | `PARCEL`, `DOCUMENT`, `FREIGHT`, `VEHICLE`, or `INVENTORY`. |
| `consignment` | `IONLogisticsConsignment` | Aggregate quantities, contained Resource/package references, and customs facts. |
| `packages[]` | `LogisticsPackage` | Package measurements, value, packaging, handling, dangerous goods, battery, and temperature facts. |
| `inventoryManifest` | `InventoryManifest` | Warehouse storage category and referenced inventory Resources. |
| `vehicleCargo` | `VehicleCargo` | Identity and measurements of a vehicle transported as cargo. |

## Deliberate migration decisions

- `serviceType` is renamed to `resourceType`; Beckn uses service terminology for
  a different concept.
- Quantities use the pinned Beckn `Quantity/2.0` schema, and declared monetary
  values use `PriceSpecification/2.0`.
- Cargo and inventory entries reference existing Resource IDs instead of copying
  product descriptions or creating a second product taxonomy.
- Shipment documents belong in `Resource.descriptor.docs`. Structured fields use
  `documentReference` to associate with those documents.
- Provider acceptance limits such as maximum weight or dimensions do not belong
  on a shipment instance and are deferred to a provider or offer pack.
- `insuranceRequested` remains deferred until request ownership is resolved
  across Resource, Commitment, and Offer.
- Required-at-step and conditional-presence rules belong in Logistics flows, not
  in this reusable attribute pack.

## Example document placement

The example file contains only `resourceAttributes`, matching other Release 1
pack examples. In the enclosing core Resource, documents referenced by the
example would be placed as follows:

```yaml
descriptor:
  docs:
    - label: DOC-INVOICE-001
      mimeType: application/pdf
      url: https://logistics.example/documents/invoice-001.pdf
    - label: DOC-COO-001
      mimeType: application/pdf
      url: https://logistics.example/documents/coo-001.pdf
```

## Validation

From the external schema validator directory:

```powershell
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics\LogisticsResource\v1
```

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-16 | Migrated the legacy Logistics shipment concepts into a Beckn v2-compatible ION resource pack. |

