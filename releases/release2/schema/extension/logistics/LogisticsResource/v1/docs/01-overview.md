# LogisticsResource v1 overview

`LogisticsResource` is the catalog-plane description of cargo. It tells a
provider what is being moved or stored and supplies the structured facts needed
for rating, capacity, safety, customs, liability, and handling decisions.

The enclosing Beckn `Resource` owns its identifier and `Descriptor`. Narrative
cargo descriptions and document artifacts therefore remain in the core object.
This attribute pack carries only structured measurements, classifications, and
cross-resource references.

## Organization

- `LogisticsConsignment` carries aggregate quantities and references.
- `LogisticsPackage` carries separately handled physical package facts.
- `InventoryManifest` references the catalog Resources expected by a warehouse.
- `VehicleCargo` describes a vehicle being transported and must not be confused
  with the carrier's transport vehicle.
- `CustomsDeclaration` contains machine-actionable customs facts; document files
  remain in `Resource.descriptor.docs`.

The generic schema is geography-neutral. The `ION` layer is limited to the
certificate types and forms used by Indonesian and ASEAN trade arrangements.

