# Required Fields: Trade BPP, Storefront Pattern, TRC-fashion

Generated from: `python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion`

Field labels: `[network-policy]` = ion.yaml x-ion-field-requirements | `[crc:X]` = ion.yaml x-ion-crc-rules | `[discovery]` = profile.json minimalForDiscovery | `[pattern]` = pattern.yaml requiredFields

Fields marked `← not in pattern.yaml` are enforced by ION network policy but not visible in the pattern itself.

---

## Step: publish_catalog

| Field | Source | Note |
|---|---|---|
| `resourceStructure` | `[network-policy]` | |
| `resourceTangibility` | `[network-policy]` | |
| `halalStatus` | `[network-policy]` | `← not in pattern.yaml` |
| `ageRestricted` | `[network-policy]` | `← not in pattern.yaml` |
| `countryOfOrigin` | `[network-policy]` | |
| `name.id` | `[network-policy]` | Bahasa Indonesia name required |
| `fashion.gender` | `[crc:TRC-fashion]` | |
| `fashion.size` | `[crc:TRC-fashion]` | |
| `fashion.fabric` | `[crc:TRC-fashion]` | |
| `fashion.fabricComposition` | `[crc:TRC-fashion]` | Required for SNI compliance |
| `images` | `[discovery]` | Missing → resource not indexed |
| `availability` | `[discovery]` | Missing → resource not indexed |
| `policies.cancellation.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `policies.returns.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `policies.warranty.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `policies.dispute.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `policies.grievanceSla.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `policies.paymentTerms.policyRef` | `[pattern]` | Must be a valid policy IRI |
| `contactDetailsConsumerCare` | `[pattern]` | UU 8/1999 — always required |

## Step: select / on_select

| Field | Source |
|---|---|
| `commitments[].lineId` | `[pattern]` |
| `commitments[].resourceId` | `[pattern]` |
| `commitments[].offerId` | `[pattern]` |
| `commitments[].quantity` | `[pattern]` |
| `performance[].performanceMode` | `[pattern]` |
| `settlements[].method` | `[pattern]` |

## Step: init / on_init

| Field | Source | Note |
|---|---|---|
| `deliveryAddress.provinsiCode` | `[network-policy]` | 2-digit BPS code |
| `participants[].npwp` | `[network-policy]` | `← not in pattern.yaml` — PMK 112/2022 |
| `participants[].nib` | `[network-policy]` | `← not in pattern.yaml` — PP 5/2021 |
| `settlements[].paymentRail` | `[pattern]` | |

## Step: confirm / on_confirm

| Field | Source | Note |
|---|---|---|
| `fulfillingLocationId` | `[pattern]` | |
| All fields from init | `[pattern]` | Carried forward |

## Step: on_status (DISPATCHED)

| Field | Source | Note |
|---|---|---|
| `awbNumber` | `[pattern]` | Required at DISPATCHED state |
| `trackingUrl` | `[pattern]` | |

---

*Regenerate this file when the spec version changes to verify no fields were added or removed.*
