# Required Fields: Trade BPP, Storefront Pattern, TRC-food-bev

Generated from: `python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-food-bev`

Field labels: `[network-policy]` = ion.yaml x-ion-field-requirements | `[crc:X]` = ion.yaml x-ion-crc-rules | `[discovery]` = profile.json minimalForDiscovery | `[pattern]` = pattern.yaml requiredFields

---

## Step: publish_catalog

| Field | Source | Note |
|---|---|---|
| `resourceStructure` | `[network-policy]` | |
| `resourceTangibility` | `[network-policy]` | |
| `halalStatus` | `[network-policy]` | `← not in pattern.yaml` — UU 33/2014 |
| `ageRestricted` | `[network-policy]` | `← not in pattern.yaml` |
| `countryOfOrigin` | `[network-policy]` | |
| `name.id` | `[network-policy]` | Bahasa Indonesia name required |
| `food.classification` | `[crc:TRC-food-bev]` | VEG / NON_VEG / HALAL / EGG |
| `food.allergens` | `[crc:TRC-food-bev]` | Array; empty array acceptable |
| `packaged.netWeight` | `[crc:TRC-food-bev]` | |
| `packaged.storageInstructions` | `[crc:TRC-food-bev]` | |
| `regulatory.halalStatus` | `[crc:TRC-food-bev]` | Must match top-level halalStatus |
| `images` | `[discovery]` | Missing → resource not indexed |
| `availability` | `[discovery]` | Missing → resource not indexed |
| `cancellationPolicy` | `[pattern]` | Must be a valid policy IRI |
| `returnPolicy` | `[pattern]` | Must be a valid policy IRI |
| `contactDetailsConsumerCare` | `[pattern]` | |

*Remaining steps follow the same pattern as TRC-fashion — see that sample for the full step list.*

---

*Regenerate this file when the spec version changes.*
