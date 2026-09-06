# trade/performance/v1

Fulfilment execution attributes — selected origin, mode, shipment identifier,
assigned agent, return QC details, SLA breaches, verification outcome, and
package facts.

## Attaches to
`beckn:Performance.performanceAttributes`

## Performance modes
| Mode | Description |
|---|---|
| DELIVERY | Logistics delivers to buyer address |
| SELF_PICKUP | Buyer collects from seller location |
| SERVICE | Provider performs a service |
| DINE_IN | For restaurant orders consumed on premises |
| CURBSIDE | Buyer drives to pickup, seller brings to car |

`fulfillingLocationId` identifies the Provider operating location selected for
this Performance. It is performance-level because one Contract may be fulfilled
through multiple execution units and locations.

## State machine reference
States are defined in `releases/release1/schema/extension/trade/TradePerformanceStates/v1/states.yaml`.
Do not redefine state codes in flow files — always reference the canonical states.

## SLA
SLA `unitBasis` options:
- `ORDER_CONFIRMATION` — countdown from when buyer confirms
- `SHIPMENT` — countdown from when package is dispatched
- `PAYMENT_RECEIPT` — countdown from payment confirmation

## Installation scheduling
`resource.installation` declares capability (does it need installation? does seller provide it?).
`performance.installationScheduling` carries the transaction-time appointment (scheduledDate, notes).

## ION-specific refinements

- `ageVerification.method` carries the KTP-, SIM-, passport-, selfie-, or
  biometric-aware verification method.
- `stops[].location.geo` uses Beckn GeoJSON geometry.
- `stops[].location.address` uses the closed Beckn Address shape.
- `stops[].location.ionAddressAttributes` adds Indonesian administrative
  subdivisions without modifying the Beckn Address object.

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `performanceMode`
- `performanceState`

This is not a normative Release 1 requirement. Per-step requirements must come
from Trade flow material included in the release.

## Per-step required fields

The Release 1 [Storefront pattern](../../../../../flows/trade/patterns/storefront/v1/pattern.yaml)
lists the required fields at each included API step.

## Used in

[Release 1 Trade flow](../../../../../flows/trade/README.md) — used by Storefront v1.

## Common rejection reasons

See the Release 1 [Trade error registry](../../../../../errors/README.md) for the
error codes included in this release.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
