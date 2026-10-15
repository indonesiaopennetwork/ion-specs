# Release 1 Logistics upstream-alignment ledger

> **Status:** In progress  
> **Target:** ION Release 1 draft  
> **Legacy source:** `indonesiaopennetwork/ion-specs` at
> `33e6b4c40feabecf6b0f6a827b488ff82998c735`  
> **Organizational reference:** `beckn/logistics` at
> `4d98c3c9b7244f32f3a900272adc990d870df0bf`  
> **Current coverage:** `LogisticsResource`, `LogisticsProvider`,
> `LogisticsParticipant`, `LogisticsOffer`

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
| `LOG-PROV-004` | How provider sites and warehouses relate to core locations | Keep addresses in `Provider.availableAt`; define `LogisticsHub` records that reference those location IDs and carry logistics-specific site capabilities. |
| `LOG-PROV-005` | How licences and association memberships are asserted | Reuse `IONBusinessRegistration` for NIB and SIUP. Represent other licences and memberships as typed, verifiable credentials rather than status booleans. |

### Organizational alignment

The current Beckn Logistics repository offers three useful boundaries:

| Beckn organizational concept | Useful boundary | ION treatment |
|---|---|---|
| `Carrier` | Transport provider, supported services, coverage, fleet, and hubs | Use as inspiration for logistics capabilities and `ServiceCoverage`; do not copy identity, tax, or India-specific fields. |
| `Operator` | Entity coordinating a logistics network or multiple carriers | Use as inspiration for the `OPERATOR` and `AGGREGATOR` provider roles. Operational counts remain out of the schema unless a concrete protocol need is established. |
| `Hub` | Logistics facility with a location, type, capacity, and facilities | Define an independent `LogisticsHub` component referencing `Provider.availableAt` rather than embedding another address. |

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
  hubs[] -> LogisticsHub
  businessRegistration -> IONBusinessRegistration
  credentials[]

ServiceCoverage
  coverageType
  geo or locationIds
  ionSubdivisions (ION layer only)

LogisticsHub
  locationId -> Provider.availableAt[*].id
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
| `warehouseLocations` | `LOGISTICS` | `LogisticsProvider.hubs[]` | Replace embedded warehouse locations with `LogisticsHub` records referencing core `Provider.availableAt` locations. |
| `warehouseLocations[].locationId` | `CORE` | `LogisticsHub.locationId` -> `Provider.availableAt[*].id` | Keep only as a reference to the core provider location. |
| `warehouseLocations[].address` | `LEGACY` | `Provider.availableAt` | Remove the untyped duplicate address; the core provider location owns address and geometry. |
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
| Release 1 `LogisticsParticipant` | `suitable for later release` | Author after the four named decisions are resolved or explicitly deferred from the pack. |

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

## Remaining pack inventories

The following legacy packs still require the same field-by-field review before
Phase 3 is complete:

1. `LogisticsCommitment`
2. `LogisticsConsideration`
3. `LogisticsContract`
4. `LogisticsPerformance`
5. `LogisticsTracking`
6. `LogisticsPerformanceStates`
