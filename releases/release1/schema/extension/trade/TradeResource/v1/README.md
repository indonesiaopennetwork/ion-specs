# trade/resource/v1

Physical product attributes for all Trade sector categories.

> **Sector boundary:** This pack covers packaged, stocked physical products.
> Restaurant meals and prepared-to-order food delivery belong to Hospitality,
> which is not included in Release 1.

## Attaches to
`beckn:Resource.resourceAttributes`

## Availability model
**Stock count is NEVER transmitted over the network.**
Publish availability signal only:
- `IN_STOCK` — adequate quantity
- `LOW_STOCK` — limited, BAP may show urgency
- `OUT_OF_STOCK` — not available
- `PREORDER` — available for pre-order
- `DISCONTINUED` — permanently removed

## Resource types
| Type | Use | Required fields |
|---|---|---|
| PLAIN | Single SKU, no choices | availability, images |
| VARIANT | One of several options of a parent | parentResourceId, variantGroup, isDefaultVariant |
| WITH_EXTRAS | Base + optional add-ons | customisationGroups |
| COMPOSED | Base + mandatory/optional groups | customisationGroups |

## Category-specific sub-objects
| Sub-object | Applicable to |
|---|---|
| food | Food & Beverage, Grocery |
| preparation | F&B, perishables |
| packaged | FMCG, grocery, pharma, cosmetics |
| regulatory | All regulated products |
| fashion | Apparel, accessories |
| electronics | Electronics, appliances |
| beauty | Cosmetics, personal care |
| agritech | Fresh produce, agricultural |
| pharmacy | Medicines, OTC |
| installation | Appliances, furniture |
| warranty | Electronics, durables |

## Regulatory
PerBPOM 31/2018 (packaged goods), UU 8/1999 (consumer protection), 
PerBPOM 23/2019 (cosmetics), PP 36/2023 (electronics warranty)

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `resourceStructure`
- `resourceTangibility`
- `availability`
- `countryOfOrigin`
- `ageRestricted`
- `images`

This is not a normative Release 1 requirement. Per-step requirements must come
from Trade flow material included in the release.

## Category-specific required fields

Which fields within this pack are mandatory depends on the CRC (Catalogue Resource Category) you assign to your resource. For example:

- `TRC-fashion` — `fashion.gender`, `fashion.size`, `fashion.fabric`, `fashion.fabricComposition` become required
- `TRC-food-bev` — `food.*` block and `packaged.*` block become required
- `TRC-electronics` — `electronics.connectivity[]` and `warranty` become required

The category examples below came from the excluded aggregate and are informative
only. Release 1 does not publish an `x-ion-crc-rules` registry.

## Required for catalogue indexing

> **Silent non-indexing warning.** minimalForDiscovery includes `resourceStructure`, `resourceTangibility`, `images`, `availability`, `ageRestricted`, `countryOfOrigin` — missing any of these causes the resource to be accepted but not indexed for discovery.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

Consult the included Trade error and flow material for Release 1 rejection rules;
do not infer them from the excluded aggregate.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
