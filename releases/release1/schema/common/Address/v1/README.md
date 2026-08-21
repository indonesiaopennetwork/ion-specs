# ion-core/address/v1

Indonesian address subdivisions (provinsi / kabupaten / kecamatan / kelurahan / RT / RW). Reusable shape embedded inside other ION Attributes bags — does NOT attach to Beckn's `Address` object directly.

## Attaches to

Used as a standalone object embedded within `Participant` (billing/delivery address), `Provider` (outlet locations), and `Performance` (delivery destination). Not an `*Attributes` extension pack — no `@context`/`@type` wrapper required.

## Why not attach to `beckn:Address`?

Beckn 2.0.0's `Address` schema is `additionalProperties: false` — it has no extension slot. The Beckn fields (streetAddress, addressLocality, postalCode, addressRegion, addressCountry, extendedAddress) cover international postal-address needs and are used as-is.

## Where this shape is embedded

- `Participant.participantAttributes.addressDetail` — via `core/participant/v1` (primary use). Every ION participant with a physical location (buyer, seller, merchant, warehouse, consignor, consignee, agent) carries this.
- `Provider.providerAttributes.availableAt[*].ionSubdivisions` — via sector provider packs, for physical presence locations of a provider.
- `Performance.performanceAttributes.stops[*].location.ionSubdivisions` — via sector performance packs, for pickup/drop stops in delivery flows.

## Fields
| Field | Type | Mandatory | Description |
|---|---|---|---|
| provinsiCode | enum | always | BPS province code (BPS-11 to BPS-94). 34 provinces. |
| kabupatenCode | string | optional | BPS 4-digit kabupaten/kota code |
| kelurahan | string | conditional | Village/urban zone. Required for delivery addresses. |
| kecamatan | string | conditional | District/sub-city. Required for delivery addresses. |
| rt | string | optional | Rukun Tetangga — neighborhood group |
| rw | string | optional | Rukun Warga — association of RTs |

## Why RT/RW
RT and RW are critical for last-mile delivery in Indonesia. Riders use RT/RW to locate specific houses in dense residential kampung areas where street names alone are insufficient.

## Regulatory
Permendagri 72/2019 tentang Perubahan atas Permendagri 137/2017

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following field as
network-required:

- `provinsiCode`

This is not a normative Release 1 requirement. Release 1 validation is defined by
the standalone schema and included Trade flow material.

## Used in

See the Release 1 [Trade flow](../../../../flows/trade/README.md). Logistics is not
included in this release.

## Common rejection reasons

Use 2-digit BPS province codes (for example, `31` for DKI Jakarta). See the
Release 1 [Trade error registry](../../../../errors/README.md) for included errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
