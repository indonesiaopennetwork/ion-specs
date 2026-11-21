# IONAddress v1

`IONAddress` is a complete Indonesian postal-address shape. It includes every
standard Beckn `Address/2.0` wire field and adds Indonesian administrative
subdivisions and delivery details.

## Attaches to

Used as a standalone object embedded within `Participant` (billing/delivery
address), `Provider` (outlet locations), and `Performance` (delivery
destination).

## Why not attach to `beckn:Address`?

Beckn 2.0.0's `Address` schema is `additionalProperties: false`, so extending it
with `allOf` would cause the Beckn branch to reject every Indonesian field.
`IONAddress` instead references each Beckn property definition individually and
adds the Indonesian properties to the same flat object.

## Where this shape is embedded

- `IONTradeParticipant.billingAddress` — billing address for the buyer or other Trade participant.
- `Provider.providerAttributes.availableAt[*].ionSubdivisions` — via sector provider packs, for physical presence locations of a provider.
- `Performance.performanceAttributes.stops[*].location.ionSubdivisions` — via sector performance packs, for pickup/drop stops in delivery flows.

## Fields
| Field | Type | Mandatory | Description |
|---|---|---|---|
| addressCountry | string | optional | Country name or ISO-3166-1 alpha-2 code; use `ID` for Indonesia. |
| addressRegion | string | optional | Province or region name. |
| addressLocality | string | optional | City or locality name. |
| streetAddress | string | optional | Building name or number and street name. |
| extendedAddress | string | optional | Apartment, suite, floor, care-of, or other supplemental information. |
| postalCode | string | optional | Indonesian five-digit postal code. |
| provinsiCode | enum | network policy | BPS province code (BPS-11 to BPS-94). 34 provinces. |
| kabupatenCode | string | optional | BPS 4-digit kabupaten/kota code |
| kelurahan | string | conditional | Village/urban zone. Required for delivery addresses. |
| kecamatan | string | conditional | District/sub-city. Required for delivery addresses. |
| rt | string | optional | Rukun Tetangga — neighborhood group |
| rw | string | optional | Rukun Warga — association of RTs |

## Why RT/RW
RT and RW are critical for last-mile delivery in Indonesia. Riders use RT/RW to locate specific houses in dense residential kampung areas where street names alone are insufficient.

## Regulatory
Permendagri 72/2019 tentang Perubahan atas Permendagri 137/2017

## Implementation guidance

The following field is implementation guidance rather than a normative Release 1
requirement:

- `provinsiCode`

This is not a normative Release 1 requirement. Release 1 validation is defined by
the standalone schema and included Trade flow material.

## Used in

See the Release 1 [Trade flows](../../../../flows/trade/README.md) and
[Logistics flows](../../../../flows/logistics/README.md).

## Common rejection reasons

Use 2-digit BPS province codes (for example, `31` for DKI Jakarta). See the
Release 1 [Trade error registry](../../../../errors/README.md) for included errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 draft | 2026-11-15 | Made `IONAddress` a complete address by composing all Beckn `Address/2.0` properties with the Indonesian fields. |
