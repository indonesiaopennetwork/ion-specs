# Release 1 Logistics upstream-alignment ledger

> **Status:** Phase 3 complete
> **Target:** ION Release 1 draft  
> **Legacy source:** `indonesiaopennetwork/ion-specs` at
> `33e6b4c40feabecf6b0f6a827b488ff82998c735`  
> **Organizational reference:** `beckn/logistics` at
> `4d98c3c9b7244f32f3a900272adc990d870df0bf`  
> **Current coverage:** `LogisticsResource`, `LogisticsProvider`,
> `LogisticsParticipant`, `LogisticsOffer`, `LogisticsCommitment`,
> `LogisticsConsideration`, `LogisticsContract`, `LogisticsPerformance`,
> `LogisticsTracking`, `LogisticsPerformanceStates`

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

## `LogisticsProvider` v1

### Sources and attachment point

- Legacy schema:
  `schema/extensions/logistics/provider/v1/attributes.yaml`
- Legacy schema name: `LogisticsProvider`
- Approved Release 1 pack name: `LogisticsProvider`
- Attachment point: `Provider.providerAttributes`
- Beckn v2 core ownership: `Provider` owns `id`, `descriptor`, `availableAt`,
  and `providerAttributes`; `Catalog` separately owns catalog identity,
  contents, provider, and validity.
- Beckn Logistics organizational references: `Carrier`, `Operator`, and `Hub`.
  These are useful conceptual boundaries but are not Release 1 dependencies.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-PROV-001` | Where catalog version, publication, delta, and rate-card metadata belongs | Do not place it in Provider attributes. Reuse core `Catalog.validity`; defer additional catalog-publication metadata until the catalog publication contract has an approved extension point. |
| `LOG-PROV-002` | How carrier, operator, forwarder, aggregator, and warehouse roles are represented | Replace the single category and aggregator boolean with a `providerRoles` collection inspired by Beckn's separate `Carrier` and `Operator` concepts. Do not copy their schemas. |
| `LOG-PROV-003` | How service coverage is represented across countries and administrative systems | Define geography-neutral `ServiceCoverage` using core geometry or location identifiers; compose ION `Address` subdivisions only in the ION layer. |
| `LOG-PROV-004` | How provider sites and warehouses relate to locations | Use the common flat `IdentifiableLocation` shape because the pinned Beckn `Location/2.0` has no `id` and cannot be extended through `allOf`; reference Beckn's individual `geo` and `address` property definitions so field paths remain compatible. Define `LogisticsHub` records that reference those IDs and retire the common shape after an official Beckn Location supplies an identifier. |
| `LOG-PROV-005` | How licences and association memberships are asserted | Reuse `IONBusinessRegistration` for NIB and SIUP. Represent other licences and memberships as typed, verifiable credentials rather than status booleans. |

### Organizational alignment

The current Beckn Logistics repository offers three useful boundaries:

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Carrier` | Transport provider, supported services, coverage, fleet, and hubs | Use as inspiration for logistics capabilities and `ServiceCoverage`; do not copy identity, tax, or India-specific fields. |
| `Operator` | Entity coordinating a logistics network or multiple carriers | Use as inspiration for the `OPERATOR` and `AGGREGATOR` provider roles. Operational counts remain out of the schema unless a concrete protocol need is established. |
| `Hub` | Logistics facility with a location, type, capacity, and facilities | Define an independent `LogisticsHub` component referencing a common `IdentifiableLocation`; do not copy Beckn Location fields into the hub. |

The proposed Release 1 organization is:

```text
LogisticsProvider
  providerRoles[]
  supportedPatterns[]
  supportedTransportModes[]
  serviceCoverage[] -> ServiceCoverage
  capabilities -> LogisticsCapabilities
  operatingHours[]
  closures[]
  fleetProfile
  providerLocations[] -> common IdentifiableLocation
  hubs[] -> LogisticsHub
  businessRegistration -> IONBusinessRegistration
  credentials[]

ServiceCoverage
  coverageType
  geo or locationIds
  ionSubdivisions (ION layer only)

LogisticsHub
  locationId -> LogisticsProvider.providerLocations[*].id
  hubType
  capacity
  bonded
  facilities[]
```

These are components inside the `LogisticsProvider` pack. They do not introduce
separate Release 1 packs or assert compatibility with the current Beckn
Logistics repository.

### Field ownership and disposition

Every property path from the legacy `LogisticsProvider` schema is listed below.
Paths grouped in one row assign the same classification, proposed component,
and disposition to each explicitly named child.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsProvider` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `catalogVersion`, `catalogPublishedAt` | `DEFER` | Catalog publication contract (`LOG-PROV-001`) | Remove from Provider attributes. Catalog versioning and publication timestamps describe a catalog artifact, not the provider. |
| `catalogValidFrom`, `catalogValidUntil` | `CORE` | `Catalog.validity` | Replace with the core `Catalog.validity` `TimePeriod`; do not duplicate it in Provider attributes. |
| `rateCardEffectiveFrom`, `rateCardEffectiveUntil` | `DEFER` | Catalog or Offer (`LOG-PROV-001`) | Remove from Provider attributes. Resolve whether validity applies to a catalog or individual offers before authoring. |
| `catalogChangelogUrl` | `LEGACY` | `Catalog.descriptor.docs` candidate | Do not retain a bare URL. If published on the protocol, represent the changelog as a core `Document` associated with the catalog descriptor. |
| `catalogDeltaReference` | `DEFER` | Catalog publication contract (`LOG-PROV-001`) | Keep outside Provider attributes until delta retrieval and immutable catalog identity are specified. |
| `nibRegistered` | `LEGACY` | `IONBusinessRegistration` | Remove the boolean; derive registration from a validated `nib` value or credential. |
| `nibNumber` | `COMMON` | `IONBusinessRegistration.nib` | Reuse the existing common-pack field and its validation constraints. |
| `siupNumber` | `COMMON` | `IONBusinessRegistration.siupNumber` | Reuse the existing common-pack field, which already documents SIUP as a legacy licence. |
| `alfiMembership`, `asperindoMembership` | `ION` | `LogisticsProvider.credentials[]` | Replace unverifiable booleans with typed membership credentials under `LOG-PROV-005`. |
| `providerCategory` | `LOGISTICS` | `LogisticsProvider.providerRoles[]` | Replace the single closed category with one or more logistics roles. Preserve carrier, forwarder, aggregator, marketplace-logistics, 3PL, 4PL, and warehouse-operator concepts during vocabulary review. |
| `aggregatorModel` | `LEGACY` | `LogisticsProvider.providerRoles[]` | Remove as redundant when the provider declares the `AGGREGATOR` role. |
| `patternsSupported` | `LOGISTICS` | `LogisticsProvider.supportedPatterns[]` | Keep as discoverable logistics-pattern capability; align values to the eventual Release 1 flow registry rather than copying Beckn service-type enums. |
| `modesSupported` | `LOGISTICS` | `LogisticsProvider.supportedTransportModes[]` | Keep as geography-neutral transport-mode capability. Distinguish transport modes from vehicle types during vocabulary review. |
| `coverage` | `LOGISTICS` | `ServiceCoverage` | Keep the serviceability concept but replace embedded country-specific fields with reusable geometry or location references under `LOG-PROV-003`. |
| `coverage[].coverageType` | `LOGISTICS` | `ServiceCoverage.coverageType` | Keep pickup, delivery, and bidirectional coverage semantics. |
| `coverage[].provinsiCode` | `COMMON` | `IONServiceCoverage.ionSubdivisions.provinsiCode` | Reuse the common `IONAddress` subdivision field only in the ION-specific layer. |
| `coverage[].cityCode` | `DEFER` | `IONServiceCoverage.ionSubdivisions` | Resolve whether this means a core location ID, BPS kabupaten/kota code, or another registry before retaining it. |
| `coverage[].pincodes` | `LEGACY` | `ServiceCoverage` | Replace India-specific terminology with core geometry, location identifiers, or explicitly defined `postalCodes`. |
| `coldChainCertified`, `coldChainTemperatureZones` | `LOGISTICS` | `LogisticsCapabilities.coldChain` | Keep as cold-chain capability facts, but represent certification evidence through credentials rather than relying only on a boolean. |
| `hazmatCertified`, `hazmatClasses` | `LOGISTICS` | `LogisticsCapabilities.dangerousGoods` | Keep supported dangerous-goods classes; represent certification evidence through credentials. |
| `highValueCapable` | `LOGISTICS` | `LogisticsCapabilities.highValue` | Keep as a discoverable enhanced-security capability, with thresholds and evidence defined by offer or policy. |
| `beaCukaiLicenceNumber` | `ION` | `LogisticsProvider.credentials[]` | Keep the Indonesian customs-broker licence as a typed credential, not a standalone field. |
| `operatingHours` | `LOGISTICS` | `LogisticsProvider.operatingHours[]` | Keep recurring operating windows, aligned with the existing ION provider-hours shape and optionally scoped to an `availableAt` location. |
| `operatingHours[].day` | `LEGACY` | `LogisticsProvider.operatingHours[]` | Replace the closed day-name enum with the existing ION numeric `dayFrom`/`dayTo` convention. |
| `operatingHours[].opens`, `operatingHours[].closes` | `LEGACY` | `LogisticsProvider.operatingHours[]` | Rename to the existing ION `startTime` and `endTime` convention. |
| `holidayCalendar` | `LOGISTICS` | `LogisticsProvider.closures[]` | Keep exceptional closure dates using the existing ION provider `closures` organization and optional location scope. |
| `pickupCutoffTimes` | `DEFER` | Logistics Offer or corridor service level | Do not assume provider ownership; cutoff time normally varies by corridor and offered service. Resolve with the Offer inventory. |
| `pickupCutoffTimes[].corridor`, `pickupCutoffTimes[].serviceLevel`, `pickupCutoffTimes[].cutoffTime` | `DEFER` | Logistics Offer or corridor service level | Move with the parent cutoff rule if retained; reference defined corridor and service-level identifiers rather than free text. |
| `fleetType` | `LOGISTICS` | `LogisticsProvider.fleetProfile` | Keep the fleet-sourcing model, inspired by the carrier boundary but independent of individual transport assets. |
| `maxDeliveryRadiusKm` | `LEGACY` | `ServiceCoverage` | Replace the unit-suffixed scalar with a measured coverage constraint or geometry in `ServiceCoverage`. |
| `warehouseLocations` | `LOGISTICS` | `LogisticsProvider.hubs[]` | Replace embedded warehouse locations with `LogisticsHub` records referencing `providerLocations[]`. |
| `warehouseLocations[].locationId` | `COMMON` | `LogisticsHub.locationId` -> `LogisticsProvider.providerLocations[*].id` | Keep as a reference to the common `IdentifiableLocation` wrapper. |
| `warehouseLocations[].address` | `LEGACY` | `IdentifiableLocation.address` | Replace the untyped address with the vendored Beckn Location address property while preserving the flat Location wire layout. |
| `warehouseLocations[].warehouseType` | `LOGISTICS` | `LogisticsHub.hubType` | Keep the facility classification, using the organizational name `hubType`. |
| `warehouseLocations[].totalCapacityCbm` | `LEGACY` | `LogisticsHub.capacity` | Replace the unit-suffixed scalar with a typed quantity and a declared unit code. |
| `warehouseLocations[].bondedStatus` | `LOGISTICS` | `LogisticsHub.bonded` | Keep as a structured customs-facility fact; credential evidence belongs in `credentials[]`. |
| `fwaApplicable` | `POLICY` | Offer or Contract policy reference | Remove the provider boolean. Framework-agreement applicability is governed by the applicable offer/contract and policy reference. |

No field should be copied from the Beckn `Carrier`, `Operator`, or `Hub`
schemas. Their organization informs boundaries only. In particular, India GST,
PAN, pincode, and India-specific vehicle or facility examples are not ION
concepts.

### Requirements that belong to flows or policies

The legacy schema's unconditional and conditional presence rules are not
reusable field ownership:

| Legacy rule | Class | Phase 4 treatment |
|---|---|---|
| Catalog version and publication timestamps always required | `LEGACY` | Remove from Provider. Any future requirement belongs to the catalog publication contract. |
| NIB registration always required | `POLICY` | Reuse `IONBusinessRegistration`; ION onboarding policy determines when validated registration is mandatory. |
| Provider category, patterns, modes, coverage, and hours always required | `FLOW` | Declare the minimum provider-discovery fields in Logistics catalog flows, not in the shared schema. |
| SIUP required above an UMKM tier | `POLICY` | Govern through Indonesian licensing policy and `IONBusinessRegistration`; do not encode the threshold in this pack. |
| Cold-chain zones required when certified | `FLOW` | Express as a same-component conditional only if the final shape retains a certification-status field; credential validity remains policy. |
| Dangerous-goods classes required when certified or serving dangerous goods | `FLOW` | Require supported classes in relevant catalog and dangerous-goods flows; certification validity remains policy. |
| Customs-broker licence required for cross-border providers | `POLICY` | Require the applicable credential through cross-border participation policy. |
| Warehouse sites required for warehouse providers | `FLOW` | Express in the warehouse catalog flow after `LOG-PROV-004` is finalized. |
| Delivery radius required for hyperlocal providers | `FLOW` | Require an applicable `ServiceCoverage` constraint in hyperlocal discovery, not the legacy scalar field. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Provider schema aligned to current Beckn core | `absent` | Compare provider roles, coverage, capabilities, and site organization when an official compatible schema is published. |
| Current Beckn Logistics `Carrier`, `Operator`, and `Hub` schemas | `incompatible` as dependencies; useful organizationally | Retain the class boundaries as design input, but do not copy their fields, India-specific identifiers, required arrays, or older core mappings. |
| Legacy ION `LogisticsProvider` | `under review` | Use only as the field source; apply common-pack reuse and the ownership corrections in this ledger. |
| Release 1 `LogisticsProvider` | `suitable for later release` | Author after the five named decisions are resolved or explicitly deferred from the pack. |

## `LogisticsParticipant` v1

### Sources and attachment point

- Mapped legacy schema:
  `schema/extensions/logistics/participant-logistics/v1/attributes.yaml`
- Legacy schema name: `LogisticsParticipantAddendum`
- Approved Release 1 pack name: `LogisticsParticipant`
- Candidate attachment point: `Participant.participantAttributes`
- Related historical candidate: `schema/extensions/logistics/agent/v1` at
  legacy commit `f003bc7`. It contains the same three business fields and no
  additional field to merge. Its direct-property attachment claim conflicts
  with the pinned Release 1 core contract.
- Beckn v2 core ownership: `Participant` owns `id`, `descriptor`, and
  `participantAttributes`; the latter references `Attributes` in the pinned
  Release 1 contract.
- Beckn Logistics organizational references: `Courier`, `Driver`, and
  `Contact`. These are useful role boundaries but are not Release 1
  dependencies.

The repository currently contains contradictory prose about the Participant
extension point. The pinned `ion-beckn.yaml` defines
`Participant.participantAttributes`, while the schema style guide and the
Business Registration README say that v2 Participant has no such bag. Phase 4
must follow the pinned machine-readable contract unless that contract is
deliberately changed first; the contradictory guidance requires a separate
repository correction.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-PART-001` | Which Participant extension point Release 1 supports | Use `Participant.participantAttributes` because it exists in the pinned Release 1 core contract. Do not use the historical direct-property claim without first changing and documenting the core contract. |
| `LOG-PART-002` | Where the Logistics participant role taxonomy comes from | Do not assume the excluded legacy common Participant pack. Determine whether Logistics owns a minimal role discriminator or whether role is expressed by Contract/Performance relationships and credential type. |
| `LOG-PART-003` | How logistics licences are represented | Replace flat licence fields with typed `DriverLicence` and `CustomsBrokerLicence` components; preserve ION regulatory semantics and sensitive-data annotations. |
| `LOG-PART-004` | Whether licence validity and evidence are added in Release 1 | Beckn `Driver.licenseExpiry` is useful inspiration, but expiry and verifiable evidence are new fields and require an explicit ION requirement before inclusion. |

### Organizational alignment

The current Beckn Logistics repository distinguishes a `Courier`, who performs
pickup or delivery, from a `Driver`, who operates a transport vehicle. ION should
preserve that conceptual distinction even when the same human fulfills both
roles. It should not copy their schemas:

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Courier` | Last-mile pickup and delivery role | Treat as a participant role. Identity and presentation remain on core `Participant`; assignment and availability belong to runtime execution. |
| `Driver` | Vehicle-operating role with a driving licence | Organize the two SIM fields under `DriverLicence`; do not copy live location, vehicle assignment, operational status, experience, or background-verification booleans. |
| `Contact` | Contact channels for a transaction party | Do not duplicate in this pack. Use core participant description/contact conventions or an approved shared contact shape when available. |

The proposed Release 1 organization is intentionally thin:

```text
LogisticsParticipant
  role or relationship-derived role (LOG-PART-002)
  driverLicence -> DriverLicence
  customsBrokerLicence -> CustomsBrokerLicence

DriverLicence
  number
  category (ION layer)
  validUntil and evidence (only if LOG-PART-004 approves them)

CustomsBrokerLicence
  number
  validUntil and evidence (only if LOG-PART-004 approves them)
```

Both licence components are ION-governed because the legacy fields identify
Indonesian SIM and PPJK credentials. Their class boundaries are inspired by the
Beckn role organization, but their definitions and regulatory vocabularies
remain ION-owned.

### Field ownership and disposition

Every property path from the mapped legacy `LogisticsParticipantAddendum`
schema is listed below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsParticipant` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `ppjkLicenceNumber` | `ION` | `CustomsBrokerLicence.number` | Keep the PPJK identifier, but organize it as a typed Indonesian customs-broker credential. Restore the sensitive-data annotation present in the historical `LogisticsAgent` candidate. |
| `driverLicenceNumber` | `ION` | `DriverLicence.number` | Keep the Indonesian SIM identifier in a typed driver-licence component and mark it as sensitive Indonesian data. |
| `driverLicenceCategory` | `ION` | `DriverLicence.category` | Keep the SIM category concept. Review the enum against the governing Indonesian licence vocabulary before authoring rather than copying it unchanged. |

No mapped field is geography-neutral, and no mapped field belongs to an
existing Release 1 common pack. The pack is therefore an ION-governed Logistics
addendum, not a substitute for a generic Beckn `Courier` or `Driver` schema.

### Beckn-inspired fields that are not legacy migration fields

These fields appear in the current Beckn Logistics `Courier` or `Driver`
organization. They are not present in the mapped legacy source and must not be
silently introduced during migration:

