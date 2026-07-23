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
States are defined in `schema/extensions/trade/performance-states/v1/states.yaml`.
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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `performanceMode`
- `performanceState`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Per-step required fields

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — used in all trade patterns`

## Common rejection reasons

Invalid `performanceState` transition → `ION-4xxx`. Missing `trackingNumber` at DISPATCHED state → `ION-4xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
