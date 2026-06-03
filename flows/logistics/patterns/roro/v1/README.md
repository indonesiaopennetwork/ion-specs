# LOG-RORO — Roll-on/Roll-off

Self-accompanied cargo on Ro-Ro vessels and ferries. The consignor typically drives or accompanies the cargo onto the vessel at origin port and off at destination port.

## Applicable service types
Strait crossings (Java-Bali Ketapang-Gilimanuk, Java-Sumatra Merak-Bakauheni), inter-island Ro-Ro freight with accompanying drivers, motorcycle and car ferry services. Covers ASDP Indonesia Ferry and private Ro-Ro operators.

## Delta from LOG-FREIGHT
- Resource is a vehicle (car, truck, trailer, motorcycle), not a cargo unit
- Consignor and consignee often the same party (owner/driver rides along)
- No pickup/drop addresses — drive-in and drive-out at ports
- Ticket reference replaces bill-of-lading
- Port events (CHECKED_IN, BOARDED, SAILED, DISEMBARKED, EXITED_PORT) replace freight events
- Driver identity and vehicle registration mandatory
- `PER_VESSEL_SLOT` capacity model

## Vehicle categories
Passenger car, light truck, heavy truck, motorcycle, trailer, bus. Each has different slot allocation and pricing on the sailing.

## Available branches
- `cancellation` (window ends at CHECKED_IN)
- `missed-sailing` (if vehicle doesn't board in time — rebook or refund per policy)
- Cross-cutting: `support`, `rating`, `raise`

## Key fields introduced
`portsServed[]`, `vehicleCategoriesAccepted[]`, `sailingSchedule[]`, `crossingDuration`, `vesselCapacityPerSailing`, `requestedSailing`, `confirmedSailing`, `boardingWindow`, `ticketReference`, `boardingGate`, `vehicleDetails`, `vehicleRegistration`, `DRIVER` participant role.

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

**Conditionally active:** `cancellation, exception` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

