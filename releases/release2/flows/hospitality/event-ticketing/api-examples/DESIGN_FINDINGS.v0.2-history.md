# v0.2 change log and engineering review

## Scope and outcome
All 43 in-scope scenario IDs have a primary candidate message sequence; SC24 waiting list remains deferred. This is scenario presence, not full behavioural or branch conformance. The business documents remain authoritative. Some fixture names, times, quantities and prices are simplified; where they differ, do not reinterpret the business requirement. No upstream files changed.

| Finding | v0.2 change | Remaining gate |
|---|---|---|
| F01 premature policy acceptance | Offered snapshots separate from accepted; prepared can have empty acceptance, confirmed/cancelled/completed require acceptance; all previous known violations cleared. | Require accepted set to equal offered set at confirm in action-specific rules; verify policy registry and signature. |
| F02 auto assignment | Allocation stages REQUESTED/PROPOSED/HELD/COMMITTED/RELEASED; successful auto assignment requires seats/layout. | Inventory and adjacency checks; action-specific state enforcement. |
| F03 late payment | Refund scope PAYMENT_ATTEMPT or TICKET; respective attemptRef or ticketIds required; SC35 extends through owed/completed refund. | Payment authority, refund idempotency, shared payment binding. |
| F04 organiser action | Separate initiator, consent decision and application state; organiser cancellation/non-delivery requires NOT_REQUIRED rather than fabricated consent. | Proactive callback and regulatory/contractual basis. |
| F05 material event change | Proposed event revision, sessions, notice and replacement allocations; preview/acceptance/application examples SC30/31. | Refund alternative branch, exact seat map and consent deadline tests. |
| F06 policy arithmetic | Preserve full-refund policy and separate 80% draft policy; snapshots now hash exact local YAML and use policy versions. | Registration, policy semantics and regulatory review. |
| F07 money | Local price component and refund ceiling checks; SC44 includes Rp900,000 payable after Rp240,000 refund and Rp60,000 fee. | Canonical Common Payment/Tax/Settlement model still unresolved; no duplicate production source should be created. |
| F08 recovery | Known draft contract identity from on_init reused for status after lost confirmation. | Confirm exact status lookup binding; unknown ID recovery and concurrent retry tests. |
| F09 layout, access, mixed and bundles | Add accessibility companion refs, layout refs, attendee type/eligibility, add-on selection refs, provider seller model, admission attempt summary. Mixed basket, student pricing, named/replay examples provided. | Real layout exchange, selected add-ons, external gate identity and multi-pool atomicity remain runtime/integration work. |
| F10 upstream wire | Recompute local request and preview digests after revisions; add draft shared support/reconcile examples. | Pinned upstream core, exact extension attachment, shared payload validation, Rego, canonical errors, production signing and manifest wiring remain open. |

## New or expanded scenario examples
SC07 mixed VIP/standing basket; SC13 adult/student; SC15 session-specific seat; SC17 named and duplicate check (bearer SC03); SC28 upgrade; SC32 non-delivery; SC36 same-operation retry; SC38 invalid credential; SC41 direct versus marketplace; SC42 policy/category; SC43 support; SC44 reconciliation. SC21/33 show release after expiry/failure, SC35 late refund, SC30/31 change application, SC37 no-show. SC39 covers admission-first race; cancellation-first remains test plan. SC36 does not yet simulate proven duplicate captures across two actual bookings; SC42 unresolved policy and SC43 disputed remedy/SATU escalation remain test-plan branches. SC28 is a simplified two-ticket upgrade fixture, not the single-ticket commercial fixture in the catalogue; exact payment and update binding is provisional. SC32 uses a cancellation snapshot with refund obligation; insolvency handling remains outside network messages. Shared support/reconcile messages are candidate envelopes and must not be treated as existing official schemas.

## Release gates (before PR)
1. Obtain pinned ion-specs checkout and approve Hospitality scope in Release 2; keep Release 1 immutable.
2. Verify parent schemas, extension slots, context and vocabulary, common fields, monetary precision and exact profile indexing. Unify canonical financial source.
3. Register policy IRIs and versions after regulatory review, check CRC scope, error-code collisions and release manifests.
4. Verify cancellation/update preview digests, notification semantics, support, reconcile, and signing against upstream; replace candidate bindings.
5. Implement action-specific validation and executable ONIX Rego; run official repository validation. Execute runtime/negative branch plan against BAP/BPP, payment and admission test doubles, including concurrency.
6. Review against all 57 numbered BRD requirements and every acceptance condition in scenario catalogue. Only then mark conformance and PR readiness.

No production credentials, actual personal data, live calls or real payments are included.