| Candidate | Status | ION ownership assessment |
|---|---|---|
| Driver licence expiry | `under review` | Natural member of `DriverLicence`, but add only after `LOG-PART-004` establishes a requirement and validation semantics. |
| Participant name and profile image | `already covered conceptually` | Use `Participant.descriptor`; do not duplicate them in participant attributes. |
| Phone and email | `deferred` | Use an approved shared contact representation; do not adopt the Beckn Logistics `Contact` schema as a dependency. |
| Rating | `incompatible here` | Rating is post-performance data, not participant identity. Use the core rating protocol. |
| Current location, availability, and operational status | `incompatible here` | Runtime execution/tracking state belongs to Logistics Performance or Tracking. |
| Assigned vehicle and active shipments | `incompatible here` | Model through Performance relationships, not persistent participant attributes. |
| KYC/background-verification booleans | `incompatible here` | Represent verifiable evidence or policy outcomes rather than self-asserted booleans. |
| Experience, languages, and operating zones | `suitable for later review` | Consider only when a concrete discovery or allocation use case requires structured values. |

### Requirements that belong to flows or policies

| Legacy rule | Class | Phase 4 treatment |
|---|---|---|
| PPJK licence required when role is `CUSTOMS_BROKER` | `FLOW` | Require the typed credential in cross-border flows once `LOG-PART-002` defines how the role is identified; licence validity remains policy. |
| Driver licence number and category required when role is `DRIVER` | `FLOW` | Require `DriverLicence` in flows that assign a driver; licence validity and permitted vehicle class remain policy. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Participant/Agent schema aligned to current Beckn core | `absent` | Compare role, credential, and attachment semantics when an official compatible schema is published. |
| Current Beckn Logistics `Courier`, `Driver`, and `Contact` schemas | `incompatible` as dependencies; useful organizationally | Retain their role separation as design input, but do not copy their identity, runtime, India-specific, or older-core fields. |
| Historical ION `logistics/agent/v1` | `incompatible` attachment; no unique business fields | Do not migrate separately. Preserve its data-residency annotations and generic/ION split reasoning as review evidence. |
| Mapped legacy ION `LogisticsParticipantAddendum` | `under review` | Use as the three-field migration source, subject to typed credential organization and the role decision. |
| Release 1 `LogisticsParticipant` | `authored in draft` | Uses `participantRoles` for the minimal courier, driver, and customs-broker distinction; licence validity and evidence remain deferred. |

## `LogisticsOffer` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/offer/v1/attributes.yaml`
- Legacy schema name: `LogisticsOffer`
- Approved Release 1 pack name: `LogisticsOffer`
- Attachment point: `Offer.offerAttributes`
- Beckn v2 core ownership: `Offer` owns identity, description, provider,
  covered Resource identifiers, add-ons, proposed Considerations, validity, and
  the domain extension bag.
- Beckn Logistics organizational references: `Fare`, `FareBreakup`,
  `DeliverySlot`, `CancellationPolicy`, `ReturnPolicy`, and `Route`. These are
  review inputs, not Release 1 dependencies.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-OFFER-001` | How a published rate card relates to core Offer Considerations and the final calculated fare | Keep calculation inputs in a `LogisticsRateCard`; use core `Offer.considerations` for published price snapshots and Contract Considerations for agreed amounts. Do not use Beckn `Fare` as the rate-card schema. |
| `LOG-OFFER-002` | How pricing zones and distance limits reuse provider coverage | Reference or specialize the `ServiceCoverage` organization from `LogisticsProvider`; keep Indonesian subdivisions only in the ION layer. |
| `LOG-OFFER-003` | How pickup windows, operational cutoffs, departures, and bookable slots are represented | Define `PickupTerms`, `OperationalCutoff`, and `ServiceWindow`; use Beckn `DeliverySlot` only as organizational inspiration and keep mutable remaining capacity out of static catalog offers. |
| `LOG-OFFER-004` | Where API rate limits, latency commitments, bulk calls, and push delays belong | Defer them from the Offer pack. They describe protocol endpoint or participant service levels and require an approved technical-capability contract. |
| `LOG-OFFER-005` | How offer-level COD capability composes the common Payment model | Define `CodTerms`, reuse the common `IONPayment` COD method and typed monetary shapes, and keep runtime cash collection in Settlement attributes. |
| `LOG-OFFER-006` | Which SLA facts are structured offer commitments and which are policy | Keep durations, state references, and measurement bases in `ServiceLevelCommitment`; move executable formulas, escalation consequences, and breach remedies to policy references. |
| `LOG-OFFER-007` | How Framework Agreement applicability and targeted visibility are represented | Do not retain the `fwaApplicable` boolean alone. The pinned core Offer has no `availableTo` field despite the legacy README claim; defer until an approved targeting or policy-binding mechanism exists. |

### Organizational alignment

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Fare` and `FareBreakup` | Calculated total and price components | Use core Consideration plus pinned `PriceSpecification` for published and agreed money. `LogisticsRateCard` separately describes how a quote is calculated. |
| `DeliverySlot` | Offered or agreed service window | Use `ServiceWindow` for recurring offer windows. Actual availability and remaining capacity belong in selection or execution responses. |
| `CancellationPolicy` and `ReturnPolicy` | Distinct policy concerns | Keep ION registry IRIs grouped under `LogisticsPolicyReferences`; do not copy inline conditions, fees, or India-specific examples. |
| `Route` | Origin, destination, waypoints, mode, and duration | Keep offer-level topology and corridor eligibility thin. Concrete planned routes belong to Logistics Performance. |

The proposed Release 1 organization is:

```text
LogisticsOffer
  serviceDefinition
  rateCard -> LogisticsRateCard
  negotiationTerms
  pickupTerms -> PickupTerms
  cutoffs[] -> OperationalCutoff
  capacityTerms
  serviceWindows[] -> ServiceWindow
  codTerms -> CodTerms
  serviceLevelCommitment
  warehouseTerms
  roRoTerms
  crossBorderTerms
  policyReferences -> LogisticsPolicyReferences

LogisticsRateCard
  rateLogic
  pricingZones[]
  weightTiers[]
  chargeableWeight
  modifiers[]
```

These are components inside the `LogisticsOffer` pack. They are not copied
Beckn schemas and do not create new release packs.

### Field ownership and disposition

Every property path parsed from the legacy `LogisticsOffer` schema is listed
below. Repeated `x-ion-condition` annotations were accidentally indented under
`properties`; YAML parsers collapse those duplicate keys to one top-level field,
while another occurs inside `overallTatCommitment`. Both parsed paths are
explicitly classified as legacy defects.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsOffer` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `serviceLevel`, `transportMode`, `routingTopology` | `LOGISTICS` | `LogisticsOffer.serviceDefinition` | Keep as geography-neutral service characteristics; review vocabularies against included Logistics flows and distinguish transport mode from vehicle type. |
| `x-ion-condition` | `LEGACY` | None | Remove the misplaced annotations that parse as a property named `x-ion-condition`. Re-express applicable requirements in flows or correctly scoped schema conditionals. |
| `rateLogic` | `LOGISTICS` | `LogisticsRateCard.rateLogic` | Keep the calculation-model discriminator under `LOG-OFFER-001`. |
| `zones` | `LOGISTICS` | `LogisticsRateCard.pricingZones[]` | Keep zone-based rating, aligned with reusable `ServiceCoverage` identifiers under `LOG-OFFER-002`. |
| `zones[].zoneId`, `zones[].corridors` | `LOGISTICS` | `LogisticsRateCard.pricingZones[]` | Keep stable identifiers; corridors must reference defined origin/destination coverage rather than free-text routes. |
| `zones[].provinsiCodes` | `COMMON` | `IONPricingZone.ionSubdivisions` | Reuse common ION Address province codes only in the ION-specific layer. |
| `zones[].baseRatePerKg`, `zones[].currency` | `LEGACY` | `LogisticsRateCard.pricingZones[].price` | Replace separate amount and default-IDR fields with pinned `PriceSpecification`; the generic layer must not default currency to IDR. |
| `weightTiers` | `LOGISTICS` | `LogisticsRateCard.weightTiers[]` | Keep tiered weight pricing. |
| `weightTiers[].maxKg` | `LEGACY` | `LogisticsRateCard.weightTiers[].maximumWeight` | Replace the unit-suffixed scalar with pinned `Quantity/2.0`. |
| `weightTiers[].ratePerKg`, `weightTiers[].minimumCharge` | `LEGACY` | `LogisticsRateCard.weightTiers[]` | Replace untyped monetary scalars with `PriceSpecification` values and explicit applicability quantities. |
| `dimensionalWeightFactor`, `chargeableWeightRule` | `LOGISTICS` | `LogisticsRateCard.chargeableWeight` | Keep the structured calculation inputs. The factor requires an explicitly defined unit convention. |
| `minimumChargeableAmount` | `LEGACY` | `LogisticsRateCard.minimumCharge` | Replace the currency-less scalar with `PriceSpecification`. |
| `fuelSurchargeFormula` | `POLICY` | `LogisticsPolicyReferences` | Remove executable free text; reference a registered surcharge policy or use structured rate modifiers. |
| `rateModifiers` | `LOGISTICS` | `LogisticsRateCard.modifiers[]` | Keep structured conditional rate components. |
| `rateModifiers[].modifierType`, `rateModifiers[].basis`, `rateModifiers[].percentOfBase` | `LOGISTICS` | `LogisticsRateCard.modifiers[]` | Keep as machine-actionable modifier semantics. |
| `rateModifiers[].amount`, `rateModifiers[].currency`, `rateModifiers[].minimumAmount`, `rateModifiers[].maximumAmount` | `LEGACY` | `LogisticsRateCard.modifiers[].price` | Replace parallel monetary scalars with `PriceSpecification`. |
| `rateModifiers[].appliesWhen` | `POLICY` | `LogisticsRateCard.modifiers[].policyRef` | Replace human-readable trigger logic with structured applicability fields or a policy reference. |
| `rateModifiers[].validFrom`, `rateModifiers[].validUntil` | `LEGACY` | `LogisticsRateCard.modifiers[].validity` | Replace the timestamp pair with pinned `TimePeriod/2.0`. |
| `selectRequired`, `quoteValidityWindow` | `LOGISTICS` | `LogisticsOffer.negotiationTerms` | Keep the firm-quote requirement and quote lifetime; flows must define the allowed action sequence. |
| `pickupModels` | `LOGISTICS` | `PickupTerms.models[]` | Keep supported pickup arrangements. |
| `pickupWindowGranularityMinutes` | `LEGACY` | `PickupTerms.windowGranularity` | Replace the unit-suffixed integer with an ISO 8601 duration. |
| `bulkPickupMaxShipments` | `LOGISTICS` | `PickupTerms.bulkMaximum` | Keep as a bulk-pickup constraint using a typed quantity. |
| `sameDayPickupCutoffTime` | `LEGACY` | `OperationalCutoff` | Remove the duplicate special-case field and express it as a typed cutoff entry. |
| `dropOffLocationsUrl` | `LEGACY` | Core location references | Replace the external directory URL with identifiers for applicable Provider locations or Hubs. |
| `cutoffs` | `LOGISTICS` | `OperationalCutoff[]` | Keep the reusable cutoff schedule. |
| `cutoffs[].cutoffType`, `cutoffs[].cutoffBasis` | `LOGISTICS` | `OperationalCutoff` | Keep as cutoff discriminators. |
| `cutoffs[].localTime`, `cutoffs[].timezone`, `cutoffs[].applicableDays`, `cutoffs[].offsetBeforeDeparture`, `cutoffs[].departureReferenceEvent`, `cutoffs[].weeklyDay`, `cutoffs[].weeklyTime` | `LOGISTICS` | `OperationalCutoff` | Keep structured timing alternatives; Phase 4 must enforce the fields appropriate to each basis. |
| `cutoffs[].lookupUrl` | `LEGACY` | Deferred schedule discovery | Do not introduce an unspecified side-channel API. Represent known cutoffs in the offer or define a separate protocol capability. |
| `cutoffs[].appliesToOriginPorts`, `cutoffs[].appliesToConsolidationTypes`, `cutoffs[].appliesToHazmat`, `cutoffs[].appliesToReefer` | `LOGISTICS` | `OperationalCutoff.applicability` | Keep structured applicability filters using stable location and vocabulary codes. |
| `cutoffs[].lateAcceptancePolicy` | `LOGISTICS` | `OperationalCutoff.lateAcceptance` | Keep the outcome discriminator; fee and approval consequences may reference policy. |
| `cutoffs[].lateFee` | `LOGISTICS` | `OperationalCutoff.lateAcceptance.fee` | Keep the conditional late-fee concept using a standard monetary representation. |
| `cutoffs[].lateFee.amount`, `cutoffs[].lateFee.currency`, `cutoffs[].lateFee.basis` | `LEGACY` | `OperationalCutoff.lateAcceptance.fee` | Replace the ad hoc money object with `PriceSpecification` plus a defined basis. |
| `cutoffs[].gracePeriod` | `LOGISTICS` | `OperationalCutoff.lateAcceptance` | Keep as an ISO 8601 duration. |
| `cutoffs[].description` | `LEGACY` | Offer descriptor or policy description | Move narrative notes out of machine-actionable cutoff attributes. |
| `awbAllocationModel`, `awbBlockAllocationSupported`, `labelFormatsSupported` | `LOGISTICS` | `LogisticsOffer.documentTerms` | Keep machine-actionable shipment-document and identifier capabilities. |
| `bulkApiSupported`, `maxBulkBatchSize` | `DEFER` | Technical capability contract (`LOG-OFFER-004`) | Do not promise batched `/confirm` behavior through a business offer without an approved API contract. |
| `apiRateLimitPerSecond` | `DEFER` | Technical capability contract (`LOG-OFFER-004`) | Move API throttling out of Logistics business terms. |
| `apiSlaCommitment` | `DEFER` | Technical capability contract (`LOG-OFFER-004`) | Move endpoint service-level declarations out of the Offer pack. |
| `apiSlaCommitment.p50LatencyMs`, `apiSlaCommitment.p99LatencyMs`, `apiSlaCommitment.uptimeCommitment`, `apiSlaCommitment.statusPushMaxDelayMs` | `DEFER` | Technical capability contract (`LOG-OFFER-004`) | Do not migrate until units, measurement windows, enforcement, and the owning protocol surface are defined. |
| `stateTimingCommitments` | `LOGISTICS` | `ServiceLevelCommitment.stateTimings[]` | Keep structured state-relative timing promises under `LOG-OFFER-006`. |
| `stateTimingCommitments[].state`, `stateTimingCommitments[].maxDwellDuration`, `stateTimingCommitments[].alertThresholdDuration`, `stateTimingCommitments[].cascadeEffect`, `stateTimingCommitments[].applicableTopology` | `LOGISTICS` | `ServiceLevelCommitment.stateTimings[]` | Keep; state must resolve to the Logistics performance-state registry and durations remain ISO 8601. |
| `stateTimingCommitments[].alertPolicyIri` | `POLICY` | `ServiceLevelCommitment.stateTimings[].alertPolicy` | Keep only as a resolvable policy-registry IRI. |
| `stateTimingCommitments[].note` | `LEGACY` | Offer descriptor or policy description | Move narrative SLA notes out of the structured timing object. |
| `overallTatCommitment` | `LOGISTICS` | `ServiceLevelCommitment.overall` | Keep the end-to-end service commitment. |
| `overallTatCommitment.pickupToDelivery`, `overallTatCommitment.measurementBasis` | `LOGISTICS` | `ServiceLevelCommitment.overall` | Keep the ISO 8601 duration and measurement basis. |
| `overallTatCommitment.operatingCalendar` | `ION` | `IONServiceLevelCommitment.operatingCalendar` | The named Indonesian calendars are ION-governed; `CUSTOM` requires a stable calendar reference. |
| `overallTatCommitment.onTimeDefinition` | `POLICY` | `ServiceLevelCommitment.policyRef` | Replace free-text executable logic with a registered measurement policy. |
| `overallTatCommitment.x-ion-condition` | `LEGACY` | None | Remove the misplaced annotation that parses as data. |
| `capacityModel`, `consolidationType`, `equipmentType`, `scheduleType` | `LOGISTICS` | `LogisticsOffer.capacityTerms` | Keep freight, equipment, and schedule capability terms; align their vocabularies with included flows. |
| `agentAssignmentModel` | `LOGISTICS` | `LogisticsOffer.executionTerms` | Keep the agent allocation model as an offer-level execution term. |
| `maxDeliveryRadiusKm` | `LEGACY` | `ServiceCoverage` | Replace the unit-suffixed scalar with a geometry or measured distance constraint under `LOG-OFFER-002`. |
| `liveTrackingEnabled` | `LOGISTICS` | `LogisticsOffer.executionTerms` | Keep the promise that tracking is supported; actual tracking data belongs in Logistics Tracking. |
| `slotsAvailable` | `DEFER` | Selection response | Remove mutable availability from a static catalog offer unless freshness and update semantics are defined. |
| `slotGranularityMinutes` | `LEGACY` | `ServiceWindow.duration` | Replace the unit-suffixed integer with an ISO 8601 duration. |
| `slotWindowsOffered` | `LOGISTICS` | `ServiceWindow[]` | Keep recurring bookable windows, inspired by Beckn `DeliverySlot`. |
| `slotWindowsOffered[].start`, `slotWindowsOffered[].end` | `LOGISTICS` | `ServiceWindow` | Keep as a time range with explicit timezone or location scope. |
| `slotWindowsOffered[].availableCapacity` | `DEFER` | Selection response | Move mutable remaining capacity out of the catalog definition. |
| `availableOnCod` | `COMMON` | `CodTerms` and accepted payment method | Reuse the common `IONPayment` COD method; retain a Logistics offer capability only where additional COD terms apply. |
| `maxCodAmount` | `LEGACY` | `CodTerms.maximumAmount` | Replace the currency-less scalar with `PriceSpecification`. |
| `codPolicy` | `POLICY` | `CodTerms.policyRef` | Keep only as a resolvable policy-registry IRI. |
| `codVerifiedReceiptOtpRequired` | `LOGISTICS` | `CodTerms.receiptVerification` | Keep as a structured offer-level collection-control requirement. |
| `codDenominationsAccepted` | `ION` | `IONCodTerms.denominationsAccepted` | The legacy values are Indonesian Rupiah denominations; keep only in the ION layer and bind them to IDR explicitly. |
| `codBuyerDailyLimit`, `codShipmentLimit` | `LEGACY` | `CodTerms` | Replace currency-less limit scalars with `PriceSpecification`; policy determines applicable thresholds. |
| `codHoldPeriodDays` | `LEGACY` | `CodTerms.holdPeriod` | Replace the unit-suffixed integer with an ISO 8601 duration. |
| `codReconciliationVariance` | `POLICY` | COD settlement policy | Move acceptable settlement variance to the applicable policy; actual reconciliation belongs to the shared Settlement pack. |
| `maxDeclaredValue` | `LEGACY` | `LogisticsOffer.maximumDeclaredValue` | Keep the offer constraint but use `PriceSpecification`. |
| `insurancePolicy` | `POLICY` | `LogisticsPolicyReferences.insurance` | Keep only as a resolvable policy-registry IRI. |
| `valueAddedServices` | `CORE` | `Offer.addOns` | Replace the closed array with references to core Offer add-ons so optional services can carry their own description and consideration. |
| `storageBillingUnit`, `minimumStorageTerm` | `LOGISTICS` | `LogisticsOffer.warehouseTerms` | Keep warehouse charging basis and minimum term; the term remains an ISO 8601 duration. |
| `vehicleCategoriesAccepted` | `LOGISTICS` | `LogisticsOffer.roRoTerms` | Keep accepted cargo-vehicle categories, distinct from carrier transport-vehicle types. |
| `sailingSchedule` | `LOGISTICS` | `LogisticsOffer.roRoTerms.departures[]` | Keep recurring advertised departures; concrete booked departure belongs to Commitment or Performance. |
| `sailingSchedule[].departurePort`, `sailingSchedule[].destinationPort` | `LOGISTICS` | `LogisticsOffer.roRoTerms.departures[]` | Keep using stable UN/LOCODE or other declared location identifiers. |
| `sailingSchedule[].departureTimes`, `sailingSchedule[].daysOfWeek` | `LOGISTICS` | `LogisticsOffer.roRoTerms.departures[]` | Keep as recurring schedule data with an explicit timezone. |
| `crossingDuration` | `LOGISTICS` | `LogisticsOffer.roRoTerms` | Keep as an ISO 8601 duration. |
| `incotermsSupported`, `dutyAndTaxModel` | `LOGISTICS` | `LogisticsOffer.crossBorderTerms` | Keep cross-border commercial responsibility terms; review vocabulary currency and avoid treating obsolete Incoterms as current standards. |
| `cancellationPolicy`, `claimPolicy`, `slaPolicy`, `evidencePolicy`, `disputePolicy`, `reAttemptPolicy` | `POLICY` | `LogisticsPolicyReferences` | Keep only as resolvable, typed ION policy-registry IRIs. Do not copy Beckn inline policy objects. |
| `fwaApplicable` | `DEFER` | Framework Agreement binding (`LOG-OFFER-007`) | Remove the standalone boolean until Release 1 has an approved agreement-binding and offer-targeting mechanism. |

### Requirements that belong to flows or policies

The legacy root `required` array and many `x-ion-condition` annotations mix
catalog requirements, pattern applicability, and policy. Phase 4 must not copy
them wholesale:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| Service level, transport mode, and rate logic always required | `FLOW` | Require the minimum discovery fields in applicable Logistics catalog flows. |
| `/select` required according to `selectRequired` | `FLOW` | Define the permitted action sequence and quote-expiry behavior in each flow. |
| Pickup, cutoff, capacity, freight, Ro-Ro, warehouse, and cross-border conditions | `FLOW` | Require the applicable component in its corresponding pattern rather than making all fields globally mandatory. |
| Rate modifier, chargeable-weight, late-fee, COD, and declared-value thresholds | `POLICY` | Keep structured values where interoperability requires them; govern thresholds and consequences through referenced policies. |
| State timing and total-turnaround requirements | `FLOW` | Bind state names to the selected performance-state machine and declare the required commitments per service level. |
| Policy IRIs always required | `FLOW` | Each included flow must name the policy categories it needs; the shared schema keeps policy references optional and validates supplied IRIs. |
| OTP required when COD is available | `FLOW` | Require only when the selected COD policy or offer explicitly uses OTP receipt verification. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Offer schema aligned to current Beckn core | `absent` | Compare service, rate-card, slot, capacity, COD, and policy organization when an official compatible schema is published. |
| Current Beckn Logistics `Fare` and `FareBreakup` | `incompatible` as dependencies; useful organizationally | Use only to distinguish calculated fare from rate logic; rely on core Consideration and pinned `PriceSpecification` in Release 1. |
| Current Beckn Logistics `DeliverySlot` | `under review` organizationally | Reuse the service-window boundary, but not its mutable availability fields or schema dependency. |
| Current Beckn Logistics policy schemas | `incompatible` as dependencies; useful organizationally | Preserve separate policy concerns, but use ION registry IRIs rather than copied inline terms. |
| Legacy ION `LogisticsOffer` | `under review` | Use as the field source while applying the ownership, typing, and policy corrections in this ledger. |
| Release 1 `LogisticsOffer` | `suitable for later release` | Author after the seven named decisions are resolved or explicitly deferred from the pack. |

## `LogisticsCommitment` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/commitment/v1/attributes.yaml`
- Legacy schema name: `LogisticsCommitment`
- Approved Release 1 pack name: `LogisticsCommitment`
- Attachment point: `Commitment.commitmentAttributes`
- Beckn v2 core ownership: `Commitment` owns `id`, lifecycle status, selected
  `resources[]`, selected `offer`, and `commitmentAttributes`.
