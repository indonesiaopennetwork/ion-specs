# trade/contract/v1

Order-level contract attributes — buyer instructions, gift, invoice preferences, credit terms, subscription.

## Attaches to
`beckn:Contract.contractAttributes`

See `attributes.yaml` for complete field definitions.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `fulfillingLocationId`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Conditional requirements

- If `paymentRail=COD`: **codAmount becomes required on this contract**. Source: `ion.yaml → x-ion-conditional-rules`.

## Per-step required fields

The `flows/trade/patterns/storefront/v1/pattern.yaml` lists every field ONIX validates at each API step for your commerce flow — use it as your implementation checklist. If ONIX rejects a message, check your step's `requiredFields` list in that file first.

## Used in

`flows/trade/README.md — used in all trade patterns`

## Common rejection reasons

Missing `fulfillingLocationId` → `ION-3xxx`. COD: missing `codAmount` → `ION-3xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
