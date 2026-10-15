# Release 1 Logistics upstream-alignment ledger

> **Status:** In progress  
> **Target:** ION Release 1 draft  
> **Legacy source:** `indonesiaopennetwork/ion-specs` at
> `33e6b4c40feabecf6b0f6a827b488ff82998c735`  
> **Organizational reference:** `beckn/logistics` at
> `4d98c3c9b7244f32f3a900272adc990d870df0bf`  
> **Current coverage:** `LogisticsResource`

This internal ledger records the ownership and migration disposition of every
field in the legacy ION Logistics packs before normative Release 1 artifacts are
created. It is an analysis record, not part of the public specification.

The migration deliberately does not depend on the current Beckn Logistics
repository because its examples have not completed the v2 migration and ION
cannot consume that repository directly. The Beckn baseline used here is the
pinned Release 1 core contract and its vendored dependency closure. A future
official Beckn Logistics v2 release will be evaluated separately rather than
being anticipated in Release 1 schemas.

The current Beckn Logistics repository is nevertheless useful as a
non-normative organizational reference. Where its domain classes express a
clean semantic boundary, ION may organize independently owned fields under a
similarly named component. Similar naming does not mean schema compatibility,
inheritance, or provenance. ION fields continue to be defined and governed by
ION until an official Beckn Logistics v2 dependency is approved.

## Classification key

Each legacy field receives one primary classification from the migration plan:

| Code | Classification |
|---|---|
| `CORE` | Inherited from the Beckn v2 core object |
| `LOGISTICS` | Geography-neutral Logistics extension |
| `ION` | Indonesia-specific or ION-governed extension |
| `COMMON` | Existing ION common-pack concept |
| `POLICY` | Policy rather than schema |
| `FLOW` | Flow-conditional requirement |
| `LEGACY` | Obsolete or incompatible v1 concept |
| `DEFER` | Deferred pending a named decision |

Classification describes ownership, not necessarily the final data type. A
geography-neutral Logistics field can still reuse a pinned Beckn schema such as
`Quantity` or `PriceSpecification`. Conditional presence is inventoried
separately from field ownership so that a useful field is not misclassified as a
flow rule.

## Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-RSRC-001` | Where a request for shipment insurance belongs | Defer `insuranceRequested`; compare Resource, Commitment, and Offer ownership before authoring |
| `LOG-RSRC-002` | How a shipment refers to the products, cargo lines, packages, or SKUs it contains | Use `LogisticsConsignment` and `InventoryManifest` as organizational candidates, but prefer stable Resource or package identifiers over a second product taxonomy |
| `LOG-RSRC-003` | Where provider acceptance limits such as maximum weight and dimensions belong | Defer; these describe provider capability or offer constraints, not a shipment instance |
| `LOG-RSRC-004` | How customs and transport documents are represented | Use Beckn `Resource.descriptor.docs` for document artifacts; retain only structured customs facts that machines must validate or compare |

## Organizational alignment

The Beckn Logistics repository separates four concepts that the legacy ION
`LogisticsShipment` schema flattened together:

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Shipment` | Movement lifecycle, route, carrier, tracking, and status | Do not place inside `LogisticsResource`. Beckn maps it to the older `Fulfillment` concept; in the current ION v2 model, execution belongs with `Performance`. |
| `Package` | A physical transport unit with measurements and handling requirements | Use the independently defined `LogisticsPackage` component for physical, packaging, dangerous-goods, and temperature facts. |
| `Consignment` | Commercial grouping of packages under one transaction | Use the independently defined `LogisticsConsignment` component for aggregate quantities, customs facts, and references to contained packages or Resources. |
| `Vehicle` | The carrier's transport asset | Do not reuse for Ro-Ro cargo. Use `VehicleCargo`, because the legacy fields describe the vehicle being transported rather than the carrier vehicle performing transport. |

The legacy `serviceType` name also conflicts with the Beckn organization. In
legacy ION it distinguishes `PARCEL`, `DOCUMENT`, `FREIGHT`, `VEHICLE`, and
`INVENTORY`: categories of the thing being handled. In Beckn `Shipment` and
`Consignment`, `serviceType` distinguishes services such as `HYPERLOCAL`,
`COURIER`, and `EXPRESS`. Phase 4 should therefore use `resourceType` for the
legacy ION concept unless review selects a more precise non-conflicting name.

The proposed Release 1 organization is:

```text
LogisticsResource
  resourceType
  consignment -> LogisticsConsignment
  packages[] -> LogisticsPackage
  inventoryManifest -> InventoryManifest
  vehicleCargo -> VehicleCargo