- Beckn Logistics organizational references: `Package`, `Consignment`,
  `DeliverySlot`, and `Vehicle`. No current Beckn Logistics Commitment schema is
  an approved dependency.
- Pinned Beckn retail reference: `RetailCommitment/2.1` demonstrates line-level
  references and typed quantity, but Logistics must not inherit the retail pack.

The pinned core `Commitment.resources[]` declaration requires each embedded
Resource to have `id` and `quantity`, while the pinned core `Resource` schema
does not declare `quantity`. This is a machine-readable core inconsistency, not
permission to preserve all legacy duplicate line fields. Phase 4 must resolve or
explicitly work around it before authoring the pack.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-CMT-001` | How committed Resource quantity is represented given the pinned core inconsistency | Prefer core `Commitment.resources[]` and a corrected typed quantity contract. Do not duplicate Resource and Offer identity in commitment attributes merely to bypass the inconsistency. |
| `LOG-CMT-002` | Whether aggregate package count, weight, and volume are transmitted or derived | Derive aggregates from committed Logistics Resources or Packages by default. Retain a declared snapshot only if audit, rating, or capacity allocation requires an authoritative value. |
| `LOG-CMT-003` | How allocation-specific container, inventory, capacity, and Ro-Ro facts are organized | Use typed `CargoAllocation`, `InventoryAllocation`, `CapacityReservation`, and Resource references rather than one flat line object. |
| `LOG-CMT-004` | Where free-text handling instructions belong | Prefer structured handling declarations on `LogisticsPackage`; retain commitment-specific instructions only when the consumer must communicate an operational instruction not represented by the selected Resource. |
| `LOG-CMT-005` | How a child logistics transaction links to a parent commitment or contract | Keep a typed parent reference only after its identifier scope and cross-contract relationship are defined. Coordinate with `LogisticsContract`. |

### Organizational alignment

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Package` | Physical unit and handling facts | Reference committed `LogisticsPackage` Resources. Do not copy weight, volume, or vehicle facts into Commitment unless an explicit immutable snapshot is required. |
| `Consignment` | Commercial grouping and transport identifiers | Use `CargoAllocation` for container and seal facts established during booking. Keep the full consignment definition with the Resource. |
| `DeliverySlot` | Selected service window | Record a selected window identifier or typed requested window rather than repeating the offer's recurring schedule. |
| `Vehicle` | Carrier transport asset | Do not use it for Ro-Ro cargo. Reference the selected `VehicleCargo` Resource instead of duplicating its registration. |
| `RetailCommitment` | Line identifier, Resource/Offer references, quantity | Use only as evidence that typed quantities and references are preferable; core Logistics ownership takes precedence and retail inheritance is inappropriate. |

The proposed Release 1 organization is:

```text
Commitment (core)
  id
  resources[]
  offer
  commitmentAttributes -> LogisticsCommitment

LogisticsCommitment
  cargoAllocation -> CargoAllocation
  inventoryAllocations[] -> InventoryAllocation
  capacityReservation -> CapacityReservation
  requestedServiceWindow
  specialInstructions (only if LOG-CMT-004 retains it)
  parentReference (only if LOG-CMT-005 resolves it)
```

These are components inside the `LogisticsCommitment` pack, not new release
packs or copied Beckn schemas.

### Field ownership and disposition

Every property path from the legacy `LogisticsCommitment` schema is listed
below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsCommitment` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `lineId` | `CORE` | `Commitment.id` | Remove the duplicate line identifier and use the core Commitment identifier. |
| `resourceId` | `CORE` | `Commitment.resources[].id` | Remove the duplicate field and use the selected core Resource references, subject to `LOG-CMT-001`. |
| `offerId` | `CORE` | `Commitment.offer.id` | Remove the duplicate field and use the selected core Offer reference. |
| `packageCount` | `DEFER` | Derived aggregate (`LOG-CMT-002`) | Derive from committed Packages by default; if retained as a declared snapshot, use pinned `Quantity/2.0`. |
| `totalWeight` | `DEFER` | Derived aggregate or `CapacityReservation` | Derive from committed Package weights unless an authoritative booked-weight snapshot is required. |
| `totalWeight.value`, `totalWeight.unit` | `LEGACY` | Derived aggregate or `CapacityReservation` | Replace the ad hoc measurement pair with pinned `Quantity/2.0` if the parent is retained. |
| `totalVolume` | `DEFER` | Derived aggregate or `CapacityReservation` | Derive from committed Package or Consignment measurements unless a booked-volume snapshot is required. |
| `totalVolume.value`, `totalVolume.unit` | `LEGACY` | Derived aggregate or `CapacityReservation` | Replace the ad hoc measurement pair with pinned `Quantity/2.0` if the parent is retained. |
| `specialInstructions` | `DEFER` | `LogisticsCommitment.specialInstructions` | Resolve `LOG-CMT-004`; keep only transaction-specific operational prose that cannot be represented by structured Package handling fields. |
| `containerReference`, `sealNumber` | `LOGISTICS` | `CargoAllocation` | Keep allocation-specific container and seal identifiers established during freight booking. |
| `skuId` | `LEGACY` | `InventoryAllocation.resourceId` | Replace the SKU-specific duplicate with a reference to the committed inventory Resource. |
| `quantity` | `DEFER` | Core committed Resource quantity (`LOG-CMT-001`) | Replace the untyped integer with the resolved core quantity representation; do not maintain a competing attribute value. |
| `lotNumber`, `expiryDate` | `LOGISTICS` | `InventoryAllocation` | Keep lot allocation and expiry facts when selection binds a specific inventory lot. |
| `capacityUnits`, `capacityUnitType` | `LEGACY` | `CapacityReservation.quantity` | Replace parallel value/type fields with pinned `Quantity/2.0` and a controlled capacity unit code. |
| `requestedDepartureDate` | `LEGACY` | `LogisticsCommitment.requestedServiceWindow` | Replace the date-only field with a selected service-window identifier or pinned `TimePeriod/2.0`. |
| `vehicleRegistration` | `LEGACY` | Selected `VehicleCargo` Resource reference | Do not duplicate a sensitive or mutable vehicle identifier; reference the committed Ro-Ro cargo Resource. |
| `parentCommitmentId` | `DEFER` | `LogisticsCommitment.parentReference` | Resolve identifier scope and cross-contract semantics under `LOG-CMT-005` before retaining it. |

### Requirements that belong to flows or policies

The legacy pack declares no root required array, but its README assigns
pattern-specific presence rules. Those rules belong to flows:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| Package count, weight, and instructions for parcel commitments | `FLOW` | Require only the selected Resource references and any non-derivable snapshot or instruction needed by the parcel flow. |
| Container, seal, weight, volume, capacity, and departure facts for freight | `FLOW` | Require the applicable `CargoAllocation`, `CapacityReservation`, and requested window fields at the step when they become known. |
| Vehicle registration for Ro-Ro | `FLOW` | Require a selected `VehicleCargo` Resource reference rather than repeating registration. |
| SKU quantity, lot, and expiry for warehouse commitments | `FLOW` | Require `InventoryAllocation` entries for flows that bind specific lots; expiry requirements depend on the Resource category and policy. |
| Parent commitment for spawned dispatches | `FLOW` | Require only in a defined parent-child warehouse dispatch flow after `LOG-CMT-005` is resolved. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Commitment schema aligned to current Beckn core | `absent` | Compare allocation, selected-slot, capacity, and parent-reference semantics when an official compatible schema is published. |
| Current Beckn Logistics `Package`, `Consignment`, `DeliverySlot`, and `Vehicle` | `incompatible` as dependencies; useful organizationally | Use their boundaries to distinguish selected Resources from booking allocations; do not copy schemas or older-core mappings. |
| Pinned `RetailCommitment/2.1` | `incompatible` as a Logistics parent; useful structurally | Reuse pinned common types where applicable, but do not inherit retail-specific commitment fields. |
| Legacy ION `LogisticsCommitment` | `under review` | Use as the field source while removing core duplication and reorganizing allocation facts. |
| Release 1 `LogisticsCommitment` | `suitable for later release` | Author after the five named decisions and the core quantity inconsistency are resolved or explicitly deferred. |

## `LogisticsConsideration` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/consideration/v1/attributes.yaml`
- Legacy schema name: `LogisticsConsideration`
- Approved Release 1 pack name: `LogisticsConsideration`
- Attachment point: `Consideration.considerationAttributes`
- Beckn v2 core ownership: `Consideration` owns `id`, lifecycle status, and
  `considerationAttributes`. Its description explicitly directs monetary
  considerations to the pinned `PriceSpecification/2.0` schema.
- Pinned monetary parent: `PriceSpecification/2.0` owns `currency`, total
  `value`, `applicableQuantity`, and generic `components[]`.
- Beckn Logistics organizational references: `Fare`, `FareBreakup`, and
  `Receipt`. They are not approved Release 1 dependencies.
- Existing ION common references: `Tax/v1`, `Payment/v1`, and `Settlement/v1`.

The legacy pack combines four different lifecycle concerns in one flat object:
the quoted or agreed logistics price, calculation inputs, post-performance
charges, and COD collection/remittance. Release 1 must separate those concerns
rather than reproduce the legacy shape.

The legacy `freight-pricing.json` example also does not validate against its
own authoring schema: it uses `breakup[].title` and nested `price` objects where
the schema declares `titleType`, numeric `amount`, and per-line `currency`; it
uses an object for `totalAmount` where the schema declares a number. The example
is evidence of intended meaning only and must not be copied into Phase 4.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-CNS-001` | Which schema supplies the canonical monetary shape | Inherit pinned `PriceSpecification/2.0`; map legacy `totalAmount` to `value` and `breakup` to refined `components[]`. Do not create a second total or currency representation. |
| `LOG-CNS-002` | How detailed logistics charge kinds are represented | Refine each generic PriceSpecification component with a `chargeCode` and optional typed calculation detail. Retain the generic component `type` for broad classification; do not use a human title as the machine code. |
| `LOG-CNS-003` | How estimated, agreed, revised, and final amounts are distinguished | Prefer separate lifecycle Consideration records and core status. Add a valuation-stage or predecessor reference only if flows cannot identify the stage and revision chain unambiguously. Do not keep parallel original/revised totals by default. |
| `LOG-CNS-004` | Where COD fee, collection, and remittance facts belong | Keep the COD service fee as a price component. Move collected amount, remittance amount, batch, timestamp, and method to Settlement/Payment modeling after defining a COD collection record; they are not price attributes. |
| `LOG-CNS-005` | How tax and customs amounts reuse shared tax modeling | Use charge components for duty and tax amounts. Reuse or generalize `IONTaxDetail` only after removing its RetailConsideration-specific parent-path assumption; do not duplicate top-level PPN fields. |
| `LOG-CNS-006` | How insurance price and coverage are separated | Keep the insurance premium as a charge component. Keep coverage amount with the selected insurance terms or policy in Offer/Contract, not in monetary consideration attributes. |
| `LOG-CNS-007` | Whether adjustment components use signed values and how their calculation is audited | Define one sign convention for discounts, credits, rebates, refunds, and positive surcharges. Retain calculation basis/rate only where an audit or dispute flow needs it; otherwise derive it from the selected Offer and component value. |

### Organizational alignment

| Beckn or ION concept | Useful boundary | ION treatment |
|---|---|---|
| Pinned `PriceSpecification` | Currency, total value, applicable quantity, and component list | Use as the normative parent and vocabulary for the monetary shape. |
| Beckn Logistics `Fare` | One logistics price containing base freight, surcharges, taxes, discounts, and a breakup | Follow the single-price boundary, but do not copy its duplicate flat amount fields or depend on the current schema. |
| Beckn Logistics `FareBreakup` | A charge line with a broad type and detailed meaning | Adopt the separation between generic component type and logistics charge code. Use the pinned PriceSpecification component as the base. |
| Beckn Logistics `Receipt` | Payment and delivery acknowledgement after execution | Treat as evidence that payment transaction and receipt facts are later-lifecycle documents, not consideration price fields. Do not copy its schema. |
| ION `Tax/v1` | Indonesian tax classification, rate, inclusivity, taxable base, and e-Faktur reference | Reuse after `LOG-CNS-005` confirms a logistics-compatible attachment path or generalizes the common pack. |
| ION `Payment/v1` and `Settlement/v1` | Payment declaration, payout terms, and reconciliation | Reuse for actual movement and reconciliation of money. Extend deliberately for COD collection/remittance rather than embedding it in the price. |

The proposed Release 1 organization is:

```text
Consideration (core)
  id
  status
  considerationAttributes -> LogisticsConsideration

LogisticsConsideration (inherits PriceSpecification/2.0)
  currency                  (inherited)
  value                     (inherited total)
  applicableQuantity        (inherited)
  components[] -> LogisticsChargeComponent

LogisticsChargeComponent (refines a PriceSpecification component)
  type                      (generic UNIT/TAX/DELIVERY/DISCOUNT/FEE/SURCHARGE)
  value, currency           (inherited)
  description               (inherited human-readable label)
  chargeCode                (logistics-specific machine code)
  calculation               (optional basis/rate audit detail)
  taxDetail                 (only after LOG-CNS-005)
