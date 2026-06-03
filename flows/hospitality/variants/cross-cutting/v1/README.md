# cross-cutting — ION Hospitality Variant v1

**Applies to:** All hospitality patterns (delivery-order and future patterns)  
**Window:** On confirm → contract complete  

## What this covers

Track, support, rate, raise, and reconcile — the five cross-cutting actions
available on every active hospitality contract.

| Action | Available from | Purpose |
|---|---|---|
| `track` | Rider assigned | Live GPS, ETA, distance remaining |
| `support` | On confirm | Wrong item, missing item, quality complaint |
| `rate` | After delivered | Food, delivery, packaging rating with tags |
| `raise` | After delivered | Formal dispute with evidence (24h window) |
| `reconcile` | After delivered | Net settlement after refunds |

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