LogisticsPackage
  measurements and declared value
  packaging and handling
  dangerousGoods
  lithiumBattery
  temperatureControl

LogisticsConsignment
  aggregate quantity and volume
  package or Resource references
  customsDeclaration
```

These are component boundaries within the `LogisticsResource` pack, not new
release packs or dependencies. `InventoryManifest` and `VehicleCargo` are
ION-chosen names with no claim of Beckn equivalence.

## `LogisticsResource` v1

### Sources and attachment point

- Legacy schema:
  `schema/extensions/logistics/resource/v1/attributes.yaml`
- Legacy schema name: `LogisticsShipment`
- Approved Release 1 pack name: `LogisticsResource`
- Attachment point: `Resource.resourceAttributes`
- Beckn v2 core ownership: `Resource` owns `id`, `descriptor`, and
  `resourceAttributes`; `Attributes` owns `@context` and `@type`.
- Beckn Logistics candidate status: **absent** from the approved Release 1
  dependency baseline. Reconcile with an official Beckn Logistics v2 resource
  schema in a later release.

### Field ownership and disposition

Every property path from the legacy `LogisticsShipment` schema is listed below.
Paths grouped in one row assign the same classification, proposed component,
and disposition to each explicitly named child.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsResource` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `serviceType` | `LOGISTICS` | `LogisticsResource.resourceType` | Keep the five geography-neutral resource categories but rename the field to avoid collision with Beckn's service-mode meaning. |
| `quantity` | `LOGISTICS` | `LogisticsConsignment` | Keep the aggregate unit-count concept, but reuse the pinned Beckn `Quantity/2.0` shape. |
| `quantity.value`, `quantity.unit` | `LEGACY` | `LogisticsConsignment` | Replace the ad hoc pair with the corresponding Beckn `unitQuantity` and `unitCode`/`unitText` fields. |
| `weight` | `LOGISTICS` | `LogisticsPackage` | Keep as a measured package fact and reuse the pinned Beckn `Quantity/2.0` shape. |
| `weight.value`, `weight.unit` | `LEGACY` | `LogisticsPackage` | Replace the ad hoc pair with Beckn quantity fields and standard unit codes. |
| `dimensions` | `LOGISTICS` | `LogisticsPackage` | Keep as a structured package measurement. |
| `dimensions.length`, `dimensions.width`, `dimensions.height`, `dimensions.unit` | `LOGISTICS` | `LogisticsPackage` | Keep; require one unit for all three axes and document a standard unit-code vocabulary during authoring. |
| `volumetricWeight` | `LOGISTICS` | `LogisticsPackage` | Keep the calculated weight when returned by a provider. |
| `volumetricWeight.value`, `volumetricWeight.unit` | `LEGACY` | `LogisticsPackage` | Replace with the pinned Beckn `Quantity/2.0` shape. |
| `volumetricWeight.formula` | `POLICY` | Offer or contract policy | Do not carry an executable or free-form pricing formula in the Resource schema; reference the applicable calculation policy from the owning offer or contract. |
| `totalVolume` | `LOGISTICS` | `LogisticsConsignment` | Keep for freight and consolidated cargo, using a standard quantity representation. |
| `totalVolume.value`, `totalVolume.unit` | `LEGACY` | `LogisticsConsignment` | Replace the ad hoc pair with Beckn quantity fields and standard unit codes. |
| `declaredValue` | `LOGISTICS` | `LogisticsPackage` | Keep the insurance/liability valuation concept and reuse pinned `PriceSpecification/2.0`. |
| `declaredValue.amount` | `LEGACY` | `LogisticsPackage` | Rename through reuse of `PriceSpecification.value`. |
| `declaredValue.currency` | `LOGISTICS` | `LogisticsPackage` | Keep through `PriceSpecification.currency`; remove the legacy `IDR` schema default because the generic layer is geography-neutral. |
| `insuranceRequested` | `DEFER` | Unresolved (`LOG-RSRC-001`) | Beckn's Package organization is relevant, but request versus package requirement remains semantically unresolved. |
| `fragile`, `stackable` | `LOGISTICS` | `LogisticsPackage` | Keep as machine-actionable handling facts. |
| `hazmatClass`, `hazmatSubsidiaryClasses`, `hazmatUnNumber`, `hazmatPackingGroup`, `hazmatProperShippingName` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep as geography-neutral dangerous-goods declarations aligned to international transport standards. |
| `hazmatNetQuantityPerPackage` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep, using a standard quantity representation. |
| `hazmatNetQuantityPerPackage.value`, `hazmatNetQuantityPerPackage.unit` | `LEGACY` | `LogisticsPackage.dangerousGoods` | Replace the ad hoc pair with Beckn quantity fields and standard unit codes. |
| `hazmatNetExplosiveMass`, `hazmatErgCode`, `hazmatSegregationGroup`, `hazmatPackagingInstruction` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep as structured dangerous-goods facts used for validation and handling. |
| `hazmatPackagingCertification` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep the structured packaging certification record. |
| `hazmatPackagingCertification.unCertifiedMarking`, `hazmatPackagingCertification.manufacturer`, `hazmatPackagingCertification.certificationDate` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep; these are machine-verifiable certification facts. |
| `hazmatOverpack`, `hazmatLimitedQuantityExemption`, `hazmatExceptedQuantityExemption` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep as dangerous-goods handling and exemption declarations. |
| `hazmatAirTransportCode`, `hazmatOceanStowageCategory` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep as transport-mode-specific regulatory classifications. |
| `hazmatShippersDeclaration` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep the declaration identity and signing facts, subject to `LOG-RSRC-004` for the document artifact. |
| `hazmatShippersDeclaration.documentReference`, `hazmatShippersDeclaration.signatoryName`, `hazmatShippersDeclaration.signedAt` | `LOGISTICS` | `LogisticsPackage.dangerousGoods` | Keep as structured facts required to identify and verify the declaration. |
| `hazmatShippersDeclaration.documentUrl` | `LEGACY` | `Resource.descriptor.docs` | Move the document artifact to the Beckn core document collection; link it by the retained document reference. |
| `lithiumBattery` | `LOGISTICS` | `LogisticsPackage.lithiumBattery` | Keep as the structured battery dangerous-goods declaration. |
| `lithiumBattery.chemistry`, `lithiumBattery.wattHourRating`, `lithiumBattery.lithiumContentGrams`, `lithiumBattery.stateOfCharge`, `lithiumBattery.configuration`, `lithiumBattery.section` | `LOGISTICS` | `LogisticsPackage.lithiumBattery` | Keep; each value affects classification, admissibility, or handling. |
| `temperatureRequirement` | `LOGISTICS` | `LogisticsPackage.temperatureControl` | Keep as a structured cold-chain requirement and use the organizational name `temperatureControl`. |
| `temperatureRequirement.controlled`, `temperatureRequirement.minTempC`, `temperatureRequirement.maxTempC`, `temperatureRequirement.category` | `LOGISTICS` | `LogisticsPackage.temperatureControl` | Keep; normalize temperature constraints and define the relationship between the category and numeric range while authoring. |
| `productCategory` | `DEFER` | Unresolved (`LOG-RSRC-002`) | The legacy enum duplicates product classification and mixes Trade categories into Logistics. Prefer referenced Resources. |
| `hsCodes` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep as standard customs classifications, while resolving consignment-level versus package-level ownership during authoring. |
| `commercialInvoice` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep the structured invoice facts needed for customs; apply `LOG-RSRC-004` to the artifact. |
| `commercialInvoice.invoiceNumber`, `commercialInvoice.invoiceDate`, `commercialInvoice.invoiceValue`, `commercialInvoice.currency` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep as machine-actionable customs facts; model the value with `PriceSpecification/2.0`. |
| `commercialInvoice.invoiceUrl` | `LEGACY` | `Resource.descriptor.docs` | Move the document artifact to the Beckn core document collection. |
| `certificateOfOrigin` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep the general certificate identity; split geography-neutral facts from the ION-specific preference list. |
| `certificateOfOrigin.certificateNumber`, `certificateOfOrigin.issuingAuthority` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep as geography-neutral certificate facts. |
| `certificateOfOrigin.certificateType`, `certificateOfOrigin.form` | `ION` | `IONLogisticsConsignment.customsDeclaration` | The legacy enum values encode Indonesian and ASEAN trade agreements and forms; place these values only in the ION layer or replace them with registry codes. |
| `certificateOfOrigin.documentUrl` | `LEGACY` | `Resource.descriptor.docs` | Move the document artifact to the Beckn core document collection. |
| `packingList` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Retain only if structured packing-list facts are added; otherwise the document belongs in `descriptor.docs` under `LOG-RSRC-004`. |
| `packingList.documentUrl` | `LEGACY` | `Resource.descriptor.docs` | Move the document artifact to the Beckn core document collection. |
| `importLicence` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep the licence identity and validity facts required for customs validation, subject to document handling under `LOG-RSRC-004`. |
| `importLicence.licenceNumber`, `importLicence.validUntil` | `LOGISTICS` | `LogisticsConsignment.customsDeclaration` | Keep as structured customs facts. |
| `cargoDescription` | `LEGACY` | Referenced `Resource.descriptor` | Move narrative cargo content to `longDesc`; do not duplicate it in Attributes. |
| `cargoManifest` | `DEFER` | `LogisticsConsignment` candidate | Resolve `LOG-RSRC-002`; represent contained packages or Resources by identifier rather than embedding a second catalogue model. |
| `cargoManifest[].lineId`, `cargoManifest[].quantity`, `cargoManifest[].unitWeight`, `cargoManifest[].hsCode` | `DEFER` | `LogisticsConsignment` candidate | Resolve their identifier and measurement shapes with `LOG-RSRC-002`; reuse Beckn quantity schemas where retained. |
| `cargoManifest[].description` | `LEGACY` | Referenced `Resource.descriptor` | Replace narrative duplication with the descriptor of the referenced cargo Resource. |
| `packagingType` | `LOGISTICS` | `LogisticsPackage` | Keep as a machine-actionable cargo handling and capacity fact. |
| `vehicleDetails` | `LOGISTICS` | `VehicleCargo` | Keep for Ro-Ro cargo, explicitly separate from the carrier's transport `Vehicle`. |
| `vehicleDetails.category`, `vehicleDetails.make`, `vehicleDetails.model`, `vehicleDetails.year`, `vehicleDetails.lengthM`, `vehicleDetails.widthM`, `vehicleDetails.heightM`, `vehicleDetails.weightKg` | `LOGISTICS` | `VehicleCargo` | Keep the structured identity and capacity facts; replace unit-suffixed field names with reusable measurement objects during authoring. |
| `vehicleRegistration` | `LOGISTICS` | `VehicleCargo` | Keep as the identifier of the vehicle being transported. |
| `skuCount` | `DEFER` | `InventoryManifest` candidate | Resolve `LOG-RSRC-002`; derive it from referenced inventory Resources when possible rather than transmitting two sources of truth. |
| `storageCategory` | `LOGISTICS` | `InventoryManifest` | Keep as a machine-actionable warehouse handling classification. |
| `skuManifest` | `DEFER` | `InventoryManifest` candidate | Resolve `LOG-RSRC-002`; prefer references to inventory Resources over embedded product records. |
| `skuManifest[].skuId`, `skuManifest[].quantity`, `skuManifest[].unitWeightKg`, `skuManifest[].unitVolumeCbm`, `skuManifest[].expiryDate` | `DEFER` | `InventoryManifest` candidate | Resolve their identifier and measurement shapes with `LOG-RSRC-002`; eliminate unit-suffixed names if retained. |
| `skuManifest[].description` | `LEGACY` | Referenced `Resource.descriptor` | Replace narrative duplication with the descriptor of the referenced inventory Resource. |
| `maxWeight` | `DEFER` | Offer or Provider capability | Resolve `LOG-RSRC-003`; a provider acceptance limit is not a shipment or package fact. |
| `maxWeight.value`, `maxWeight.unit` | `DEFER` | Offer or Provider capability | Move with the parent capability constraint and use Beckn `Quantity/2.0` if retained. |
| `maxDimensions` | `DEFER` | Offer or Provider capability | Resolve `LOG-RSRC-003`; a provider acceptance limit is not a shipment or package fact. |
| `maxDimensions.length`, `maxDimensions.width`, `maxDimensions.height`, `maxDimensions.unit` | `DEFER` | Offer or Provider capability | Move with the parent capability constraint and use the same dimensions shape if retained. |