```

`LogisticsChargeComponent` and any calculation detail are components inside the
`LogisticsConsideration` pack, not separate packs or copied Beckn Logistics
schemas. COD collection/remittance records are intentionally outside this
structure.

### Charge-code organization

The legacy `titleType` enum is useful source material, but its members should
be organized under broad component types rather than treated as 66 unrelated
top-level price fields:

| Generic component type | Representative legacy charge codes | Notes |
|---|---|---|
| `DELIVERY` or `UNIT` | `FREIGHT_BASE`, `MINIMUM_CHARGE` | The exact generic type for minimum charge must be fixed with the sign and calculation rules. |
| `SURCHARGE` | `FUEL_SURCHARGE`, `PEAK_SEASON_SURCHARGE`, `REMOTE_AREA_SURCHARGE`, `OVERSIZE_SURCHARGE`, `WEIGHT_DIFF_ADJUSTMENT` | Calculation basis/rate is optional audit detail; the amount remains the component value. |
| `FEE` | `COD_CHARGE`, `HANDLING_FEE`, `STORAGE_FEE`, `PICK_PACK_FEE`, `DOCUMENTATION_FEE` | More specific legacy COD fee variants may remain charge codes without becoming top-level properties. |
| `TAX` | `PPN_TAX`, `PPNBM_TAX`, `PPH_23_WITHHOLDING`, `STAMP_DUTY`, `CUSTOMS_DUTY` | Tax rate, taxable base, and regime belong in tax detail when applicable. Customs duties may require a distinct duty classification. |
| `DISCOUNT` | `DISCOUNT`, `VOLUME_REBATE`, `SLA_REBATE`, `CREDIT_NOTE`, `PPN_DIBEBASKAN_CREDIT` | Resolve the signed-value convention under `LOG-CNS-007`; do not encode sign only in the charge code. |

All legacy enum values remain source candidates for the Phase 4 controlled
vocabulary. This table organizes them; it does not silently discard values not
shown as representatives.

### Field ownership and disposition

Every property path from the legacy `LogisticsConsideration` schema is listed
below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsConsideration` | Keep through the inherited Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `breakup` | `LEGACY` | `LogisticsConsideration.components[]` | Replace with the inherited PriceSpecification component list refined as `LogisticsChargeComponent`. |
| `breakup[].titleType` | `LOGISTICS` | `LogisticsChargeComponent.chargeCode` | Keep the machine-readable logistics charge meaning; pair it with the inherited generic component `type`. |
| `breakup[].amount` | `LEGACY` | `LogisticsChargeComponent.value` | Rename to the inherited component value. |
| `breakup[].currency` | `CORE` | `LogisticsChargeComponent.currency` | Reuse the inherited component currency; require consistency with the parent currency unless a multi-currency rule is explicitly defined. |
| `breakup[].ppnRate` | `COMMON` | `LogisticsChargeComponent.taxDetail.rate` | Replace with shared tax detail after `LOG-CNS-005`; meaningful only for a tax component. |
| `totalAmount` | `CORE` | `LogisticsConsideration.value` | Replace with inherited PriceSpecification total value. |
| `currency` | `CORE` | `LogisticsConsideration.currency` | Reuse inherited ISO 4217 currency. |
| `freightBase` | `LEGACY` | `components[chargeCode=FREIGHT_BASE].value` | Remove the duplicate flat total and express it once as a component. |
| `fuelSurcharge` | `LEGACY` | `components[chargeCode=FUEL_SURCHARGE].value` | Remove the duplicate flat total and express it once as a component. |
| `fuelSurchargeRate` | `DEFER` | `LogisticsChargeComponent.calculation.rate` | Retain only if the transaction must audit the applied rate; otherwise derive it from the selected Offer's formula and component value. |
| `codCharge` | `LEGACY` | `components[chargeCode=COD_CHARGE].value` | Keep the logistics service fee as one component, not a duplicate flat amount. |
| `codAmountCollected` | `COMMON` | Future COD collection record under Settlement/Payment | Move the actual collected amount out of Consideration; resolve the common-pack extension under `LOG-CNS-004`. |
| `codRemittanceAmount` | `COMMON` | Future COD remittance record under Settlement | Move the actual remitted amount out of Consideration and reconcile it through Settlement. |
| `codRemittanceBatchRef` | `COMMON` | Future COD remittance record under Settlement | Move the batch reference with the remittance record. |
| `codRemittanceTimestamp` | `COMMON` | Future COD remittance record under Settlement | Move the remittance event time with the remittance record. |
| `codRemittanceMethod` | `COMMON` | Payment/Settlement method | Replace the logistics-local enum with the applicable shared payment method and rail representation. |
| `insurancePremium` | `LEGACY` | `components[chargeCode=INSURANCE_PREMIUM].value` | Keep the premium as one charge component. |
| `insuranceCoverageAmount` | `DEFER` | Selected insurance terms in Offer/Contract | Move the insured coverage limit out of price attributes under `LOG-CNS-006`. |
| `dutyEstimate` | `LEGACY` | Estimated `CUSTOMS_DUTY` component | Express as a component on the estimated Consideration rather than a parallel top-level amount. |
| `taxEstimate` | `LEGACY` | Estimated tax component(s) | Express each tax as a component on the estimated Consideration with tax detail where applicable. |
| `actualDuty` | `LEGACY` | Final or revised `CUSTOMS_DUTY` component | Express on the later lifecycle Consideration; do not keep estimated and actual fields side by side. |
| `actualTax` | `LEGACY` | Final or revised tax component(s) | Express on the later lifecycle Consideration; preserve tax-regime detail rather than one undifferentiated total where known. |
| `revisedAmount` | `LEGACY` | Successor `LogisticsConsideration.value` | Replace with the canonical total on a revised Consideration under `LOG-CNS-003`. |
| `revisionBreakup` | `LEGACY` | Successor `LogisticsConsideration.components[]` | Replace with canonical components on the revised Consideration. |
| `revisionBreakup[].titleType` | `LOGISTICS` | Successor component `chargeCode` | Use the same controlled charge vocabulary as the original Consideration. |
| `revisionBreakup[].originalAmount` | `DEFER` | Revision audit record or predecessor component | Derive by comparing predecessor and successor Considerations unless an explicit audit snapshot is required. |
| `revisionBreakup[].revisedAmount` | `LEGACY` | Successor component `value` | Use the revised component's canonical value. |
| `revisionBreakup[].diff` | `DEFER` | Derived revision delta | Derive from predecessor and successor values unless the protocol requires an asserted delta. |
| `weightDiffAdjustment` | `LEGACY` | `components[chargeCode=WEIGHT_DIFF_ADJUSTMENT].value` | Express once as a positive or negative adjustment component according to `LOG-CNS-007`. |
| `addressChangeSurcharge` | `LEGACY` | `components[chargeCode=ADDRESS_CHANGE_SURCHARGE].value` | Add the missing controlled charge code and express the amount as a component. |
| `rescheduleFee` | `LEGACY` | `components[chargeCode=RESCHEDULE_FEE].value` | Add the missing controlled charge code and express the amount as a component. |
| `failedPickupFee` | `LEGACY` | `components[chargeCode=FAILED_PICKUP_FEE].value` | Express once as a component. |
| `storageFee` | `LEGACY` | `components[chargeCode=STORAGE_FEE].value` | Express once as a component. |
| `pickPackFee` | `LEGACY` | `components[chargeCode=PICK_PACK_FEE].value` | Express once as a component. |
| `valueAddedServiceFee` | `LEGACY` | One or more value-added-service components | Prefer specific service charge codes; use the aggregate code only when the constituent services are unavailable. |
| `ppnRate` | `COMMON` | PPN component `taxDetail.rate` | Remove the duplicate consideration-level field and use shared tax detail on the PPN component. |
| `ppnAmount` | `LEGACY` | PPN component `value` | Remove the duplicate consideration-level field and use the tax component value. |

### Requirements that belong to flows or policies

The legacy schema requires `breakup` and `totalAmount`, while the README adds
lifecycle-specific rules. Phase 4 should translate them as follows:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| Freight price returned during selection and initialization | `FLOW` | Require canonical `currency`, `value`, and applicable components at the steps where the provider quotes or agrees a monetary Consideration. |
| PPN rate required for taxable lines | `FLOW` / `POLICY` | Require tax detail on applicable tax components; source the current rate from policy or regulation, never a hardcoded example. |
| Duty and tax estimate at selection, actual amount after customs clearance | `FLOW` | Carry estimated and later revised/final Considerations at their respective events; use the same component codes and stable revision semantics. |
| Weight discrepancy revision | `FLOW` | Send a revised Consideration through the update flow and link or correlate it to the prior value according to `LOG-CNS-003`. |
| COD collection reported at delivery and remittance reported later | `FLOW` | Carry collection/remittance through Performance, Payment, or Settlement artifacts once `LOG-CNS-004` defines the common record; do not mutate price attributes into a remittance ledger. |
| Conditional operational fees | `FLOW` / `POLICY` | Add the corresponding component only after the triggering event and applicable agreed policy; charge-code presence is not permission to levy a fee. |
| Total and component arithmetic | `POLICY` | Validate currency consistency, component sign convention, and total calculation using a validator or policy rule rather than duplicating derived flat fields. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Consideration schema aligned to current Beckn core | `absent` | Compare fare, component taxonomy, lifecycle-stage, and revision semantics when an official compatible schema is published. |
| Pinned `PriceSpecification/2.0` | `suitable for Release 1` | Use as the normative parent for total, currency, applicable quantity, and components. |
| Current Beckn Logistics `Fare` and `FareBreakup` | `incompatible` as dependencies; useful organizationally | Use the single-fare and typed-breakup boundaries, but do not copy duplicate amounts, India-specific examples, or current external references. |
| Current Beckn Logistics `Receipt` | `incompatible` as a dependency; useful organizationally | Keep receipt and payment acknowledgement outside Consideration; revisit only with a compatible document model. |
| ION `Tax/v1` | `under review` for Logistics reuse | Generalize or add a compatible attachment seam before referencing it from a PriceSpecification component. |
| ION `Payment/v1` and `Settlement/v1` | `partially reusable` | Reuse existing payment and reconciliation concepts; design the missing COD collection/remittance record separately. |
| Legacy ION `LogisticsConsideration` | `under review` | Use as the charge and flow source while removing duplicate totals and separating lifecycle concerns. |
| Release 1 `LogisticsConsideration` | `suitable for later release` | Author after the seven named decisions are resolved or explicitly deferred. |

## `LogisticsContract` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/contract/v1/attributes.yaml`
- Legacy schema name: `LogisticsContract`
- Approved Release 1 pack name: `LogisticsContract`
- Attachment point: `Contract.contractAttributes`
- Beckn v2 core ownership: `Contract` owns `id`, descriptor, commitments,
  considerations, participants, performances, settlements, lifecycle status,
  and `contractAttributes`.
- Existing Release 1 references: `IONBusinessRegistration`, `IONTaxDetail`,
  `IONPayment`, `IONSettlementReconciliation`, core `Descriptor`, core
  `Document`, pinned `Quantity`, and pinned `TimePeriod`.
- Beckn Logistics organizational references: `Consignment`, `SupportCase`,
  `Proof`, `ReturnPolicy`, `CancellationPolicy`, and `Receipt`. They are not
  approved Release 1 dependencies.
- Local structural reference: `IONTradeContract` demonstrates property-level
  reuse of invoice preferences, composed business registration, typed parent
  linkage, and one normalized cancellation object. Logistics must not inherit
  the retail or Trade contract pack.

The legacy pack is not one stable contract shape. It combines agreement
bindings, billing identity, payment terms, insurance, disputes and claims,
execution measurements, reverse-logistics requests, customs artifacts, and
one-off action responses. Phase 4 must preserve the ideas while relocating
facts to the core object or extension point that owns their lifecycle.

The legacy `parcel-contract.json` example does not validate against its own
authoring schema: `contractType`, `origin`, `destination`, `serviceLevel`, and
`agreedRate` are not declared properties. Those values already map more cleanly
to selected Resources, Commitments, Performances, Offers, and Considerations and
must not be added to the new contract pack merely to preserve the example.

Four intended annotations are also indented under `properties` in the legacy
schema and therefore become literal payload properties named
`x-ion-condition`: one each at the root, under `withholdingTax`, under
`cargoInsurance`, and under `beaCukaiDeclaration`. They are migration defects,
not public fields. Their rules must move to flow or policy validation.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-CON-001` | How Framework Agreement, parent, reverse, and reservation relationships are represented | Use typed `AgreementBinding` or `ContractRelationship` entries with relationship kind and globally meaningful reference scope. Coordinate the parent edge with `LOG-CMT-005`; do not retain unrelated string fields. |
| `LOG-CON-002` | How transaction-party business and billing identity is carried | Compose `IONBusinessRegistration` and the pinned reusable invoice-preference property where transaction-specific identity is required. Do not duplicate legacy NPWP/NIB formats or provider onboarding records. |
| `LOG-CON-003` | How invoice, tax, withholding, stamp-duty, credit, and payment facts are split | Keep invoice requests on Contract, price/tax amounts on Consideration, payment and credit terms on Settlement/Payment, reconciliation amounts on Settlement, and issued documents as typed Document references. Extend common packs only where a genuine gap remains. |
| `LOG-CON-004` | How selected cargo insurance terms are represented | Use one `CargoInsuranceAgreement` with policy reference, underwriter Participant reference, insured party, typed monetary limits, coverage extensions, and validity. The premium remains a Consideration component. |
| `LOG-CON-005` | How multiple disputes and claims are persisted | Replace singleton dispute/claim fields with repeatable `LogisticsCase` records inspired by Beckn Logistics `SupportCase`; use core Support for interaction and core Documents for evidence. Define one coherent case status model. |
| `LOG-CON-006` | Where observed weight and temperature exceptions live | Record measurements and exception events on Logistics Performance or Tracking. Contract cases may reference those observations but must not duplicate their raw telemetry. |
| `LOG-CON-007` | How reverse logistics and inventory release create downstream work | Represent them as child Contracts, Commitments, Resources, and Performances connected by typed relationships. Do not encode an imperative request as parallel arrays in the parent contract. |
| `LOG-CON-008` | How Incoterms and customs compliance are organized | Keep agreed Incoterms in `CrossBorderTerms`; organize declaration metadata and document references in `CustomsCompliance`; keep item classification on Resources and execution milestones on Performance. |
| `LOG-CON-009` | How cancellation and operational resolution decisions are recorded | Use one typed cancellation record aligned with `IONTradeContract` where applicable. Event-specific resolutions belong to the triggering Performance/update flow or a LogisticsCase, not unrelated flat strings. |
| `LOG-CON-010` | Whether transaction-time eKYC state is transmitted | Prefer a minimal Participant verification assertion or credential reference and keep sensitive evidence off-network. Do not expose rejection narratives or duplicate provider onboarding state in Contract attributes. |

### Organizational alignment

| Beckn or ION concept | Useful boundary | ION treatment |
|---|---|---|
| Core `Contract` | Canonical commitments, considerations, participants, performances, settlements, status, and descriptor documents | Reference these core members instead of copying shipment, price, party, execution, or payment facts into contract attributes. |
| `IONTradeContract` | Parent linkage, composed business identity, invoice preference refinement, and normalized cancellation | Follow these local structural patterns where semantics are cross-sector; do not inherit the Trade or Retail pack. |
| Beckn Logistics `Consignment` | Commercial grouping and shipment identity | Keep consignment facts with Logistics Resources and core Commitments; the Contract binds them rather than reproducing them. |
| Beckn Logistics `SupportCase` | Repeatable issue record with type, status, evidence, claim, and resolution | Use as naming and grouping inspiration for `LogisticsCase`, while aligning interaction with core Support and evidence with core Document. |
| Beckn Logistics `Proof` | Typed evidence associated with an execution event | Use core Document and Logistics Performance evidence structures; do not copy media URLs into Contract cases. |
| Beckn Logistics `ReturnPolicy` and `CancellationPolicy` | Terms governing eligibility, fees, and resolutions | Keep terms in Offer policy references. Contract records the selected policy reference and actual request/outcome only. |
| ION common tax, payment, settlement, and business-registration packs | Cross-sector Indonesian compliance and money movement | Reuse these owners rather than defining Logistics-only NPWP, tax, credit, invoice, or reconciliation shapes. |

The proposed Release 1 organization is:

```text
Contract (core)
  id, descriptor
  commitments[], consideration[], participants[]
  performance[], settlements[], status
  contractAttributes -> LogisticsContract

LogisticsContract
  relationships[] -> ContractRelationship
  buyerBusinessRegistration (only when transaction-specific)
  invoicePreferences
  cargoInsurance -> CargoInsuranceAgreement
  crossBorderTerms -> CrossBorderTerms
  customsCompliance -> CustomsCompliance
  cases[] -> LogisticsCase
  cancellation
