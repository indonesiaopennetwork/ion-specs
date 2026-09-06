# Trade Performance Extension — Overview

Fulfilment tracking attributes. What the BAP receives at each state transition.

## What gets added per state
- PACKED: nothing new (just state code)
- DISPATCHED: `trackingNumber`, `trackingUrl`, `estimatedDeliveryTime`, and `agent`
- OUT_FOR_DELIVERY: updated `estimatedDeliveryTime`; live location is carried by `Tracking.trackingAttributes`
- DELIVERED: inherited `proofOfDelivery`, optional `deliveryReceiptId`, contract status = COMPLETE

## installationScheduling
Declared capability is in `resource.installation` (does it need installation? does seller provide it?). This field carries the transaction-time appointment — `scheduledDate` + `notes`. Populated by BPP after on_confirm.

## Tracking vs status
`/on_status` carries durable performance state and execution facts. `/on_track`
carries transient position information in `Tracking.trackingAttributes`; live GPS
is not stored in `Performance.performanceAttributes`.
