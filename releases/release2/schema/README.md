# Release 2 schemas

All schema contracts and their vendored schema dependencies are contained below
this directory:

- `common/` contains the Trade-required common packs, the reusable
  `IdentifiableLocation`, the common `IONParticipant`, the Settlement pack
  (`IONSettlementReconciliation`) used by reconciliation, and the Grievance
  pack (`IONGrievance`) used by `/support` and `/on_support`.
- `extension/trade/` contains the ten Release 2 Trade packs, including
  `TradeParticipant`, which specializes the common participant model for the
  Trade domain.
- `core/` contains the ION-maintained Beckn contract at
  `api/v2.0.0/ion-beckn.yaml` and `api/v2.0.0/ion-additional.yaml`, which holds
  the ION endpoints Beckn does not define.
- `vendored/beckn/` contains the pinned upstream Beckn protocol contract at
  `api/v2.0.0/beckn.yaml`, retained temporarily for its existing URL, and the
  separately vendored schema dependencies.

The public namespace mirrors this structure at
`https://schema.ion.id/release2/schema/`.