```

These are components inside the `LogisticsContract` pack unless a named
decision explicitly moves them to a common pack. Raw execution observations,
payment events, and child-work requests are intentionally outside this shape.

### Field ownership and disposition

Every property path from the legacy `LogisticsContract` schema is listed below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsContract` | Keep through the Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `fwaReference` | `DEFER` | `ContractRelationship` or agreement binding | Replace the unscoped policy IRI with a typed Framework Agreement binding after `LOG-CON-001` defines identifier and version semantics. |
| `parentContractReference` | `DEFER` | `ContractRelationship` | Replace with a typed parent relationship coordinated with `LOG-CMT-005`. |
| `npwp`, `nib` | `COMMON` | `buyerBusinessRegistration` / referenced Participant | Replace the duplicated legacy formats with `IONBusinessRegistration`; the legacy punctuated 15-digit NPWP pattern is incompatible with the current 16-digit common definition. |
| `invoicePreferences` | `COMMON` | `LogisticsContract.invoicePreferences` | Reuse the pinned invoice-preference shape at property level and add only Logistics-required refinements; do not inherit the Retail contract. |
| `invoicePreferences.fakturaRequired` | `LEGACY` | `invoicePreferences.invoiceType` | Replace the boolean with an explicit tax-invoice request type. |
| `invoicePreferences.fakturaReference`, `invoicePreferences.fakturaStatus`, `invoicePreferences.fakturaPenggantiForReference` | `COMMON` | Tax detail and issued tax-invoice Document | Move issued Faktur Pajak identity and replacement state out of preferences; reuse `IONTaxDetail.eFakturRef` and add a common typed document only if the replacement lifecycle must be exchanged. |
| `invoicePreferences.invoicingModel` | `DEFER` | Invoice preference or Framework Agreement | Retain only if consolidated/FWA billing cannot be derived from the governing agreement and settlement schedule. |
| `invoicePreferences.coretaxIntegration` | `LEGACY` | Implementation detail | Remove the provider-system boolean from the public contract. |
| `invoicePreferences.coretaxTransactionId` | `DEFER` | Issued tax-invoice Document | Retain only as a regulated external-system reference in a typed document, never as evidence that an implementation uses Coretax. |
| `withholdingTax` | `LEGACY` | Consideration tax component plus Settlement and Documents | Remove the parallel aggregate object and distribute its facts to their lifecycle owners under `LOG-CON-003`. |
| `withholdingTax.applicable` | `POLICY` | Applicable tax policy / presence of PPH component | Derive applicability from party and transaction facts; do not transmit a competing boolean. |
| `withholdingTax.rate` | `COMMON` | PPH component `IONTaxDetail.rate` | Reuse shared tax detail on the applicable Consideration component. |
| `withholdingTax.withheldAmount` | `COMMON` | `IONSettlementReconciliation.withholdingAmount` | Move the realized withheld amount to Settlement; the tax component carries the agreed tax amount. |
| `withholdingTax.buktiPotongReference`, `withholdingTax.buktiPotongDate`, `withholdingTax.buktiPotongDocumentUrl` | `DEFER` | Typed withholding-certificate Document | Preserve as document metadata only after a common certificate shape is defined; use access-controlled core Document references. |
| `withholdingTax.withheldBy` | `COMMON` | Settlement participant/account responsibility | Replace the role-only enum with a core Participant reference or the shared settlement responsibility model. |
| `withholdingTax.remittedToDjp`, `withholdingTax.djpRemittanceReference` | `COMMON` | Settlement/tax-remittance evidence | Move post-payment remittance state and reference out of Contract terms. |
| `withholdingTax.x-ion-condition` | `LEGACY` | Flow or policy rule | Remove the accidentally declared payload property and preserve the intended condition in validation policy. |
| `ppnExemption` | `DEFER` | Tax detail plus `TaxExemptionEvidence` | Generalize the common Tax pack if exemption authority, evidence, and validity must be transmitted. |
| `ppnExemption.applicable` | `POLICY` | `IONTaxDetail.taxRegime` | Use `EXEMPT` and the presence of exemption evidence rather than a duplicate boolean. |
| `ppnExemption.reason`, `ppnExemption.exemptionLicenceReference`, `ppnExemption.validUntil` | `ION` | `TaxExemptionEvidence` | Preserve Indonesia-specific exemption classification, authority reference, and validity in a typed common tax evidence object after `LOG-CON-003`. |
| `stampDuty` | `LEGACY` | Consideration component plus e-Meterai Document | Split the tax amount from issued stamp evidence. |
| `stampDuty.applicable` | `POLICY` | Stamp-duty policy / component presence | Derive applicability; do not transmit a competing boolean. |
| `stampDuty.amount` | `COMMON` | Consideration tax/fee component value | Do not hardcode the legacy default; source the applicable amount from current policy. |
| `stampDuty.eMeteraiReference` | `ION` | Typed e-Meterai Document | Preserve the regulated reference as document metadata when issued. |
| `creditTermsDays`, `paymentDueDate` | `COMMON` | `IONPayment.creditTerms` | Reuse `CreditTerms` under `Settlement.settlementAttributes`; do not duplicate payment terms on Contract attributes. |
| `ekycFormReference`, `ekycStatus`, `ekycVerificationTimestamp`, `ekycRejectionReason` | `DEFER` | Participant verification assertion | Resolve `LOG-CON-010`; expose only the minimum result and credential reference needed for the transaction, with sensitive form and rejection detail off-network. |
| `cargoInsurance` | `LOGISTICS` | `CargoInsuranceAgreement` | Keep selected cargo coverage as a typed contract component under `LOG-CON-004`. |
| `cargoInsurance.policyReference` | `POLICY` | `CargoInsuranceAgreement.policyRef` | Keep a governed policy reference with stable IRI semantics. |
| `cargoInsurance.insuranceScope` | `LOGISTICS` | `CargoInsuranceAgreement.coverageScope` | Keep the selected ICC or other coverage scope in a controlled vocabulary. |
| `cargoInsurance.underwriterSubscriberId` | `CORE` | `Contract.participants[].id` | Reference the underwriter Participant; do not create a second party identifier. |
| `cargoInsurance.underwriterName` | `CORE` | Underwriter Participant descriptor | Remove the duplicate legal/display name. |
| `cargoInsurance.underwriterPolicyNumber` | `LOGISTICS` | `CargoInsuranceAgreement.policyNumber` | Keep the insurer-issued policy identifier, distinct from the ION policy IRI. |
| `cargoInsurance.insuredParty` | `LOGISTICS` | `CargoInsuranceAgreement.insuredParticipantId` | Replace the closed role-only enum with a core Participant reference, retaining role as descriptive classification if needed. |
| `cargoInsurance.coverageAmount`, `cargoInsurance.currency`, `cargoInsurance.deductible` | `LOGISTICS` | Typed monetary limits in `CargoInsuranceAgreement` | Keep coverage and deductible with one explicit currency using a reusable monetary shape. |
| `cargoInsurance.premiumAmount` | `LEGACY` | Insurance-premium Consideration component | Remove the duplicate amount from Contract terms. |
| `cargoInsurance.validFrom`, `cargoInsurance.validUntil` | `LOGISTICS` | `CargoInsuranceAgreement.validity` | Replace parallel timestamps with pinned `TimePeriod/2.0`. |
| `cargoInsurance.warRiskAddition`, `cargoInsurance.strikeRiskAddition`, `cargoInsurance.generalAverageParticipation` | `LOGISTICS` | `CargoInsuranceAgreement.coverageExtensions[]` | Replace parallel booleans with controlled selected coverage extensions. |
| `cargoInsurance.transitClauseExtension` | `DEFER` | Policy clause or coverage extension | Prefer a governed clause/document reference over unstructured legal text. |
| `cargoInsurance.x-ion-condition` | `LEGACY` | Flow or policy rule | Remove the accidentally declared payload property and preserve the intended freight/cross-border condition in policy. |
| `disputeReason`, `disputeReason.policyIri`, `disputeReason.description` | `LEGACY` | `LogisticsCase.reason` | Replace the singleton object with a case reason containing a policy reference and core Descriptor-compatible description. |
| `disputeState` | `LEGACY` | `LogisticsCase.status` | Replace the mixed dispute/claim enum with one coherent per-case lifecycle. |
| `disputeResolution`, `disputeResolution.outcome`, `disputeResolution.resolvedAt` | `LEGACY` | `LogisticsCase.resolution` | Move the outcome and resolution timestamp into the applicable repeatable case. |
| `disputeResolution.settlementAmount` | `COMMON` | Case resolution plus Consideration/Settlement | Keep an offered or agreed amount as a typed monetary value, and record actual discharge through Settlement. |
| `claimType` | `LOGISTICS` | `LogisticsCase.type` | Keep the issue classification on each case rather than once per Contract. |
| `claimDetail` | `LEGACY` | `LogisticsCase.claim` | Replace the singleton claim object with a typed section of the applicable case. |
| `claimDetail.policyIri`, `claimDetail.description` | `POLICY` | `LogisticsCase.policyRef` and descriptor | Preserve the governing policy reference and concise claim description. |
| `claimDetail.claimedAmount` | `LOGISTICS` | `LogisticsCase.claimedAmount` | Keep as a typed monetary amount using the Contract currency or an explicit currency. |
| `claimDetail.evidenceUrls`, `claimDetail.evidenceType` | `CORE` | `LogisticsCase.evidence[]` using core `Document` | Replace parallel URL/type fields with typed, secured Document references. |
| `claimDetail.reportedAt` | `LOGISTICS` | `LogisticsCase.reportedAt` | Keep the case creation/reporting timestamp. |
| `claimAssessment`, `claimAssessment.outcome`, `claimAssessment.rejectionReason`, `claimAssessment.inspectionRequired` | `LOGISTICS` | `LogisticsCase.assessment` | Keep one assessment per case; use a controlled outcome and concise rationale, with inspection represented as a linked Performance when scheduled. |
| `claimAssessment.offeredSettlement` | `LOGISTICS` | `LogisticsCase.assessment.offeredAmount` | Keep as a typed monetary offer; actual payment remains a Settlement. |
| `claimResolution`, `claimResolution.decision` | `LOGISTICS` | `LogisticsCase.resolution` | Keep the claimant's response or escalation decision in the case lifecycle. |
| `addressChangeReason`, `addressUnserviceableResolution` | `FLOW` | Logistics Performance exception or `LogisticsCase` | Record against the address/serviceability exception that triggered the decision; selected new address belongs to the updated Performance. |
| `returnReason`, `returnReason.code`, `returnReason.policyIri`, `returnReason.description` | `LEGACY` | Reverse `LogisticsCase.reason` and governing return policy | Normalize as a Descriptor-compatible reason plus policy reference; do not maintain a separate return-only reason shape. |
| `returnItems`, `returnItems[].resourceId`, `returnItems[].quantity` | `CORE` | Child reverse Contract commitments/resources | Replace the duplicate line list with core Commitment Resource references and typed quantities under `LOG-CON-007`. |
| `reverseContractReference` | `DEFER` | `ContractRelationship` | Replace with a typed `REVERSE_OF` or `GENERATED_RETURN` relationship. |
| `excursionDetail` | `LEGACY` | Logistics Performance exception event | Move the raw cold-chain observation out of Contract attributes under `LOG-CON-006`. |
| `excursionDetail.detectedAt`, `excursionDetail.location` | `LEGACY` | Performance event time and core Location | Use typed event timestamp and Location rather than an unstructured location string. |
| `excursionDetail.measuredTemperature`, `excursionDetail.declaredMin`, `excursionDetail.declaredMax` | `LEGACY` | Typed temperature Measurements | Replace unitless numbers with typed quantities and reference the agreed Resource/Offer range. |
| `excursionDetail.excursionDurationMinutes` | `LEGACY` | Typed duration on Performance event | Replace the minutes-only integer with an ISO 8601 duration. |
| `excursionResolution`, `excursionResolution.decision` | `FLOW` | Performance exception resolution or `LogisticsCase` | Record the decision in the exception/claim flow, not as a singleton Contract field. |
| `discrepancyDetail` | `LEGACY` | Logistics Performance measurement event | Move the weight discrepancy observation out of Contract attributes. |
| `discrepancyDetail.declaredWeight`, `discrepancyDetail.measuredWeight` | `LEGACY` | Typed weight Measurements | Replace unitless numbers with pinned `Quantity/2.0`; reference the declared Resource measurement where possible. |
| `discrepancyDetail.measurementTimestamp`, `discrepancyDetail.measurementLocation` | `LOGISTICS` | Performance measurement event | Keep the timestamp and controlled operational point on the event. |
| `discrepancyDetail.scalePhotoUrl` | `CORE` | Performance evidence using core `Document` | Replace the raw URL with secured typed evidence. |
| `discrepancyDetail.measuredDimensions` | `LEGACY` | Typed dimensional measurement | The legacy object has no declared shape; replace it with the same typed dimensions used by the measured Resource. |
| `disputeCounter`, `disputeCounter.counterWeight` | `LEGACY` | `LogisticsCase.counterproposal` | Keep a typed counter-measurement only when a case disputes the provider observation. |
| `disputeCounter.evidenceUrls`, `disputeCounter.evidenceType` | `CORE` | `LogisticsCase.evidence[]` using core `Document` | Replace parallel evidence fields with typed Documents. |
| `inventoryReleaseRequest` | `FLOW` | New child Contract/Commitment request | Do not persist an imperative request shape in the parent Contract under `LOG-CON-007`. |
| `inventoryReleaseRequest.skus`, `inventoryReleaseRequest.quantities` | `LEGACY` | Child Commitment Resource references and quantities | Replace fragile parallel arrays with paired core Resource entries and typed quantities. |
| `inventoryReleaseRequest.destinationType`, `inventoryReleaseRequest.destinationAddress` | `LEGACY` | Child Logistics Performance destination | Replace the enum plus untyped object with the selected destination role and core Address/Location on the child execution. |
| `incoterms`, `incotermsVersion`, `incotermsNamedPlace` | `LOGISTICS` | `CrossBorderTerms` | Keep the agreed rule, edition, and named place as one structured trade-term component. |
| `x-ion-condition` | `LEGACY` | Cross-border flow rule | Remove the accidentally declared root payload property and require `CrossBorderTerms` only in applicable flows. |
| `beaCukaiDeclaration` | `ION` | `CustomsCompliance.declaration` | Keep Indonesia customs declaration metadata as a structured compliance component. |
| `beaCukaiDeclaration.declarationType`, `beaCukaiDeclaration.declarationNumber`, `beaCukaiDeclaration.declarationDate`, `beaCukaiDeclaration.ceisaReceiptNumber` | `ION` | Customs declaration identity and receipt | Keep controlled declaration type and CEISA-issued identifiers/date. |
| `beaCukaiDeclaration.nikDeclarant` | `DEFER` | Declarant Participant/credential reference | Avoid transmitting raw NIK; reference the authorized declarant and retain sensitive identity off-network. |
| `beaCukaiDeclaration.hsCodeTariffPost` | `LEGACY` | Logistics Resource customs classification | Move item-specific HS/tariff classification to each affected Resource rather than one Contract-wide string. |
| `beaCukaiDeclaration.cifValueIdr`, `beaCukaiDeclaration.exchangeRateUsed` | `ION` | `CustomsCompliance.valuation` | Keep declared customs valuation and applied official exchange rate with explicit source/date and currency semantics. |
| `beaCukaiDeclaration.x-ion-condition` | `LEGACY` | Cross-border flow or policy rule | Remove the accidentally declared payload property and preserve the intended CEISA condition in validation. |
| `inatradePermits` | `ION` | `CustomsCompliance.permits[]` | Keep regulated permit references as typed compliance documents. |
| `inatradePermits[].permitType`, `inatradePermits[].permitNumber`, `inatradePermits[].issuingMinistry`, `inatradePermits[].validUntil` | `ION` | Permit Document metadata | Keep controlled permit identity, issuer, and validity. |
| `inatradePermits[].documentUrl` | `CORE` | Core `Document.url` | Use an access-controlled typed Document reference. |
| `lartasClassification` | `ION` | Logistics Resource regulatory classification | Move prohibited/restricted-goods classification to each affected Resource; Contract policy validates the aggregate shipment. |
| `aseanSingleWindowReference` | `ION` | `CustomsCompliance` document/reference | Keep the external clearance reference when applicable. |
| `fumigationCertificate` | `LOGISTICS` | `CustomsCompliance.certificates[]` | Keep as a typed compliance Document when wood packaging requires it. |
| `fumigationCertificate.certificateNumber`, `fumigationCertificate.treatmentType`, `fumigationCertificate.treatmentDate`, `fumigationCertificate.facilityCode` | `LOGISTICS` | Fumigation certificate metadata | Preserve the certificate identity and ISPM 15 treatment metadata. |
| `fumigationCertificate.documentUrl` | `CORE` | Core `Document.url` | Use an access-controlled typed Document reference. |
| `phytosanitaryCertificate` | `LOGISTICS` | `CustomsCompliance.certificates[]` | Keep as a typed compliance Document for applicable agricultural Resources. |
| `phytosanitaryCertificate.certificateNumber`, `phytosanitaryCertificate.issuingAuthority` | `LOGISTICS` | Phytosanitary certificate metadata | Preserve certificate identity and issuer. |
| `phytosanitaryCertificate.documentUrl` | `CORE` | Core `Document.url` | Use an access-controlled typed Document reference. |
| `xbReturnDecision` | `FLOW` | Customs-rejection `LogisticsCase` or child Contract relationship | Record the chosen resolution after rejection and create a child Contract when movement is required. |
| `cancellationReason` | `LEGACY` | `LogisticsContract.cancellation.reason` | Normalize to the same cancellation boundary used by `IONTradeContract`. |
| `cancellationReason.id` | `LEGACY` | Cancellation reason `Descriptor.code` or policy reference | Remove the second reason identifier; use one machine-readable code and a separate policy reference when needed. |
| `cancellationReason.descriptor`, `cancellationReason.descriptor.code`, `cancellationReason.descriptor.shortDesc` | `CORE` | Core `Descriptor` | Replace the partial inline Descriptor with a core schema reference. |
| `cancellationReasonCode` | `LEGACY` | Cancellation reason `Descriptor.code` | Remove the third duplicate reason code. |
| `pickupFailedResolution` | `FLOW` | Pickup-failure Performance exception or cancellation | Record the decision in the triggering flow; cancellation uses the normalized cancellation object. |
| `buyerResolutionDeadline` | `FLOW` | Applicable `LogisticsCase` or exception event | Keep only when a response deadline is communicated for a specific case/event. |
| `codPartialReason` | `FLOW` | COD collection exception / `LogisticsCase.reason` | Record against the partial-collection event and COD settlement record, not as an unscoped Contract string. |

### Requirements that belong to flows or policies

The legacy schema has no root `required` list, while its descriptions and README
assign numerous conditional requirements. Those rules belong to flows and
policies:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| FWA-governed pricing, credit, and policy inheritance | `FLOW` / `POLICY` | Require a resolvable agreement binding in applicable B2B flows and validate selected Offer, Consideration, and Settlement terms against it. |
| B2B identity, tax invoice, withholding, and stamp duty | `FLOW` / `POLICY` | Compose current common schemas and require them only for the applicable party, tax, invoice, and value thresholds. |
| Named cargo insurance and freight/cross-border coverage | `FLOW` / `POLICY` | Require `CargoInsuranceAgreement` when selected terms or regulation demand it; verify the underwriter Participant and coverage period. |
| Dispute and claim progression | `FLOW` | Define case creation, evidence exchange, assessment, resolution, and escalation transitions for each independent case. |
| Temperature excursion and weight discrepancy | `FLOW` | Report typed observations on Performance/Tracking, then create or update a referenced case when the observation is disputed or claimed. |
| Reverse shipment and inventory release | `FLOW` | Create child core Contracts and Commitments with typed relationships; validate that referenced Resources and quantities belong to the parent transaction. |
| Incoterms, customs declaration, permits, LARTAS, and certificates | `FLOW` / `POLICY` | Require only for applicable cross-border routes and Resource categories; validate document validity and authority at the step where each artifact becomes available. |
| Cancellation, failed pickup, address failure, partial COD, and customs rejection | `FLOW` | Carry request reason and resolution in the triggering API flow, then persist only the normalized outcome or case/child relationship needed for contract history. |
| Sensitive identity and evidence URLs | `POLICY` | Apply data minimization, access control, and residency rules; prefer participant or Document references over raw identity values and public URLs. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Contract schema aligned to current Beckn core | `absent` | Compare agreement binding, insurance, case, cross-border, and cancellation organization when an official compatible schema is published. |
| Core `Contract`, `Document`, `Support`, `Performance`, and `Settlement` | `suitable for Release 1` with gaps | Use their lifecycle ownership directly; fill only Logistics-specific case and agreement gaps. |
| `IONTradeContract` | `incompatible` as a parent; useful local precedent | Reuse cross-sector property patterns or extract common structures without importing retail semantics. |
| ION common business-registration, tax, payment, and settlement packs | `partially reusable` | Compose existing definitions and generalize only the identified tax-document, COD, and certificate gaps. |
| Current Beckn Logistics `SupportCase`, `Proof`, `ReturnPolicy`, `CancellationPolicy`, `Receipt`, and `Consignment` | `incompatible` as dependencies; useful organizationally | Use their semantic boundaries as review input without copying schemas, v1-shaped examples, or older-core mappings. |
| Legacy ION `LogisticsContract` | `under review` | Use as the scenario inventory while removing duplicated core data, action payloads, raw telemetry, and common-pack concepts. |
| Release 1 `LogisticsContract` | `suitable for later release` | Author after the ten named decisions are resolved or explicitly deferred. |

## `LogisticsPerformance` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/performance/v1/attributes.yaml`
- Legacy schema name: `LogisticsPerformance`
- Approved Release 1 pack name: `LogisticsPerformance`
- Attachment point: `Performance.performanceAttributes`
- Beckn v2 core ownership: `Performance` owns `id`, lifecycle `status`, the
  `commitmentIds[]` it satisfies, and `performanceAttributes`.
