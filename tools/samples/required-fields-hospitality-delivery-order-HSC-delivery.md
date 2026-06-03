# Required Fields: Hospitality BPP, Delivery-Order Pattern, HSC-delivery

Generated from: `python tools/ion_required_fields.py --sector hospitality --pattern delivery-order --crc HSC-delivery`

---

## Step: publish_catalog

| Field | Source | Note |
|---|---|---|
| `halalStatus` | `[network-policy]` | `← not in pattern.yaml` |
| `ageRestricted` | `[network-policy]` | `← not in pattern.yaml` |
| `name.id` | `[network-policy]` | Bahasa Indonesia name |
| `preparationTime` | `[pattern]` | ISO 8601 duration |
| `food.classification` | `[crc:HSC-delivery]` | |
| `food.allergens` | `[crc:HSC-delivery]` | |
| `returnable` | `[pattern]` | Always false for hospitality |
| `cancellationPolicy` | `[pattern]` | Typically only before PREPARING |

---

*Regenerate this file when the spec version changes.*
