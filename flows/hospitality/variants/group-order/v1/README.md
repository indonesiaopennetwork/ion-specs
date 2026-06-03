# group-order — ION Hospitality Variant v1

**Applies to:** delivery-order  
**Activation:** `RestaurantProvider.groupOrderEnabled = true`  

Multiple participants add items to a shared cart before the initiator
locks and submits. One order, one delivery address, one payment by initiator.
Covers Grab Group Order and GoFood Pesan Bareng style flows.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