- Existing Release 1 references: core `Descriptor`, core `Document`, core
  `Location`, core `Participant`, pinned `Address`, pinned `Quantity`, and
  pinned `TimePeriod`.
- Beckn Logistics organizational references: `Shipment`, `LogisticsRoute`,
  `Waypoint`, `TrackingUpdate`, `Alert`, `Proof`, `Driver`, `Vehicle`, and
  `DeliverySlot`. They are not approved Release 1 dependencies.
- Local structural reference: `IONTradePerformance` demonstrates core Document
  evidence, typed quantities, assigned-agent refinement, stops, and SLA breach
  records. Logistics must not inherit the retail or Trade pack.

`LogisticsPerformance` is the ION shipment-execution aggregate corresponding
organizationally to Beckn Logistics `Shipment`. It should not wrap another
top-level Shipment object: the core Performance already supplies the execution
identity, status, and Commitment linkage.

The legacy pack also overlaps the separate `LogisticsTracking` pack. Core
`Tracking` owns the live URL or streaming handle, high-level active state, and
`trackingAttributes`; Performance owns the durable execution plan, milestones,
observations, proofs, and history. A current-location snapshot may appear in a
Tracking response but must not become a second Performance state history.

The legacy `parcel-delivery-status.json` example does not validate against its
own schema. It uses undeclared `currentState`, `lastUpdateAt`, and
`estimatedDeliveryAt` properties; the schema instead declares core Performance
status, multiple timing records, and `estimatedDeliveryTime`. Phase 4 must build
a new example from the selected model.

The legacy authoring file contains 34 textual `x-ion-condition` occurrences.
Twenty-four are repeated keys at the root `properties` indentation, so YAML
parsing collapses them into one literal payload property named
`x-ion-condition`. Two more are similarly nested as payload properties under
financial attribution and state timing. Correctly scoped annotations still do
not replace flow requirements. None of these condition strings should be
migrated as data fields.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-PERF-001` | How AWB, booking, bill-of-lading, ticket, storage, and per-leg carrier identifiers are represented | Use repeatable typed `ServiceReference` and Document references rather than mutually exclusive flat strings. Preserve issuer and scope where needed. |
| `LOG-PERF-002` | How pickup windows, route legs, stops, schedules, milestones, and actual times are organized | Use `PickupExecution`, ordered `RouteLeg`/stop components, pinned `TimePeriod`, and timestamped `PerformanceEvent` milestones. Do not maintain parallel date/window/timestamp fields when one typed structure suffices. |
| `LOG-PERF-003` | How pickup, delivery, handoff, label, manifest, and acknowledgement evidence is represented | Use typed `LogisticsProof` records backed by core `Document`, Location, timestamp, and Participant references. Never expose raw OTPs, unrestricted media URLs, or inline label bytes by default. |
| `LOG-PERF-004` | How assigned agents, carriers, vehicles, hubs, and facilities are referenced | Use core Contract Participant IDs and Logistics Resource/location references. Keep only transaction-time assignment facts; do not duplicate names, plates, photos, or provider identities. |
| `LOG-PERF-005` | Boundary between Performance history and live Tracking | Performance keeps durable events and observations. Core Tracking plus `LogisticsTracking` keeps the URL/stream handle, credentials, refresh guidance, current location snapshot, and live ETA. |
| `LOG-PERF-006` | How temperature, weight, dimensions, capacity, emissions, and other measurements are typed | Use pinned `Quantity/2.0` with controlled unit codes and a timestamp/location/device envelope. Avoid unitless values and parallel value/unit objects. |
| `LOG-PERF-007` | Which capacity facts belong to Commitment versus execution | Requested/proposed capacity, hold, and confirmation belong to selection/Commitment. Performance records actual allocation/use and loading/manifest milestones, linked to the committed reservation. |
| `LOG-PERF-008` | How delivery attempts, customs holds, discrepancies, and excursions are represented | Use repeatable `PerformanceEvent`/`LogisticsAlert` records with reason, time, location, evidence, deadline, and resolution reference. Create a Contract `LogisticsCase` only when an event becomes a dispute or claim. |
| `LOG-PERF-009` | How warehouse receipt, picking, allocation, ready-to-ship, and handoff are represented | Use typed inventory execution and handoff records referencing Resources, Commitments, Participants, Locations, and child Contract relationships. Remove parallel SKU/quantity arrays and gateway-routing internals. |
| `LOG-PERF-010` | How current state, transition history, dwell commitments, and SLA breach evidence relate to the state registry | Core `Performance.status` is current state. Keep normalized transition and breach history; derive live dwell/time-remaining/cascade projections. Coordinate codes and transitions with `LogisticsPerformanceStates`. |
| `LOG-PERF-011` | Whether and how shipment sustainability evidence remains in this pack | Retain a typed `SustainabilityReport` component for the draft, using quantities and evidence references; plan later extraction if the GLEC/CSRD model becomes independently reusable. Carbon credits/offset purchases remain separate Resources, Contracts, and Settlements. |
| `LOG-PERF-012` | Where leg-level financial attribution belongs | Allocate charges through Consideration components and discharge through Settlement, referencing route-leg IDs when needed. Performance must not carry a second billing ledger. |

### Organizational alignment

| Beckn or ION concept | Useful boundary | ION treatment |
|---|---|---|
| Core `Performance` | Execution identity, current status, and Commitment linkage | Use directly; never duplicate `currentState`, performance identity, or committed Resource links. |
| Beckn Logistics `Shipment` | One execution aggregate containing route, proof, alerts, and shipment progress | Treat `LogisticsPerformance` as this aggregate rather than nesting or copying `Shipment`. |
| Beckn Logistics `LogisticsRoute` and `Waypoint` | Ordered route, legs/stops, locations, schedule, and actual arrival/departure | Use similar named internal components with core Location and typed timing. |
| Beckn Logistics `Proof` | Typed evidence for pickup, delivery, and handoff | Use the boundary but back evidence with core Document and privacy-aware verification results. |
| Beckn Logistics `TrackingUpdate` and `Alert` | Timestamped progress or exception event | Use as organizational inspiration for durable `PerformanceEvent`/`LogisticsAlert` history; do not import their older-core identifiers or duplicate live Tracking. |
| Beckn Logistics `Driver` and `Vehicle` | Assigned human and transport asset | Reference Contract Participants and Logistics Resources instead of copying identity/profile fields. |
| `IONTradePerformance` | Stops, assigned-agent extensions, core Document evidence, typed quantities, and SLA breach history | Reuse cross-sector shapes or extract shared components where appropriate; do not inherit retail modes or requirements. |

The proposed Release 1 organization is:

```text
Performance (core)
  id
  status
  commitmentIds[]
  performanceAttributes -> LogisticsPerformance

LogisticsPerformance
  serviceReferences[] -> ServiceReference
  pickup -> PickupExecution
  route -> LogisticsRoute
    legs[] -> RouteLeg
    stops[] -> LogisticsStop
  events[] -> PerformanceEvent / LogisticsAlert
  assignments[] -> LogisticsAssignment
  proofs[] -> LogisticsProof
  measurements[] -> LogisticsMeasurement
  attempts[] -> DeliveryAttempt
  warehouseExecution -> WarehouseExecution
  sla -> SLAExecution
  sustainability -> SustainabilityReport
```

These named structures are internal components of the
`LogisticsPerformance` pack unless a later common extraction is approved.
`LogisticsTracking` remains a separate pack attached to core Tracking.

### Field ownership and disposition

Every property path from the legacy `LogisticsPerformance` schema is listed
below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsPerformance` | Keep through the Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `awbNumber`, `bookingReference`, `billOfLadingReference`, `ticketReference`, `storageContractReference` | `LOGISTICS` | `serviceReferences[]` | Replace pattern-specific flat identifiers with typed references under `LOG-PERF-001`. |
| `x-ion-condition` | `LEGACY` | Flow requirements | Remove the duplicate root property produced by misplaced annotations and restate each applicable rule in flows. |
| `awbAllocationMode`, `preAllocatedAwbBlockRef` | `LOGISTICS` | AWB `ServiceReference` allocation metadata | Keep allocation mode and block reference only for an AWB reference; require the block only for pre-allocation. |
| `pickupModel` | `LOGISTICS` | `PickupExecution.model` | Keep the selected pickup operating model. |
| `requestedPickupDate`, `requestedPickupWindow`, `requestedPickupWindow.from`, `requestedPickupWindow.until` | `LEGACY` | `PickupExecution.requestedWindow` | Replace split date/time fields with pinned `TimePeriod/2.0`; time-only windows require an associated date and time zone. |
| `confirmedPickupDate`, `confirmedPickupWindow`, `confirmedPickupWindow.from`, `confirmedPickupWindow.until` | `LEGACY` | `PickupExecution.confirmedWindow` | Replace parallel date/window fields with one date-time TimePeriod. |
| `pickupBatchId` | `LOGISTICS` | `PickupExecution.batchReference` | Keep the provider-issued bulk-pickup grouping reference. |
| `pickupBatchShipmentCount` | `DEFER` | Derived batch aggregate | Derive from the batch manifest unless an asserted count is required for audit. |
| `pickupAgentPointId` | `LOGISTICS` | `PickupExecution.lodgementLocationId` | Reference the selected Provider location or Logistics Resource. |
| `pickupLodgementTimestamp` | `LOGISTICS` | Lodgement `PerformanceEvent.timestamp` | Record as the actual counter/locker handoff event. |
| `appliedCutoffs` | `LOGISTICS` | `PickupExecution.appliedCutoffs[]` | Keep resolved transaction deadlines separately from recurring Offer schedules. |
| `appliedCutoffs[].cutoffType`, `appliedCutoffs[].deadline`, `appliedCutoffs[].status` | `LOGISTICS` | `AppliedCutoff` | Keep the controlled cutoff kind, absolute deadline, and observed outcome. |
| `appliedCutoffs[].timeRemaining` | `LEGACY` | Derived at presentation time | Remove the volatile duration; derive it from the deadline and current time. |
| `appliedCutoffs[].lateAcceptancePolicy` | `POLICY` | Selected Offer policy reference | Do not repeat policy terms on Performance; record an exception outcome event if late acceptance occurs. |
| `appliedCutoffs[].description` | `CORE` | Applied-cutoff Descriptor | Keep only concise human-readable context not already conveyed by the code or policy. |
| `shippingLabelUrl`, `shippingLabelFormat` | `CORE` | Label core `Document` | Replace the parallel fields with a typed Document carrying URL, MIME/standard, and label format metadata. |
| `shippingLabelBytes` | `DEFER` | Secured label Document/content endpoint | Do not inline printer payload bytes by default; retain only if an explicit size, security, and transport contract is defined. |
| `routingTopology` | `LOGISTICS` | `LogisticsRoute.topology` | Keep the confirmed high-level topology when it affects expected stops or state transitions. |
| `estimatedTAT` | `DEFER` | Derived route estimate / SLA | Prefer estimated arrival plus the selected SLA; retain a duration only if its start event is explicit. |
| `estimatedDeliveryTime` | `LOGISTICS` | Destination stop `estimatedArrival` | Keep one current delivery estimate on the final stop or route summary. |
| `scheduledDeparture`, `scheduledArrival` | `LOGISTICS` | Route or leg schedule | Place scheduled times on the applicable route leg/stop rather than the aggregate when multiple legs exist. |
| `pickupTimestamp`, `deliveryTimestamp` | `LOGISTICS` | Pickup/delivery `PerformanceEvent.timestamp` | Record actual milestones as events and derive summary timestamps if needed. |
| `proofOfPickupType`, `proofOfDeliveryType` | `LEGACY` | `LogisticsProof.type` | Remove duplicate selector fields; each proof record declares its own type and milestone. |
| `proofOfPickup`, `proofOfDelivery` | `LEGACY` | `proofs[]` | Replace two ad hoc objects with repeatable typed proof records. |
| `proofOfPickup.type`, `proofOfDelivery.type` | `LOGISTICS` | `LogisticsProof.type` | Use one controlled proof-type vocabulary. |
| `proofOfPickup.value`, `proofOfDelivery.value` | `DEFER` | Core `Document` or verification result | Replace untyped/raw values with secured evidence or a non-secret verification outcome. |
| `proofOfPickup.timestamp`, `proofOfDelivery.timestamp` | `LOGISTICS` | `LogisticsProof.capturedAt` | Keep the evidence capture time. |
| `proofOfPickup.gps`, `proofOfDelivery.gps` | `LEGACY` | `LogisticsProof.location` | Replace an untyped string with core Location/GeoJSON. |
| `proofOfPickup.capturedBy` | `CORE` | `LogisticsProof.capturedByParticipantId` | Reference the assigned Participant rather than embedding identity. |
| `proofOfDelivery.signatory`, `proofOfDelivery.signatoryRelation` | `DEFER` | `LogisticsProof.recipient` | Minimize personal data; keep a Participant reference or recipient role/relationship only when policy requires it. |
| `deliveryOtp` | `DEFER` | Off-network handoff credential / proof verification | Never echo the usable OTP in Performance updates. Exchange it through an approved secret channel and record only verification outcome/evidence. |
| `trackingUrl` | `CORE` | `Tracking.url` | Remove the duplicate Performance field and use core Tracking. |
| `liveGps`, `liveGps.lat`, `liveGps.lng`, `liveGps.timestamp`, `liveGps.accuracy` | `LEGACY` | `LogisticsTracking.currentLocation` | Move the live snapshot to the Tracking extension and use typed geometry/accuracy units. |
| `lastScanTimestamp`, `lastScanLocation` | `LEGACY` | Latest scan `PerformanceEvent` | Replace the lossy last-only pair with event history; use core Location. |
| `agentDetails` | `LEGACY` | `assignments[]` | Replace the embedded profile with transaction-time assignment references. |
| `agentDetails.name`, `agentDetails.phoneProxy`, `agentDetails.photoUrl` | `CORE` | Assigned Participant and secured descriptor/document | Do not duplicate identity; disclose only minimized presentation/contact data allowed at the current state. |
| `agentDetails.vehicleType`, `agentDetails.vehiclePlate` | `CORE` | Assigned Vehicle Resource | Reference the transport asset rather than copying type and registration. |
| `hubId` | `LOGISTICS` | Event/stop Logistics Resource or location reference | Associate the hub with the applicable event or route stop, not the entire aggregate. |
| `legs` | `LOGISTICS` | `LogisticsRoute.legs[]` | Keep ordered execution legs for multimodal journeys. |
| `legs[].legId`, `legs[].legSequence`, `legs[].legType` | `LOGISTICS` | `RouteLeg` identity/order/type | Keep stable leg identity, explicit order, and controlled leg role. |
| `legs[].origin`, `legs[].destination` | `LEGACY` | `RouteLeg.origin` / `RouteLeg.destination` using core Location | Replace the inline location objects with typed locations/stops. |
| `legs[].origin.locationType`, `legs[].destination.locationType` | `LOGISTICS` | Route stop role/facility type | Keep one controlled facility/stop classification. |
| `legs[].origin.locationCode`, `legs[].destination.locationCode` | `LOGISTICS` | Route stop external code | Keep UN/LOCODE, IATA, or facility code with an explicit code scheme. |
| `legs[].origin.address`, `legs[].destination.address` | `CORE` | Core/pinned Address on Location | Replace untyped objects with the approved Address shape and ION address extension where needed. |
| `legs[].carrierId` | `CORE` | `RouteLeg.carrierParticipantId` | Reference a Contract Participant. |
| `legs[].carrierName`, `legs[].carrierType` | `LEGACY` | Carrier Participant descriptor/role | Remove duplicate name and infer or retain role through Participant attributes. |
| `legs[].vesselOrFlightRef` | `DEFER` | Assigned transport Resource/reference | Split vessel, voyage, flight, rail, or fleet identifiers into typed asset/service references rather than one ambiguous string. |
| `legs[].subBookingReference`, `legs[].masterBillReference`, `legs[].houseBillReference` | `LOGISTICS` | Leg-scoped `ServiceReference` / Document | Keep typed booking and transport-document identifiers scoped to the issuing carrier and leg. |
| `legs[].scheduledDeparture`, `legs[].scheduledArrival`, `legs[].actualDeparture`, `legs[].actualArrival` | `LOGISTICS` | `RouteLeg` schedule and milestone events | Keep planned times on the leg and actual times as events; use consistent time-zone-aware date-times. |
| `legs[].legStatus` | `DEFER` | Route-leg status Descriptor | Align with the canonical Performance state registry and avoid a conflicting miniature state machine. |
| `legs[].financialAttribution` | `LEGACY` | Consideration/Settlement allocation keyed by leg ID | Remove the billing sub-ledger from Performance under `LOG-PERF-012`. |
| `legs[].financialAttribution.billingFromSubscriberId`, `legs[].financialAttribution.billingToSubscriberId` | `CORE` | Consideration/Settlement Participant references | Replace subscriber strings with core Participant references in the financial owner. |
| `legs[].financialAttribution.legAmount`, `legs[].financialAttribution.currency` | `COMMON` | Leg-attributed Consideration component | Express the amount once in the canonical monetary shape. |
| `legs[].financialAttribution.x-ion-condition` | `LEGACY` | Flow rule | Remove the accidentally declared payload property. |
| `temperatureReading` | `LEGACY` | `measurements[]` temperature observation | Replace the singleton object with repeatable typed measurements. |
| `temperatureReading.value`, `temperatureReading.unit` | `LEGACY` | Pinned `Quantity/2.0` | Use a controlled temperature unit code rather than the one-value enum. |
| `temperatureReading.timestamp` | `LOGISTICS` | Measurement timestamp | Keep when the observation was made. |
| `temperatureReading.location` | `LEGACY` | Measurement core Location | Replace the free-text location with a typed reference. |
| `temperatureReading.deviceId` | `LOGISTICS` | Measurement device Resource/reference | Keep traceability to the calibrated sensing device where required. |
| `temperatureReading.excursionDetected` | `DEFER` | Derived limit evaluation / exception event | Derive from the agreed range and measurement; emit an exception event when the result is authoritative. |
| `coldChainIntegrityVerified` | `DEFER` | Cold-chain assessment/attestation | Replace the aggregate boolean with a signed assessment referencing the underlying measurement interval and evidence. |
| `actualWeight` | `LEGACY` | `measurements[]` weight observation | Replace the singleton object with a typed measurement. |
| `actualWeight.value`, `actualWeight.unit` | `LEGACY` | Pinned `Quantity/2.0` | Use controlled weight unit codes. |
| `actualWeight.measuredAt`, `actualWeight.measurementTimestamp` | `LOGISTICS` | Measurement event location role and timestamp | Keep the operational point and observation time; link evidence when disputed. |
| `reservedCapacity`, `reservedCapacity.quantity`, `reservedCapacity.unit`, `reservedCapacity.reservationToken` | `DEFER` | `LogisticsCommitment.capacityReservation` | Move selection-time reservation quantity/token to Commitment under `LOG-PERF-007`; Performance may reference it. |
| `reservationHoldUntil`, `proposedDeparture`, `requestedDepartureDate`, `capacityConfirmed` | `DEFER` | Commitment/service-window negotiation | Move pre-confirmation hold and proposed/requested schedule to Commitment; confirmation is derived from the active Commitment. |
| `manifestVerified` | `LOGISTICS` | Manifest-verification `PerformanceEvent` / proof | Replace the boolean with timestamped verification evidence. |
| `loadingTimestamp`, `departureTimestamp`, `arrivalTimestamp` | `LOGISTICS` | Performance milestone events | Record actual loading/departure/arrival against the relevant leg or stop. |
| `requestedSailing` | `DEFER` | Commitment requested service window | Keep the requested sailing with selection/Commitment. |
| `confirmedSailing` | `LOGISTICS` | Route-leg schedule / service reference | Keep the confirmed sailing on the booked leg. |
| `boardingWindow`, `boardingWindow.from`, `boardingWindow.until` | `LEGACY` | Route stop `TimePeriod` | Replace the ad hoc object with pinned `TimePeriod/2.0`. |
| `boardingGate` | `LOGISTICS` | Boarding stop/location detail | Keep the assigned gate on the applicable route stop. |
| `customsHoldReason` | `FLOW` | Customs-hold `LogisticsAlert.reason` | Record as a typed exception event and link the customs declaration/case. |
| `customsResolutionPath` | `FLOW` | Alert/case resolution | Record the chosen resolution against the customs-hold event; create child work where re-export/destruction requires it. |
| `estimatedClearanceDuration` | `DEFER` | Customs stop estimated resolution | Keep only with an explicit estimation timestamp and start basis; prefer a revised stop ETA. |
| `attemptNumber`, `ndrReasonCode`, `ndrTimestamp`, `attemptsRemaining`, `buyerResolutionDeadline` | `LOGISTICS` | `attempts[]` / delivery-attempt alert | Replace aggregate counters and last-event fields with repeatable attempt records; derive remaining attempts from policy and history. |
| `valueAddedServicesSelected` | `CORE` | Commitment Resources/Offer selection | Move selected services to Commitment; Performance events record their execution outcomes. |
| `expectedReceiptDate` | `LOGISTICS` | Warehouse receipt schedule | Keep as a date-time/window with time-zone semantics where operationally relevant. |
| `inboundReceiptTimestamp` | `LOGISTICS` | Warehouse receipt event | Keep the actual receipt milestone. |
| `receivedQuantities` | `LOGISTICS` | `WarehouseExecution.receipts[]` | Keep Resource-level received-versus-expected observations without SKU-specific coupling. |
| `receivedQuantities[].skuId` | `LEGACY` | Receipt `resourceId` | Reference the committed inventory Resource. |
| `receivedQuantities[].receivedQty`, `receivedQuantities[].expectedQty` | `LEGACY` | Receipt typed quantities | Replace integers with pinned Quantity and derive expected quantity from the Commitment when possible. |
| `inboundDiscrepancy` | `LEGACY` | Warehouse discrepancy alert/case | Replace the singleton object with a typed event referencing affected receipt lines. |
| `inboundDiscrepancy.hasDiscrepancy` | `LEGACY` | Presence/status of discrepancy event | Remove the redundant boolean. |
| `inboundDiscrepancy.discrepancyDetail` | `DEFER` | Alert Descriptor / Contract case | Keep concise event description; detailed dispute evidence belongs to `LogisticsCase`. |
| `pickedSkus` | `LEGACY` | `WarehouseExecution.inventoryMovements[]` | Replace SKU-specific lines with Resource-referenced inventory movement records. |
| `pickedSkus[].skuId`, `pickedSkus[].quantity` | `LEGACY` | Inventory movement Resource ID and typed Quantity | Reference the Resource and use pinned Quantity. |
| `warehouseLocationAllocated` | `LOGISTICS` | Warehouse allocation Location/slot reference | Keep only the minimum facility/bin reference appropriate for the receiving parties. |
| `capacityAllocated` | `LEGACY` | Warehouse allocation measurements | Replace the ad hoc aggregate with typed capacity quantities. |
| `capacityAllocated.cbm`, `capacityAllocated.pallets` | `LEGACY` | Pinned Quantity entries | Use controlled volume and pallet unit codes. |
| `inboundInstructions` | `DEFER` | Commitment instructions / warehouse stop instructions | Keep only execution-specific instructions not already agreed in the Commitment or Resource handling data. |
| `transportContractReference` | `DEFER` | Core Contract relationship | Move child transport linkage to `LogisticsContract.relationships[]`. |
| `readyToShip` | `CORE` | `Performance.status` | Represent readiness as a canonical state, not a duplicate boolean. |
| `readyToShipTimestamp` | `LOGISTICS` | READY_FOR_PICKUP transition event | Keep the state-entry timestamp in history. |
| `readyToShipBy` | `CORE` | Transition actor Participant ID | Replace the role-only enum with the Participant that asserted readiness. |
| `rtsPickupToken` | `DEFER` | Off-network handoff credential | Do not expose the usable token in status payloads; record only verification evidence at handoff. |
| `parentWarehouseContractRef`, `spawnedTransportContractRefs` | `DEFER` | Core Contract relationships | Move parent/child links to typed relationships under `LOG-CON-001`. |
| `parentWarehouseCommitmentRefs` | `CORE` | `Performance.commitmentIds[]` or child Contract relationship | Use core Commitment IDs; avoid a second warehouse-specific list. |
| `dispatchOriginWarehouseBppId` | `CORE` | Contract Participant/Provider reference | Reference the warehouse Participant rather than duplicating network identity. |
| `rtsNotificationRouting` | `LEGACY` | Network routing layer | Remove gateway/BPP routing mechanics from the domain Performance schema. |
| `rtsNotificationRouting.warehouseBppEmits`, `rtsNotificationRouting.transportBppReceives`, `rtsNotificationRouting.ionGatewayRoutingRequired` | `LEGACY` | Protocol routing configuration | Derive from sender/recipient context and registry routing; do not transmit booleans/IDs as performance facts. |
| `rtsNotificationRouting.handoffEvidence` | `LEGACY` | `LogisticsProof` / handoff events | Preserve domain acknowledgement evidence without the routing wrapper. |
| `rtsNotificationRouting.handoffEvidence.warehouseConfirmedAt`, `rtsNotificationRouting.handoffEvidence.transportAcknowledgedAt` | `LOGISTICS` | Handoff event timestamps | Keep the producer confirmation and receiver acknowledgement as distinct events. |
| `rtsNotificationRouting.handoffEvidence.rtsAcknowledgementRef` | `LOGISTICS` | Handoff proof/document reference | Keep a typed acknowledgement reference when required. |
| `slaStatus` | `DEFER` | `SLAExecution` derived summary | Derive from applicable commitments and breach history; retain only if a signed point-in-time assessment is required. |
| `currentStateTimingStatus` | `LEGACY` | Core status plus `SLAExecution` | Remove the parallel current-state snapshot and keep authoritative transition/breach records. |
| `currentStateTimingStatus.currentState` | `CORE` | `Performance.status.code` | Remove the duplicate state value. |
| `currentStateTimingStatus.enteredAt` | `LOGISTICS` | Latest state-transition event | Derive from normalized history. |
| `currentStateTimingStatus.maxDwellDuration`, `currentStateTimingStatus.alertThresholdDuration` | `POLICY` | Selected Offer SLA/timing commitment | Reference the agreed commitment; do not copy policy inputs on each update. |
| `currentStateTimingStatus.dwellSoFar`, `currentStateTimingStatus.timeRemainingInCommitment` | `LEGACY` | Derived values | Compute from transition time, current time, and committed duration. |
| `currentStateTimingStatus.dwellStatus`, `currentStateTimingStatus.cascadeEffect` | `DEFER` | SLA assessment/forecast event | Keep only when an authoritative assessment or forecast is exchanged, with calculation time and method. |
| `currentStateTimingStatus.x-ion-condition` | `LEGACY` | Flow/policy rule | Remove the accidentally declared payload property. |
| `stateTimingHistory` | `LOGISTICS` | `SLAExecution.stateHistory[]` | Keep normalized state transition and dwell evidence. |
| `stateTimingHistory[].state`, `stateTimingHistory[].enteredAt`, `stateTimingHistory[].exitedAt` | `CORE` | State code and transition timestamps | Use codes from `LogisticsPerformanceStates` and time-zone-aware timestamps. |
| `stateTimingHistory[].dwellDuration` | `DEFER` | Derived transition duration | Derive from entered/exited timestamps unless an asserted duration is necessary for audit. |
| `stateTimingHistory[].maxDwellCommitment` | `POLICY` | Referenced SLA commitment | Avoid copying the Offer term; retain the policy/version reference used for evaluation. |
| `stateTimingHistory[].wasBreached`, `stateTimingHistory[].breachDuration` | `LOGISTICS` | SLA breach record | Replace boolean-plus-optional-duration with a breach record present only when breached. |
| `sustainabilityReport` | `DEFER` | `SustainabilityReport` | Retain as an internal component for this draft under `LOG-PERF-011`, with future extraction noted. |
| `sustainabilityReport.carbonEmissionKgCO2e` | `LEGACY` | Typed CO2e Quantity | Replace the unit-encoded property name with Quantity using a controlled kg CO2e unit. |
| `sustainabilityReport.carbonEmissionCalculationMethod`, `sustainabilityReport.carbonCalculationScope`, `sustainabilityReport.fuelType` | `LOGISTICS` | `SustainabilityReport` methodology fields | Keep controlled calculation method, boundary, and fuel classification with version/evidence where applicable. |
| `sustainabilityReport.fuelConsumptionLitres`, `sustainabilityReport.safAllocationLitres` | `LEGACY` | Typed fuel Quantity entries | Replace unit-encoded numeric properties with Quantity. |
| `sustainabilityReport.carbonOffsetPurchased` | `LEGACY` | Referenced carbon-credit Contract/Settlement | Remove the unsupported boolean; an offset claim must reference the acquired/retired credit and evidence. |
| `sustainabilityReport.carbonOffsetRegistryReference` | `DEFER` | Carbon-credit Resource/retirement Document | Keep only as a typed external registry reference with verification evidence. |
| `sustainabilityReport.carbonOffsetAmountKgCO2e` | `LEGACY` | Typed retired-credit Quantity | Replace the unit-encoded number and link it to the retirement record. |
| `sustainabilityReport.greenCertification` | `DEFER` | Core Documents/credentials | Replace bare strings with verifiable certification references and validity. |
| `hygieneProtocolApplied` | `DEFER` | Operational attestations/evidence | Keep applied protocol codes only with issuer, time, and evidence when a flow or policy requires attestation. |

