# Release 1 core API scope

Release 1 does not include the unreconciled ION-native `ion.yaml` aggregate;
the manifest records `ionApi: excluded`.

This directory holds standalone ION network extension APIs that extend the
vendored Beckn Protocol contract by reference:

- [`reconcile/v1/`](reconcile/v1/README.md) — settlement reconciliation between
  the BAP and BPP of an order: the `/reconcile` and `/on_reconcile` API and the
  `IONSettlementReconciliation` attribute pack.