No legacy `LogisticsResource` field maps to an existing ION common pack. The
shared `Address`, `BusinessRegistration`, `Payment`, `Settlement`, and `Tax`
packs do not own shipment characteristics.

### Requirements that belong to flows or policies

The following legacy `required` and `x-ion-condition` declarations are not
field ownership. They must not become unconditional required fields merely
because they appeared in the legacy schema.

| Legacy rule | Class | Phase 4 treatment |
|---|---|---|
| `serviceType` and `quantity` always required | `FLOW` | Declare presence at the applicable Logistics catalog or transaction steps. Keep the reusable attribute schema optional. |
| Weight required when quantity is declared | `FLOW` | Define by service type and transaction step; the legacy statement is too broad. |
| Dimensions required for volumetric charging | `FLOW` | Tie to the selected offer's charging method. |
| Declared value required for insurance or liability threshold | `FLOW` | Resolve with `LOG-RSRC-001`; the provider liability threshold itself is policy. |
| Dangerous-goods conditional fields | `FLOW` | Express presence rules in dangerous-goods flow variants, keyed by classification and transport mode. |
| Temperature fields required for cold chain | `FLOW` | Express in the cold-chain flow variant. |
| Cross-border invoice, origin, packing-list, licence, and HS-code requirements | `FLOW` | Express in cross-border flows; applicable legal thresholds and document rules remain policy. |
| Vehicle identity and measurements required for Ro-Ro | `FLOW` | Express in the Ro-Ro flow. |
| SKU manifest required for warehouse inbound | `FLOW` | Revisit after `LOG-RSRC-002`, then express in the warehouse inbound flow. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Resource schema aligned to the current Beckn core | `absent` | Compare field semantics, enum values, and reusable measurement/document shapes when an official compatible version is published. |
| Current Beckn Logistics `Shipment`, `Package`, `Consignment`, and `Vehicle` schemas | `incompatible` as dependencies; useful organizationally | Use their semantic boundaries as review input, but do not copy, reference, or claim conformance to them. Their mappings still target older core concepts. |
| Legacy ION `LogisticsShipment` | `under review` | Use only as the migration source; Phase 4 must apply this ledger rather than copying it verbatim. |
| Release 1 `LogisticsResource` | `suitable for later release` | Author only after the four named decisions are resolved or explicitly deferred from the pack. |

## Remaining pack inventories

The following legacy packs still require the same field-by-field review before
Phase 3 is complete:

1. `LogisticsProvider`
2. `LogisticsParticipant`
3. `LogisticsOffer`
4. `LogisticsCommitment`
5. `LogisticsConsideration`
6. `LogisticsContract`
7. `LogisticsPerformance`
8. `LogisticsTracking`
9. `LogisticsPerformanceStates`