### Requirements that belong to flows or policies

The legacy schema has no root `required` list, but its duplicated annotations
and README assign many fields to specific states and patterns. Phase 4 should
translate them as follows:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| Pattern-specific shipment/service identifier | `FLOW` | Require the applicable typed ServiceReference at confirmation, with issuer and scope. |
| Pickup model, requested/confirmed window, batch, or counter lodgement | `FLOW` | Require only the structures relevant to the selected pickup model and record actual handoff as an event. |
| Labels, proofs, OTP, manifests, and handoff acknowledgement | `FLOW` / `POLICY` | Exchange typed Documents or verification results at the state where produced; apply privacy, authentication, size, and retention rules. |
| Multileg route and carrier schedule | `FLOW` | Require ordered legs and assigned Participant/Resource references only for applicable freight or multimodal patterns. |
| Cold-chain, weight, dimensional, and capacity measurements | `FLOW` / `POLICY` | Require typed observations when the Resource/Offer policy calls for them; emit exception events when agreed limits are exceeded. |
| Customs hold, delivery attempts, and operational exceptions | `FLOW` | Append events with reason, deadline, evidence, and resolution; promote to a Contract case only when disputed or claimed. |
| Warehouse receipt, picking, allocation, ready-to-ship, and cross-BPP handoff | `FLOW` | Use Resource-referenced execution records and core relationships; keep protocol routing outside the domain payload. |
| State timing and SLA | `FLOW` / `POLICY` | Validate transitions against `LogisticsPerformanceStates`, calculate dwell against the selected Offer terms, and persist breach evidence rather than volatile counters. |
| Sustainability and hygiene attestations | `FLOW` / `POLICY` | Require only for opted-in or regulated programs, with methodology, issuer, validity, and supporting evidence. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Performance/Shipment schema aligned to current Beckn core | `absent` | Compare route, proof, alert, measurement, assignment, and history semantics when an official compatible schema is published. |
| Core `Performance`, `Tracking`, `Document`, `Location`, and Participant/Commitment linkage | `suitable for Release 1` | Use directly and keep their lifecycle boundaries explicit. |
| Current Beckn Logistics `Shipment`, `Route`, `Waypoint`, `TrackingUpdate`, `Alert`, `Proof`, `Driver`, `Vehicle`, and `DeliverySlot` | `incompatible` as dependencies; useful organizationally | Use their semantic boundaries and names as review input without copying older-core IDs, duplicated status, or live-tracking state. |
| `IONTradePerformance` | `incompatible` as a parent; useful local precedent | Reuse or extract cross-sector stops, evidence, assignment, quantity, and SLA patterns without importing retail modes. |
| Legacy ION `LogisticsPerformance` | `under review` | Use as the scenario inventory while removing live Tracking, selection-time Commitment data, common financial data, raw credentials, and routing internals. |
| Release 1 `LogisticsPerformance` | `suitable for later release` | Author after the twelve named decisions and the Performance/Tracking boundary are resolved or explicitly deferred. |

## `LogisticsTracking` v1

### Sources and attachment point

- Legacy schema: `schema/extensions/logistics/tracking/v1/attributes.yaml`
- Legacy schema name: `LogisticsTracking`
- Approved Release 1 pack name: `LogisticsTracking`
- Attachment point: `Tracking.trackingAttributes`
- Beckn v2 core ownership: `Tracking` owns the Contract reference, active or
  inactive status, tracking URL/stream handle, and `trackingAttributes`.
- Existing Release 1 references: core `Tracking`, core `Contract`, core
  `Participant`, core `GeoJSONGeometry`, core `Document`, and pinned `Quantity`.
- Beckn Logistics organizational references: `TrackingUpdate`,
  `LogisticsRoute`, `Driver`, and `Vehicle`. They are not approved Release 1
  dependencies.
- Coordinated Release 1 pack: `LogisticsPerformance` owns durable route,
  assignment, milestone, observation, proof, and exception history.

Core Tracking intends `contract` to be an ID-only reference, but its
machine-readable schema composes the full core Contract and adds `required:
[id]`. Because core Contract separately requires `commitments`, the resulting
schema still requires commitments in the tracking reference. This is a core
schema inconsistency, not permission to duplicate the full Contract in every
tracking response. Phase 4 must correct or explicitly work around it.

The legacy `gps-tracking.json` example also does not validate against its own
extension schema. It declares `trackingUrl`, which belongs to core
`Tracking.url`, and `pollingIntervalSeconds`, while the schema declares
`refreshIntervalSeconds`. It also shows only the extension object rather than
the enclosing core Tracking object. Phase 4 needs a complete replacement
example.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-TRK-001` | How the core Tracking Contract-reference inconsistency is resolved | Correct core Tracking to reference an ID-only Contract shape, or add an approved local reference schema. Do not require or echo the full Contract merely to satisfy the current `allOf`. |
| `LOG-TRK-002` | How transport mechanism and tracking capabilities are distinguished | Replace the mixed `trackingType` enum with a transport `mode` and optional `capabilities[]`. Core `Tracking.url` remains the actual endpoint/handle. |
| `LOG-TRK-003` | How authenticated tracking access is represented safely | Declare an authentication scheme, credential reference, and expiry only when needed. Never place reusable bearer tokens or API keys directly in schema examples, logs, or durable Contract/Performance history. |
| `LOG-TRK-004` | How a point-in-time location/ETA snapshot is typed and interpreted | Use a timestamped `TrackingSnapshot` with GeoJSON Point, typed accuracy/speed, bounded heading, and absolute estimated arrival. Treat it as transient, not canonical Performance history. |
| `LOG-TRK-005` | Which route, agent, and vehicle facts may appear in Tracking | Keep planned route and assignment in LogisticsPerformance. Tracking may carry references and a current/remaining route geometry only when required for the live response; it must not duplicate profiles or registrations. |
| `LOG-TRK-006` | How carrier handoff and endpoint templates are represented | Identify the endpoint owner/carrier Participant when useful. Keep reusable URL templates in Provider/Offer capability metadata, and send only the resolved core Tracking URL per transaction. |

### Organizational alignment

| Beckn or ION concept | Useful boundary | ION treatment |
|---|---|---|
| Core `Tracking` | Contract reference, active state, and URL/stream handle | Use directly and remove all extension-level duplicates. |
| Beckn Logistics `TrackingUpdate` | Timestamped status/location event | Use as organizational evidence for snapshot naming, but durable updates belong to LogisticsPerformance events rather than the tracking handle. |
| Beckn Logistics `LogisticsRoute` | Planned route and geometry | Keep the authoritative route on LogisticsPerformance; Tracking may return a current or remaining geometry snapshot only. |
| Beckn Logistics `Driver` and `Vehicle` | Assigned human and asset | Use Contract Participant and Logistics Resource references from Performance; do not repeat names, phones, plates, or photos in Tracking. |
| `LogisticsPerformance` Phase 3 model | Durable assignment, route, event, and observation history | Tracking references that execution state and supplies only access metadata or a transient snapshot. |

The proposed Release 1 organization is:

```text
Tracking (core)
  contract -> ID-only Contract reference (after LOG-TRK-001)
  status
  url
  trackingAttributes -> LogisticsTracking

LogisticsTracking
  mode
  capabilities[]
  refreshInterval
  access -> TrackingAccess
  eventTypes[]
  snapshot -> TrackingSnapshot
    location
    observedAt
    accuracy
    heading
    speed
    estimatedArrivalAt
    assignment references
  currentRouteGeometry (optional)
  endpointOwnerParticipantId (optional)
