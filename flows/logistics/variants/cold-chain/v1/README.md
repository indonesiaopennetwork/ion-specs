# Cold Chain Proof Branch

Mandatory temperature proof-of-condition at pickup and delivery for cold-chain shipments.

## Applies to
LOG-PARCEL, LOG-FREIGHT, LOG-WAREHOUSE (inbound and outbound).

## Trigger
`resource.temperatureRequirement.controlled = true`. Fires automatically at PICKED_UP and DELIVERED events.

## Sub-branches
`cold-chain-proof-pickup`, `cold-chain-excursion-alert`, `cold-chain-proof-delivery`.

## Excursion handling
If temperature leaves the declared range, BPP sends unsolicited `/on_update`. BAP chooses: continue at buyer risk, hold for inspection, or cancel and return.

## If integrity fails at delivery
`coldChainIntegrityVerified = false` in the DELIVERED `on_status` automatically makes the `damage-claim` exception branch eligible.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
