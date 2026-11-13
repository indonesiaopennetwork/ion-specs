# ION Address v1

ION-maintained postal Address with an `addressAttributes` extension point. The
`IONAddress` type supplies Indonesian subdivisions and delivery-premises details.

## Attaches to

`IONAddress` attaches to `Address.addressAttributes` and therefore carries the
usual `@context` and `@type` fields.

## Why ION maintains Address

The upstream Beckn Address is closed and has no extension slot. ION maintains a
compatible Address that retains its standard fields and adds only
`addressAttributes`.

## Where this shape is embedded

- `Location.address.addressAttributes`
- Any direct use of the ION-maintained `Address`

## Fields
| Field | Type | Mandatory | Description |
|---|---|---|---|
| provinsiCode | enum | always | BPS province code (BPS-11 to BPS-94). 34 provinces. |
| kabupatenCode | string | optional | BPS 4-digit kabupaten/kota code |
| kelurahan | string | conditional | Village/urban zone. Required for delivery addresses. |
| kecamatan | string | conditional | District/sub-city. Required for delivery addresses. |
| rt | string | optional | Rukun Tetangga — neighborhood group |
| rw | string | optional | Rukun Warga — association of RTs |
| addressType | enum | optional | Nature of the destination premises |
| landmark | string | optional | Nearby landmark used to locate the address |

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

See the Release 1 [Trade flows](../../../../flows/trade/README.md) and
[Logistics flows](../../../../flows/logistics/README.md).

## Common rejection reasons

Use 2-digit BPS province codes (for example, `31` for DKI Jakarta). See the
Release 1 [Trade error registry](../../../../errors/README.md) for included errors.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
