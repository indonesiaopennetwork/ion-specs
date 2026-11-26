# v0.3 conformance audit and remediation

Baseline: uploaded `ion-specs-main (2).zip` and `ion-onix-main.zip`, SHA-256 recorded in conformance/input-provenance.json. Upstream commit history absent from ZIP. Original v0.2 and both archives unchanged.

## Findings
| Finding | v0.3 result | Remaining gate |
|---|---|---|
| CF01 Support | Corrected to Support.orderId, descriptor, canonical Grievance attributes; SC43 explicit proposal, acceptance, completion and resolution; schema passes. | Unresolved/disputed SATU and runtime grievance tests. |
| CF02 Reconcile | Canonical contracts/settlements/summary, SC44 commission disagreement then corrected retry, per-settlement accord. All four pass. | Product owner to confirm current maintained semantics versus earlier three-way business agreement; SEAM payout not tested. |
| CF03 Reference integrity | Corrected previously flagged 83 messages and 11 additional catalogue references. Offline targeted checks pass. | Rego compilation and multi-system catalogue/index validation. |
| CF04 Partial cancellation | Retain nonterminal contract with surviving valid entitlements; no whole-order invalidation. | Clarify core /on_cancel prose with protocol owner; no upstream normative change imposed. |
| CF05 Release scope | Overlay marks hospitality validation-pending; release scope and manifest pass. | Explicit approval for Release 2. |
| CF06 Rego | Four new metadata-bearing rules (CRC+resource ID, catalogue offer reference, commitment reference, assigned-seat count/uniqueness), six unit test functions, six smoke fixtures; generated registry has seven total rules. Python predicate mirror passed. | OPA format/strict compile/unit/smoke/bundle and live ONIX checks NOT run. Four rules do not cover every runtime invariant. |
| CF07 Policies | Six draft documents placed in canonical policy folders; registry generator passes (95 entries); 2,732 IRI and 1,244 hash/version checks pass. | Draft, not ratified; Indonesian legal and commercial review; policy runtime resolution. |
| CF08 Core/common | Full offline API request body validation 520/520. Canonical shared settlement throughout lifecycle; common attributes 268/268. Generated schemas use existing Ruby generator and release-qualified metadata. | Independent original upstream API conformance not claimed beyond supplied ION-maintained contract and pinned dependencies; exact field-level inheritance for sector-specific generic concepts remains reviewable. |
| CF09 Cancellation try echo | Existing core schema accepts the callback shape. | Confirm semantic echo and raw-body digest binding with owner. |
| CF10 Zero-payment booking | SC11 passes core schema without settlements; no invented payment. | Explicit zero-payment normative behaviour and live confirmation test. |
| CF11 Callback error exclusivity | Maintained action schemas and local fixtures pass. | Runtime ACK/NACK and callbacks. |
| CF12 Proactive event change | Core callback shape passes. | Organiser authority, consent, sequencing and notification semantics. |
| CF13 Finance | Canonical settlement, common payment definitions, fee projection and arithmetic cross-check. | Canonical Tax binding for applicable taxes; offer-level fee terms, settlement due dates, currency precision and stateful refund execution. |
| CF14 Error taxonomy | Eight error responses checked against core registered enum; no unknown code. | Register Hospitality-specific errors only if existing taxonomy insufficient; current sector registry not extended. |
| CF15 Catalogue | Five publish fixtures validated; catalogue identity checks; seven staged schema type indices. | Real catalog/publish acknowledgement, independent indexing and discovery filter tests. |
| CF16 PII/credentials | No real admission credentials in examples; opaque references and synthetic data. | Log redaction, access control and actual credential security review. |
| CF17 HTTP transport | Local BLAKE2b digests matched, 254 callback pairs. | Ed25519 signing, signed ACK, registry resolution, TTL, replay and callback binding not executed. |
| CF18 Stateful correctness | Existing branch plan retained; primary journeys for 43/43 in-scope scenarios. | Actual BAP/BPP/payment/admission integration, concurrent holds and admission/cancellation/refund races not executed. |

## Additional discovered defects
- 14 status messages did not include the core Contract.commitments required by the supplied schema. Reused last authoritative commitment snapshot rather than adding a fictitious booking. All now pass.
- 258 e-wallet declarations were ambiguous between EWallet and BNPL in `oneOf`; supplying wallet-specific amount resolves the overlap. Payment attributes are now reused through canonical Settlement rather than a separate Payment bag.
- Previous SC44 repeated an already-agreed settlement. New initial IDR 50,000 commission versus agreed 60,000 creates a genuine dispute; retry resolves it. Actual maintained Release 2 semantics are the source, not a new financial API.
- SC43 expanded from four to six grievance events, so total primary messages are 515 instead of 513. Five publish inputs are additional.

## Release gate outcome
The actual `ruby tools/release/validate_release.rb releases/release2` is still nonzero: Rego source/metadata (requires OPA), Rego unit/smoke tests, and signed bundle. All other gates reported passing. OPA installation failed because proxy.golang.org could not resolve; Docker is not installed. Uploaded ion-onix snapshot contains adapter configuration and Docker Compose definitions, not a locally runnable pinned ONIX source tree. Testnet configuration points to Release 1 by default and some receivers disable extension validation; must explicitly use staged Release 2 and enable extension checks. Existing signed Release 2 bundle is not a candidate bundle and MUST be rebuilt after OPA is available. No live network test, payment, signing key or deployment executed.

## Decisions requiring review
1. Candidate scope expansion and draft policy terms are not approval or ratification.
2. Current maintained reconciliation contract is used provisionally; review older three-leg agreement design and SEAM handoff.
3. Full versus partial cancellation and zero-payable contract need precise core semantic clarifications. Do not weaken core schemas simply to pass examples.
4. IDR minor/major conversion and synthetic fee/due-date/account assumptions are local fixture choices. Review canonical finance, tax and buyer-fee terms.
5. Rule changes to existing metadata tools enable sector HSP; actual OPA formatting, compilation and signed-bundle rebuild remain required.
6. All 43 scenario IDs have primary examples; exception and concurrency branches are not fully executed. See api-examples/BRANCH_TEST_PLAN.md.
