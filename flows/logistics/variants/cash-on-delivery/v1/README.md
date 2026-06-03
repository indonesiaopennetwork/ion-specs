# COD Branch

Cash-on-delivery collection, refusal handling, and remittance.

## Applies to
LOG-PARCEL, LOG-HYPERLOCAL.

## Trigger
`offer.availableOnCod = true` AND `settlement.collectedBy = BPP` AND `settlement.method = COD`.

## Sub-branches
`cod-collection` (successful), `cod-refusal` (buyer refuses), `cod-partial-collection` (rare — partial payment), `cod-remittance` (LSP remits to BAP).

## Remittance
Scheduled per `offer.codPolicy` IRI (weekly, bi-weekly). LSP holds funds until remittance date. Remittance breach triggers `penalty.cod-remittance-late` policy.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
