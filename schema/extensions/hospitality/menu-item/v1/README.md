# hospitality/menu-item/v1

**ION schema class:** `ion:IONMenuItem`

ION Hospitality sector extension pack for prepared food and beverage items available for delivery or self-pickup.

**CRCs:** `HSC-restaurant-ordering`, `HSC-fnb-delivery`
**Covers:** Restaurant meals, beverages, cloud kitchen items ordered via GoFood, GrabFood, Tokopedia Food, and any online food ordering platform on ION
**Beckn attachment:** `Resource.resourceAttributes`
**Sector:** `ion:hospitality`
**Upstream:** `FoodAndBeverageResource v2.1` (schema.beckn.io)

## Attaches to

`beckn:Resource.resourceAttributes`

## Two-layer split

| Layer | Schema name | What it carries |
|---|---|---|
| Generic | `MenuItem` | Non-regulatory fields: resourceStructure, logisticsServiceType, availability, preparationTime, menuCategory, customisationGroups, identity, itemRating |
| ION | `IONMenuItem` | Adds `fnb` sub-object: Indonesian food regulatory fields — halal certification (UU 33/2014), allergen declaration, BPOM registration, cuisine type, spice level |

## Network-required fields

Enforced by ONIX at `catalog/publish` for CRC `HSC-restaurant-ordering` and `HSC-fnb-delivery`:

| Field | Condition |
|---|---|
| `fnb.classification` | Always required |
| `fnb.allergens` | Always required (empty array if none) |
| `images` | Always required (min 1) |
| `availability` | Always required |
| `fnb.halalCertNumber` | Required when `fnb.classification` = `HALAL` |

For the full step-by-step list:
```bash
python tools/ion_required_fields.py --sector hospitality --pattern delivery-order --crc HSC-restaurant-ordering
```

## Used in

`flows/hospitality/README.md` — `delivery-order` pattern

## Common rejection reasons

- Missing `fnb.classification` → `ION-D8xxx`. Required for all hospitality resources.
- Missing `fnb.allergens` → `ION-D8xxx`. Declaration is mandatory (empty array if none present).
- `fnb.halalCertNumber` absent when `fnb.classification` is `HALAL` → `ION-D8xxx`.
- `images` array is empty → `ION-D8xxx`. At least one food photo is required.
- `ageRestricted` is `false` but `isAlcoholic` is `true` → `ION-D8xxx`. Contradictory fields.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-03 | Initial release. Merged from hospitality/delivery and hospitality/fnb-delivery into a single compliant pack. Generic layer inherits FoodAndBeverageResource v2.1. ION layer carries fnb sub-object with Indonesian food regulatory fields. |
