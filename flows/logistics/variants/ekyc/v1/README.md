# eKYC Branch

B2B identity verification at `/init` for transactions without an active Framework Agreement.

## Applies to
LOG-PARCEL (B2B), LOG-FREIGHT, LOG-XB.

## Trigger
Transaction carries NPWP/NIB on consignor or consignee AND no `fwaReference` in contractAttributes.

## Sub-branches
`ekyc-first-transaction` (full KYC submission), `ekyc-refresh` (periodic update).

## Outcome
On VERIFIED, transaction proceeds to `/confirm`. On REJECTED, transaction terminates at `/on_init`. On PENDING_MANUAL_REVIEW, `/on_init` returns pending status and BPP sends unsolicited `/on_init` on resolution.

## Registries checked
NPWP against DJP (Direktorat Jenderal Pajak), NIB against OSS (Online Single Submission).

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
