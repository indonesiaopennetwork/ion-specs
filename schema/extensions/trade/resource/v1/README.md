# trade/resource/v1

Physical product attributes for all Trade sector categories.

> **Sector boundary:** This pack covers packaged, stocked physical products. Restaurant meals and food delivery (GoFood, GrabFood, any prepared-to-order food) are **Hospitality** sector — use `schema/extensions/hospitality/delivery/v1` instead.

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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `resourceStructure`
- `resourceTangibility`
- `availability`
- `countryOfOrigin`
- `ageRestricted`
- `images`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Category-specific required fields

Which fields within this pack are mandatory depends on the CRC (Catalogue Resource Category) you assign to your resource. For example:

- `TRC-fashion` — `fashion.gender`, `fashion.size`, `fashion.fabric`, `fashion.fabricComposition` become required
- `TRC-food-bev` — `food.*` block and `packaged.*` block become required
- `TRC-electronics` — `electronics.connectivity[]` and `electronics.warrantyMonths` become required

Run `python tools/ion_required_fields.py --sector trade --pattern <your-pattern> --crc <your-crc>` to see the full list for your category, or check `ion.yaml → x-ion-crc-rules` directly. Do not maintain a static list — CRCs are added as sectors mature.

## Required for catalogue indexing

> **Silent non-indexing warning.** minimalForDiscovery includes `resourceStructure`, `resourceTangibility`, `images`, `availability`, `ageRestricted`, `countryOfOrigin` — missing any of these causes the resource to be accepted but not indexed for discovery.

## Per-step required fields

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — used in all trade patterns`

## Common rejection reasons

Missing `resourceStructure` → `ION-8xxx`. Missing `countryOfOrigin` → `ION-8xxx`. Unknown `crc` code → `ION-2xxx`. Category-specific required fields depend on your CRC — run the required-fields tool. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
