# ION Logistics flows

This tree contains the reviewed Release 1 Logistics patterns, variants, and
their shared execution-state registry. Flow documents constrain how the core
Beckn actions and the Release 1 Logistics attribute packs are used; they do not
define additional message fields.

- [`patterns/`](patterns/) contains the six base transaction patterns.
- [`variants/`](variants/) contains only branches whose actions, schemas,
  states, and policy dependencies are available in Release 1.
- [`state-machines/`](state-machines/) contains the shared, versioned execution
  graphs referenced by pattern and variant profiles.

The Phase 6 review and explicit deferrals are recorded in
[`docs/internal/ION_Release1_Logistics_Flow_Migration_Ledger.md`](../../../../docs/internal/ION_Release1_Logistics_Flow_Migration_Ledger.md).
