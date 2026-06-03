# LOG-FREIGHT — Freight Logistics

Capacity-based freight for bulk and consolidated cargo. Booking is against reserved capacity on specific departures, not against a per-package rate card.

## Applicable service types
FTL, LTL, FCL, LCL, air cargo, rail freight, river barge, bulk, break-bulk, project cargo. Covers Samudera, SPIL, Maersk, Puninar, Linfox, DB Schenker, Kuehne+Nagel, and domestic trucking operators.

## Delta from LOG-PARCEL
- Rate is per capacity unit (per container, per cbm, per freight-kg), not per package
- `selectRequired` always true — capacity confirmation is authoritative at `/select`
- `on_select` returns a capacity reservation token with a hold window
- Bill-of-lading replaces AWB
- State machine uses departure events (LOADED, DEPARTED, ARRIVED, UNLOADED)
- Cargo manifest with HS codes mandatory at `/init`
- `capacityModel` and `consolidationType` mandatory on offer
- `scheduleType` on offer distinguishes regular sailings/flights vs ad-hoc bookings

## Capacity models
| Model | Capacity unit | Typical use |
|---|---|---|
| PER_CONTAINER | 20ft, 40ft, 40HC containers | FCL ocean |
| PER_PALLET | 1m × 1.2m × 1.6m | LTL road, LCL ocean |
| PER_CBM | Cubic metres | LCL, air cargo, LTL |
| PER_KG | Chargeable weight | Air cargo, LTL |
| PER_TRUCK | Full truck | FTL |
| PER_VESSEL_SLOT | Vessel-specific slots | Ro-Ro, ferry, bulk |

## Consolidation types
FTL, LTL, FCL, LCL, BULK, BREAK_BULK, PROJECT_CARGO.

## Available branches
- During-transaction: `ekyc`, `fwa-activation`, `capacity-reservation`, `payment-prepaid`, `payment-credit`
- Fulfilment: `weight-dispute`, `cold-chain-proof` (reefer), `damage-claim`, `loss-claim`
- Cancellation: with capacity-release and policy-driven fees
- Reverse: `reverse-freight` (acceptance states, credit notes)
- Cross-cutting: `track`, `support`, `rating`, `raise`

## Key fields introduced
`capacityModel`, `consolidationType`, `scheduleType`, `billOfLadingReference`, `cargoManifest[]`, `hsCodes[]`, `reservedCapacity`, `reservationHoldUntil`, `scheduledDeparture`, `scheduledArrival`, `vesselsOperated`, `fleetType`, `reefer`, `projectCargoCapability`.

## Multi-leg freight
For multi-modal freight (ocean + road, air + trucking), the `performance.stops[]` array carries each leg. Each leg has its own carrier attribution. The parent contract governs commercial terms; leg-level events update the performance object.

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `logistics/resource/v1` | See pack README | [`schema/extensions/logistics/resource/v1/README.md`](../../../../schema/extensions/logistics/resource/v1/README.md) |
| `logistics/offer/v1` | See pack README | [`schema/extensions/logistics/offer/v1/README.md`](../../../../schema/extensions/logistics/offer/v1/README.md) |
| `logistics/commitment/v1` | See pack README | [`schema/extensions/logistics/commitment/v1/README.md`](../../../../schema/extensions/logistics/commitment/v1/README.md) |
| `logistics/consideration/v1` | See pack README | [`schema/extensions/logistics/consideration/v1/README.md`](../../../../schema/extensions/logistics/consideration/v1/README.md) |
| `logistics/performance/v1` | See pack README | [`schema/extensions/logistics/performance/v1/README.md`](../../../../schema/extensions/logistics/performance/v1/README.md) |
| `logistics/contract/v1` | See pack README | [`schema/extensions/logistics/contract/v1/README.md`](../../../../schema/extensions/logistics/contract/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, exception` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

