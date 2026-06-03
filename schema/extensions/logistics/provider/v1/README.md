# provider/v1

Logistics provider attributes. Attaches to `beckn:Provider.providerAttributes`.

## What it covers
Identity and licences (NIB, SIUP, ALFI, ASPERINDO), provider model (carrier vs forwarder vs aggregator vs 3PL/4PL vs warehouse), patterns and modes supported, geographic coverage, capabilities (cold chain, hazmat, high-value, customs brokerage), operating hours, fleet type, warehouse locations.

## Mandatory fields (always)
`nibRegistered`, `providerCategory`, `patternsSupported`, `modesSupported`, `coverage[]`, `operatingHours[]`

## Conditional fields
`siupNumber` (freight and warehouse), `beaCukaiLicenceNumber` (cross-border providers), `coldChainTemperatureZones` (if coldChainCertified=true), `hazmatClasses` (if hazmatCertified=true), `warehouseLocations[]` (warehouse providers), `maxDeliveryRadiusKm` (hyperlocal providers).

## Used in patterns
All logistics patterns. Fields applicable per pattern are documented in each pattern's conditional field list.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `providerType`
- `supportedModes`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Per-step required fields

The `flows/logistics/patterns/parcel/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/logistics/README.md — catalog publish step`

## Common rejection reasons

Missing `providerType` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
