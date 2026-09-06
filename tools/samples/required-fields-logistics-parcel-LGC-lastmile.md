# Required Fields: Logistics BPP, Parcel Pattern, LGC-lastmile

Generated from: `python tools/ion_required_fields.py --sector logistics --pattern parcel --crc LGC-lastmile`

---

## Step: publish_catalog

| Field | Source |
|---|---|
| `serviceLevel` | `[network-policy]` |
| `transportMode` | `[network-policy]` |
| `routingTopology` | `[pattern]` |
| `rateLogic` | `[pattern]` |
| `selectRequired` | `[pattern]` |

## Step: confirm / on_confirm

| Field | Source | Note |
|---|---|---|
| `awbNumber` | `[pattern]` | Issued at confirm |
| `billingNpwp` | `[network-policy]` | `← not in pattern.yaml` |

## Step: on_status (PICKED_UP)

| Field | Source |
|---|---|
| `proofOfPickup` | `[pattern]` |
| `actualWeight` | `[pattern]` |

---

*Regenerate this file when the spec version changes.*
