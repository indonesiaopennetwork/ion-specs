# Release 1 core API scope

Release 1 does not include the unreconciled ION-native `ion.yaml` aggregate.
Its core API contract is the Beckn-derived `api/v2.0.0/ion-beckn.yaml`, which is being
reviewed for ION decentralized-catalog behavior. The manifest therefore records
`ionApi: review-required` while this draft work remains incomplete.

This directory also holds standalone ION network extension APIs that extend
`api/v2.0.0/ion-beckn.yaml` by reference:

- [`reconcile/v1/`](reconcile/v1/README.md) — settlement reconciliation between
  the BAP and BPP of an order: the `/reconcile` and `/on_reconcile` API and the
  `IONSettlementReconciliation` attribute pack.
