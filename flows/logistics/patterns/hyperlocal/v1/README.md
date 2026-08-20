# LOG-HYPERLOCAL — Hyperlocal Delivery

Sub-day single-rider delivery within a city or metropolitan area. Real-time GPS, rider exposed mid-flow, no hub states.

## Applicable service types
INSTANT and sub-3-hour delivery patterns. Covers GoSend, GrabExpress, Paxel instant, Lalamove, and on-demand courier services.

## Delta from LOG-PARCEL
- State machine: `hyperlocal-fifo` or `hyperlocal-pre-assigned` — no hub events
- Service level restricted to INSTANT or sub-3h
- `agentAssignmentModel` is mandatory on offer (PRE_ASSIGNED, POOL_ASSIGNED, FIFO_AT_PICKUP, DEDICATED_FLEET)
- Rider identity exposed via `agentDetails` — timing depends on assignment model
- `liveTrackingEnabled` true throughout
- `selectRequired` typically true (surge pricing)
- Cold chain rarely supported; hazmat not supported
- No AWB — `bookingReference` used
- Tighter cancellation and return windows

## Agent assignment models
| Model | Rider known at |
|---|---|
| PRE_ASSIGNED | Booking confirmation |
| DEDICATED_FLEET | Booking confirmation (from committed pool) |
| POOL_ASSIGNED | Rider dispatched to merchant |
| FIFO_AT_PICKUP | Rider pickup event — first rider takes first ready order |

## Available branches
- `payment-prepaid`, `payment-cod`
- `attempt-ndr` (1–2 attempts typical), `attempt-reschedule`
- Reverse: `reverse-simple`
- Cross-cutting: `track`, `support`, `rating`, `raise`

## Key fields introduced
`agentAssignmentModel`, `maxDeliveryRadiusKm`, `liveTrackingEnabled`, `bookingReference`, `agentDetails` (name, phone via proxy, vehicle, photo).

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `logistics/resource/v1` | See pack README | [`schema/extensions/logistics/resource/v1/README.md`](../../../../schema/extensions/logistics/resource/v1/README.md) |
| `logistics/offer/v1` | See pack README | [`schema/extensions/logistics/offer/v1/README.md`](../../../../schema/extensions/logistics/offer/v1/README.md) |
| `logistics/commitment/v1` | See pack README | [`schema/extensions/logistics/commitment/v1/README.md`](../../../../schema/extensions/logistics/commitment/v1/README.md) |
| `logistics/consideration/v1` | See pack README | [`schema/extensions/logistics/consideration/v1/README.md`](../../../../schema/extensions/logistics/consideration/v1/README.md) |
| `logistics/performance/v1` | See pack README | [`schema/extensions/logistics/performance/v1/README.md`](../../../../schema/extensions/logistics/performance/v1/README.md) |
| `logistics/contract/v1` | See pack README | [`schema/extensions/logistics/contract/v1/README.md`](../../../../schema/extensions/logistics/contract/v1/README.md) |
| `logistics/agent/v1` | See pack README | [`schema/extensions/logistics/agent/v1/README.md`](../../../../schema/extensions/logistics/agent/v1/README.md) |
| `core/address/v1` | See pack README | [`releases/release1/common/Address/v1/README.md`](../../../../releases/release1/common/Address/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, cash-on-delivery` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

