# ION Logistics flows

This tree contains the reviewed Release 2 Logistics patterns, variants, and
their shared execution-state registry. Flow documents constrain how the core
Beckn actions and the Release 2 Logistics attribute packs are used; they do not
define additional message fields.

Logistics is published at `preview` implementation maturity. Its schemas, flows,
state machines, policies, errors, and examples pass the Release 2 validation
gates, but the area has not received sufficient implementation and
interoperability testing for production adoption. Implementers should use it for
evaluation and feed normative refinements into Release 2.

- [`patterns/`](patterns/) contains the six base transaction patterns.
- [`variants/`](variants/) contains only branches whose actions, schemas,
  states, and policy dependencies are available in Release 2.
- [`state-machines/`](state-machines/) contains the shared, versioned execution
  graphs referenced by pattern and variant profiles.

The Phase 6 review and explicit deferrals are recorded in
[`docs/internal/ION_Release1_Logistics_Flow_Migration_Ledger.md`](../../../../docs/internal/ION_Release1_Logistics_Flow_Migration_Ledger.md).