```

`TrackingAccess` and `TrackingSnapshot` are internal components of the
`LogisticsTracking` pack. They do not create a second event history.

### Field ownership and disposition

Every property path from the legacy `LogisticsTracking` schema is listed below.

| Legacy field path | Class | Proposed owner | Release 1 disposition |
|---|---|---|---|
| `@context`, `@type` | `CORE` | `LogisticsTracking` | Keep through the Beckn `Attributes` extension contract; update the context URL and type to the Release 1 pack. |
| `trackingType` | `LEGACY` | `LogisticsTracking.mode` and `capabilities[]` | Split transport mechanism from data capability under `LOG-TRK-002`; `LIVE_GPS` is a capability while URL, polling, webhook, and WebSocket describe access modes. |
| `refreshIntervalSeconds` | `LEGACY` | `LogisticsTracking.refreshInterval` | Replace the unit-encoded integer with an ISO 8601 duration and require it only for polling or snapshot-refresh modes. |
| `credentials` | `DEFER` | `TrackingAccess` | Replace the inline credentials object with safe access metadata under `LOG-TRK-003`. |
| `credentials.type` | `LOGISTICS` | `TrackingAccess.authScheme` | Keep a controlled authentication-scheme identifier when the endpoint is not anonymously accessible. |
| `credentials.value` | `DEFER` | Secure credential delivery / reference | Do not embed reusable secrets in the tracking extension; use a short-lived signed URL or an approved out-of-band credential reference. |
| `credentials.validUntil` | `LOGISTICS` | `TrackingAccess.expiresAt` | Keep the access expiry for short-lived handles or credential references. |
| `webhookEvents` | `LOGISTICS` | `LogisticsTracking.eventTypes[]` | Keep the subscribed event categories for webhook/event-stream modes; align state-change values with `LogisticsPerformanceStates`. |
| `currentLocation` | `LEGACY` | `TrackingSnapshot.location` plus snapshot metadata | Replace the ad hoc location object with a timestamped typed snapshot. |
| `currentLocation.latitude`, `currentLocation.longitude` | `LEGACY` | Core `GeoJSONGeometry` Point | Replace parallel coordinates with a standards-based Point geometry. |
| `currentLocation.timestamp` | `LOGISTICS` | `TrackingSnapshot.observedAt` | Keep the observation timestamp so consumers can judge staleness. |
| `currentLocation.accuracyMeters` | `LEGACY` | `TrackingSnapshot.accuracy` | Replace the unit-encoded number with pinned Quantity using a metre unit code. |
| `currentLocation.heading` | `LOGISTICS` | `TrackingSnapshot.heading` | Keep with explicit degree semantics, a 0–360 constraint, and the observation timestamp. |
| `currentLocation.speedKmh` | `LEGACY` | `TrackingSnapshot.speed` | Replace the unit-encoded number with pinned Quantity using a speed unit code. |
| `etaMinutes` | `LEGACY` | `TrackingSnapshot.estimatedArrivalAt` | Prefer an absolute, time-zone-aware estimate; derive relative minutes at presentation time. |
| `routePolyline` | `LEGACY` | `LogisticsTracking.currentRouteGeometry` | Replace provider-specific encoded polyline text with GeoJSON LineString when a live/remaining route snapshot is required; planned route remains on Performance. |
| `agentDetails` | `LEGACY` | Tracking snapshot assignment references | Remove the duplicated embedded profile under `LOG-TRK-005`. |
| `agentDetails.name`, `agentDetails.phone`, `agentDetails.photoUrl`, `agentDetails.languagesSpoken` | `CORE` | Assigned Contract Participant / Performance assignment | Reference the assigned Participant and apply state-based data minimization; do not copy presentation/contact/profile data into Tracking. |
| `agentDetails.vehicleType`, `agentDetails.vehiclePlate` | `CORE` | Assigned Vehicle Resource / Performance assignment | Reference the transport Resource rather than duplicating its type or registration. |
| `trackingHandoffToCarrier` | `LEGACY` | `endpointOwnerParticipantId` / resolved core URL | Remove the redundant boolean; a distinct endpoint owner indicates carrier handoff. |
| `carrierTrackingUrlPattern` | `DEFER` | Provider/Offer tracking capability metadata | Move reusable templates out of transaction Tracking. Core `Tracking.url` carries the resolved endpoint. |

### Requirements that belong to flows or policies

The legacy schema requires `trackingType` and uses correctly scoped
`x-ion-condition` annotations on several properties. Phase 4 should translate
them as follows:

| Legacy rule group | Class | Phase 4 treatment |
|---|---|---|
| Tracking mode and core URL | `FLOW` | Require core `url`, core `status`, and the selected mode in `/on_track`; validate that the URL scheme is compatible with the mode. |
| Polling refresh interval | `FLOW` | Require only for polling/snapshot modes and enforce network minimums to prevent abusive polling. |
| Webhook event selection | `FLOW` | Require only for webhook or event-stream modes and align event codes with Performance states/alerts. |
| Authenticated endpoint access | `FLOW` / `POLICY` | Require safe access metadata only when needed; enforce short expiry, redaction, transport security, and secret-handling policy. |
| Current location, ETA, route geometry, and assignment references | `FLOW` / `POLICY` | Include only when authorized for the current Performance state; enforce precision, freshness, minimization, and retention limits. |
| Carrier handoff | `FLOW` | Return the resolved carrier-owned core URL and optional owner Participant reference; never require clients to expand a URL template. |

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 Tracking extension aligned to current Beckn core | `absent` | Compare access mode, snapshot, privacy, and carrier-handoff semantics when an official compatible schema is published. |
| Core `Tracking` | `suitable for Release 1` after a reference fix | Use status, URL, and attributes directly; resolve the Contract reference inconsistency under `LOG-TRK-001`. |
| Current Beckn Logistics `TrackingUpdate`, `LogisticsRoute`, `Driver`, and `Vehicle` | `incompatible` as dependencies; useful organizationally | Use their event, geometry, and assignment boundaries without copying older-core identity/status structures. |
| Legacy ION `LogisticsTracking` | `under review` | Use as the access-mode and snapshot source while removing core URL duplication, inline secrets, embedded profiles, and provider-specific geometry. |
| Release 1 `LogisticsTracking` | `suitable for later release` | Author after the six named decisions and core Contract-reference inconsistency are resolved or explicitly deferred. |

## `LogisticsPerformanceStates` v1

### Sources and artifact boundary

- Legacy registry:
  `schema/extensions/logistics/performance-states/v1/states.yaml`
- Legacy documentation:
  `schema/extensions/logistics/performance-states/v1/README.md`
- Approved Release 1 artifact name: `LogisticsPerformanceStates`
- Runtime owner: `Performance.status.code` plus Logistics flow validation.
- Artifact kind: versioned state-machine registry, not an OpenAPI schema pack
  and not an `Attributes` attachment.
- Legacy scope: 10 machines, 133 state occurrences, 81 distinct state codes,
  and 146 directed transition edges.
- Beckn Logistics organizational references: local status enums on `Shipment`,
  `TrackingUpdate`, `Waypoint`, and `Alert`. The current repository has no
  equivalent canonical multi-pattern transition registry.

The Beckn Logistics objects are useful vocabulary references, but not a source
that ION can inherit. Only five of the ten current `Shipment.status` values,
four of nine `TrackingUpdate.status` values, one of four `Waypoint.status`
values, and none of the three `Alert.status` values exactly overlap the 81 ION
state codes. More importantly, those Beckn schemas declare independent enums;
they do not define allowed transitions, terminal outcomes, required data,
guards, side effects, or Contract-status aggregation.

The legacy profile incorrectly claims an attachment to
`beckn:performance-states Attributes`, and the root README describes an
attribute pack with nonexistent `attributes.yaml`, `schema.json`, JSON-LD, and
renderer artifacts. Release 1 must publish and validate this as a distinct
registry artifact, as already anticipated by the migration plan.

### Named decisions

| ID | Decision required | Phase 3 default |
|---|---|---|
| `LOG-STATE-001` | Where and how the artifact is published | Treat it as a release-local, versioned state-machine registry referenced by Logistics flows. Do not invent a Beckn attachment point or generated schema-pack files. |
| `LOG-STATE-002` | What machine-readable grammar and validator govern the registry | Define a formal registry grammar and dedicated validator covering unique IDs, initial state, target existence, reachability, terminal consistency, required-field references, typed triggers/effects, and flow references. |
| `LOG-STATE-003` | How ION state codes relate to Beckn Logistics status enums | Maintain ION's richer pattern-specific vocabulary and document optional coarse mappings. Do not copy or claim equivalence with the current independent Beckn enums. |
| `LOG-STATE-004` | How terminal state and terminal outcome are represented | Use one authoritative per-state terminal declaration with a typed outcome such as SUCCESS, CANCELLED, FAILED, RETURNED, TRANSFERRED, or DISPUTED. Remove the competing machine-level terminal list or generate it. |
| `LOG-STATE-005` | How multiple Performance outcomes determine core `Contract.status` | Define an aggregation rule across all required Performances. A single terminal Performance must not complete or cancel a multi-performance Contract incorrectly. |
| `LOG-STATE-006` | How state-specific required data is referenced | Replace bare legacy field names with stable semantic requirement IDs or schema JSON Pointers targeting the reorganized `LogisticsPerformance`, Contract relationship, proof, and warehouse structures. |
| `LOG-STATE-007` | How variants, guards, side effects, and follow-up work are represented | Replace free-text `triggers[]` with typed `flowRefs[]`, `guards[]`, and `effects[]`. Refund release and storage billing are effects; reverse/customs/attempt handling are flow references; cold-chain/reweigh conditions are guards. |
| `LOG-STATE-008` | Where rider-identity disclosure rules belong | Keep disclosure authorization in flow/privacy policy keyed by state and assignment model, not as an unqualified graph boolean. |
| `LOG-STATE-009` | Whether topology and reverse flows are separate machines or composed variants | Keep separate machines only when transition graphs materially differ; define reusable fragments/composition for shared delivery, attempt, RTO, and customs sequences to prevent drift. |
| `LOG-STATE-010` | How registry changes remain compatible after publication | Version machine IDs and state semantics as public contracts. Additive transitions require review; renamed/removed states or changed terminal outcomes require a new release. |

### Organizational alignment with Beckn Logistics

| Beckn Logistics object | Current status vocabulary | ION treatment |
|---|---|---|
| `Shipment` | Ten coarse shipment states; five exact ION overlaps | Use only as a coarse comparison vocabulary. Core Performance already owns status, and ION needs pattern-specific execution states. |
| `TrackingUpdate` | Nine event-status values; four exact ION overlaps | Treat as evidence that tracking events may expose a coarse status, not as the canonical transition graph. |
| `Waypoint` | Four stop-local states; one exact ION overlap | Keep stop state local to route execution. Do not merge it automatically into aggregate Performance state. |
| `Alert` | Three alert-lifecycle states and separate alert types | Keep alert lifecycle distinct from Performance lifecycle; an alert may be open while Performance remains in a normal or exception state. |
| Beckn Logistics canonical state-machine registry | Absent | Reconcile later if an official compatible registry is published. |

The proposed Release 1 registry shape is:

```text
registryVersion
machines
  <machineId>
    description
    initialState
    states
      <stateCode>
        category
        contractStatusContribution
        terminalOutcome (only when terminal)
        transitions[]
          to
          guards[]
          flowRefs[]
          effects[]
        requirements[]
          requirementId
          targetPointer
        disclosurePolicyRefs[]
```

The exact syntax remains a Phase 4 decision, but the semantic separation is
required. A validator should be able to resolve every reference without
parsing human prose.

### Legacy machine inventory and disposition

All ten legacy machines are included below.

| Legacy machine ID | Scope | Release 1 disposition |
|---|---|---|
| `hyperlocal-pre-assigned` | Hyperlocal delivery with rider assigned at confirmation | Keep as a candidate machine; externalize disclosure policy and repair terminal declarations. |
| `hyperlocal-fifo` | Hyperlocal FIFO assignment at pickup | Keep if assignment timing changes the graph materially; otherwise compose the assignment/disclosure difference over a shared hyperlocal graph. |
| `parcel-p2p` | Direct parcel delivery | Keep as a topology-specific candidate or compose from parcel fragments. |
| `parcel-p2h2p` | Parcel through one hub | Keep as a topology-specific candidate; repair unreachable disposal outcome. |
| `parcel-p2h2h2p` | Parcel through origin and destination hubs | Keep as a topology-specific candidate; repair unreachable disposal outcome. |
| `parcel-reverse-qc` | Consumer return with origin QC | Keep as a child reverse-Contract machine; classify disputed termination separately from success. |
| `freight-capacity` | Capacity-based road/ocean/air/rail/river execution | Keep; separate return-flow launch from terminal outcome and align leg milestones with LogisticsPerformance. |
| `roro` | Roll-on/Roll-off port and sailing execution | Keep; decide whether missed sailing is recoverable, terminal, or launches rebooking. |
| `xb` | Export, international transit, import customs, and domestic delivery | Keep; repair missing RTO target and model rejection/destruction/remediation outcomes explicitly. |
| `warehouse-inventory` | Storage and inventory execution rather than transit | Keep as a distinct machine; model dispatch as child work and define expiry/return entry paths. |

### Legacy graph defects requiring Phase 4 resolution

The following findings come from a mechanical graph audit of `states.yaml`:

| Machine | Finding | Required resolution |
|---|---|---|
| `hyperlocal-pre-assigned`, `hyperlocal-fifo` | Machine-level terminal list names `FAILED`, but neither graph defines that state. Both define terminal `RETURNED_TO_ORIGIN` without listing it. | Define explicit failure/return outcomes or remove the stale entries; use one terminal source of truth. |
| `hyperlocal-fifo` | `CANCELLED` is declared but unreachable from the initial path. | Add the intended cancellation transitions or remove the state. |
| `parcel-p2h2p`, `parcel-p2h2h2p` | `RTO_DISPOSED` is terminal but unreachable. | Add the policy-controlled disposal transition or remove the state for these topologies. |
| `freight-capacity` | `FREIGHT_RETURN_INITIATED` is listed as terminal, explicitly marked `terminal: false`, and unreachable. | Treat it as a typed transition/effect into a child reverse flow, or define its next states. |
| `roro` | `MISSED_SAILING` is listed as terminal but explicitly marked non-terminal; `CANCELLED` is unreachable. | Define rebooking/cancellation transitions and one authoritative outcome. |
| `xb` | `DELIVERY_ATTEMPT_FAILED` targets undefined `RTO_INITIATED`; `DESTROY_IN_PLACE` is terminal but unreachable. | Add explicit, policy-guarded remediation states/transitions or link to a child reverse/destruction flow. |
| `warehouse-inventory` | `RETURN_TO_SENDER` is terminal but omitted from the terminal list; `STORAGE_CONTRACT_EXPIRED` is unreachable. | Reconcile terminal metadata and define the expiry/return entry transitions. |

The legacy flow references also disagree with the registry:

| Legacy flow reference | Registry result | Phase 4 treatment |
|---|---|---|
| Parcel pattern `#parcel` | No such machine; three topology-specific parcel IDs exist | Select the machine from the confirmed routing topology using an explicit resolvable reference. |
| Hyperlocal pattern `#hyperlocal-fifo OR #hyperlocal-pre-assigned` | Not a single valid fragment/reference | Define deterministic selection based on assignment model. |
| Reverse variant `#hyperlocal-reverse`, `#freight-reverse`, `#xb-reverse` | No such machines | Add reviewed child reverse machines or point to existing valid machines; do not leave dangling references. |
| Reverse variant `#parcel-reverse-qc` | Resolves | Preserve after graph and terminal-outcome validation. |

### Structural-field disposition

| Legacy registry field | Class | Release 1 disposition |
|---|---|---|
| `states` | `LEGACY` | Rename to `machines` or otherwise make clear that its children are state machines, not individual states. |
| `<machine>.description` | `LOGISTICS` | Keep concise machine scope documentation. |
| `<machine>.terminal` | `LEGACY` | Remove or generate from per-state terminal outcomes under `LOG-STATE-004`. |
| `<machine>.transitions` | `LEGACY` | Rename/restructure as a state map so each node owns its outgoing transitions and metadata. |
| `<state>.next` | `LOGISTICS` | Keep as typed transition targets and validate that every target exists. |
| `<state>.terminal` | `LEGACY` | Replace boolean with typed `terminalOutcome`; absence means non-terminal. |
| `<state>.requiredFields` | `LEGACY` | Replace bare names with resolvable requirement IDs or JSON Pointers under `LOG-STATE-006`. |
| `<state>.triggers` | `LEGACY` | Split free text into typed guards, flow references, and effects under `LOG-STATE-007`. |
| `<state>.exposesRiderIdentity` | `POLICY` | Replace with privacy/disclosure policy references evaluated against assignment model and caller authorization. |
| `<state>.description` | `LOGISTICS` | Keep only state-specific semantics not already defined by the state code/catalog. |

The 14 distinct legacy `requiredFields` names are all review inputs, not valid
future pointers. `agentDetails`, proof and timestamp fields, `hubId`,
`manifestVerified`, warehouse quantity/picking fields, and
`transportContractReference` were reorganized during the LogisticsPerformance
and LogisticsContract inventories. Phase 4 must map them to assignments,
events, proofs, stops, warehouse execution, and Contract relationships.

### Contract-status aggregation and flow ownership

The legacy README's direct mapping from one terminal Performance state to core
`Contract.status` is insufficient when a Contract has multiple Performances.
Release 1 needs a deterministic aggregation rule covering at least:

- all required Performances completed successfully;
- one required Performance cancelled while others remain active;
- a return or replacement child Contract while the original is complete;
- a terminal dispute, customs rejection, missed sailing, or failed pickup;
- warehouse storage that spawns multiple child transport Contracts; and
- optional/supporting Performances that must not block completion.

State-specific required data and transition guards belong to flow validation.
Policy determines eligibility, disclosure, fees, and timeouts. The registry
provides stable codes and graph semantics but must not embed prose that only a
human can interpret.

### Upstream reconciliation outcome

| Candidate | Current status | Later action |
|---|---|---|
| Official Beckn Logistics v2 state-machine registry aligned to current Beckn core | `absent` | Compare machine/state identifiers, terminal outcomes, and transition semantics if an official registry is published. |
| Current Beckn Logistics `Shipment`, `TrackingUpdate`, `Waypoint`, and `Alert` enums | `incompatible` as canonical state machines; useful vocabulary references | Document coarse mappings where useful while preserving distinct object lifecycles and ION's validated graphs. |
| Core `Performance.status` and `Contract.status` | `suitable for Release 1` with aggregation rules | Carry detailed state in `Performance.status.code`; define deterministic multi-performance contribution to the four core Contract states. |
| Legacy ION `LogisticsPerformanceStates` | `under review` | Use as the scenario/state source while repairing graph defects, stale field references, free-text triggers, profile claims, and dangling flow references. |
| Release 1 `LogisticsPerformanceStates` | `suitable for later release` | Author only with the dedicated grammar, validator, graph tests, flow-reference tests, and ten named decisions resolved or explicitly deferred. |

## Phase 3 completion

Phase 3 is complete. The ledger now covers all nine Logistics extension-point
packs plus the standalone performance-state registry:

1. `LogisticsResource`
2. `LogisticsProvider`
3. `LogisticsParticipant`
4. `LogisticsOffer`
5. `LogisticsCommitment`
6. `LogisticsConsideration`
7. `LogisticsContract`
8. `LogisticsPerformance`
9. `LogisticsTracking`
10. `LogisticsPerformanceStates`

Phase 4 can now proceed as vertical slices in the migration-plan order. Each
slice must resolve or explicitly defer its named decisions before normative
artifacts are authored.
