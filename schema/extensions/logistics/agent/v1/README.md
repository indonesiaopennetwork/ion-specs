# ion-logistics/participant-logistics/v1

Thin addendum to `core/participant/v1` carrying participant identity fields that apply only to logistics roles.

## Attaches to
`beckn:Participant.participantAttributes`

## Depends on
`core/participant/v1` — this addendum assumes the role taxonomy, identity fields, and addressDetail are already declared by the core participant pack.

## Fields
- `ppjkLicenceNumber` — PPJK customs-broker licence (required when `role=CUSTOMS_BROKER`)
- `driverLicenceNumber` — Indonesian SIM (required when `role=DRIVER`)
- `driverLicenceCategory` — SIM class (A, B_I, B_II, C, D)

## Why this exists as a separate pack

These three fields are strictly logistics-specific — trade, finance, tourism, healthcare have no need for PPJK customs licences or driver SIM categories. Keeping them out of `core/participant/v1` keeps the core pack tight and avoids forcing every sector to carry fields it doesn't use.

## How both blocks coexist on one participant

Beckn 2.0 allows `participantAttributes` to carry multiple JSON-LD typed blocks. Both the core participant block and this addendum attach to the same slot with distinct `@type` values and disjoint field sets. Implementations populating a DRIVER or CUSTOMS_BROKER participant will typically carry both blocks in the same payload.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `role`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Conditional requirements

- If `role=DRIVER`: **driverLicenceCategory and driverLicenceNumber become required**. Source: `ion.yaml → x-ion-conditional-rules`.

## Participant attachment note

`Participant` in Beckn v2.0 does not have a `participantAttributes` bag. Fields from this pack attach as **direct properties on the `Participant` object**. Do not wrap them in a `participantAttributes` sub-object — ONIX will reject the payload.

## Per-step required fields

The `flows/logistics/patterns/parcel/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/logistics/README.md`

## Common rejection reasons

Missing `role` → `ION-8xxx`. Driver: missing `driverLicenceNumber` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
