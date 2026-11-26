# Release 2 Storefront and Trade Rego candidate ledger

**Status:** Draft for rule approval

**Inventory date:** 2026-11-26

**Scope:** Release 2 Trade `storefront` flow, current Common packs, current
Trade extension packs, and the Trade performance state pack

This document lists business rules in English before they are implemented in
Rego. A row is not normative merely because it appears here. The source flow,
schema pack, or policy remains authoritative; candidates marked **Approve**
need an explicit normative decision before implementation.

The inventory deliberately does not turn every JSON Schema constraint into a
Rego rule. JSON Schema continues to own object shape, types, enums, formats,
and conditions that it can express clearly. Rego is for action-specific,
cross-field, cross-object, reference, calculation, and workflow rules.

## Source shorthand

- **SF** —
  [`releases/release2/flows/trade/patterns/storefront/v1/pattern.yaml`](../../../releases/release2/flows/trade/patterns/storefront/v1/pattern.yaml)
- **Common/&lt;pack&gt;** — the named pack below
  `releases/release2/schema/common/`
- **Trade/&lt;pack&gt;** — the named pack below
  `releases/release2/schema/extension/trade/`
- **States** —
  `TradePerformanceStates/v1/states.yaml`

## Dispositions

| Disposition | Meaning |
|---|---|
| **Implement** | The requirement is already explicit and the current ONIX message contains the data needed to evaluate it. |
| **Existing** | A Release 2 Rego rule already enforces it. |
| **Align** | The intended rule is understandable, but its pattern path, current API shape, and/or examples disagree and must be reconciled first. |
| **Approve** | The pack contains a conditional annotation or prose expectation, but the requirement is not yet sufficiently normative or scoped. |
| **Data** | The rule is valid, but evaluation needs a registry, catalog snapshot, prior message, clock, or operator configuration that the current policy input does not contain. |
| **Schema** | JSON Schema already owns the constraint; do not duplicate it in Rego by default. |
| **Defer** | The rule belongs to another Trade pattern or variant, or needs protocol/profile work first. |

Unless a row says otherwise, rejecting a structurally valid message is an
additive compatibility constraint and should use `POL_ELIGIBILITY_NOT_MET`.
Cancellation eligibility uses `POL_CANCELLATION_NOT_ALLOWED`. No candidate
uses `POL_GENERIC_ERROR`; ONIX reserves that for policy execution failure.

## Storefront scoping and source-alignment gate

The rows below describe Storefront semantics, but the production Beckn message
does not currently carry a normative Storefront selector. The examples contain
`_meta.pattern`, but `_meta` is repository fixture metadata rather than a field
in the protocol message. Before Storefront-only rules are added to the shared
`data.ion.release2.result` query, one of these must be true:

1. the rule is approved as a universal Trade rule;
2. the protocol supplies an authoritative pattern/profile selector; or
3. ONIX invokes a pattern-specific query using trusted routing context outside
   the message.

There are also concrete differences between SF `requiredFields` and the
current Beckn 2 publication example:

- SF names `context.domain`, but `Context` has no `domain` property and none of
  the Storefront examples sends one;
- SF uses singular `message.catalog`, while `catalog/publish` sends
  `message.catalogs[]`;
- SF uses `availableAt[].gps`, while the example and current location model use
  GeoJSON `geo`;
- SF locates resource name and description under `resourceAttributes`, while
  the example uses the resource `descriptor`;
- SF requires offer `price`, while the example carries price through
  `considerations[]`; and
- SF lists `minAge` for every resource, while its example omits it when
  `ageRestricted` is false.

The Storefront description also excludes restaurant meals, while its principal
catalog example uses a pizza restaurant and the `RESTAURANT` provider category.
These are specification-alignment findings, not reasons to guess at a Rego
interpretation. Rows affected by these conflicts are marked **Align**. The
English semantic rule can be retained, but its authoritative JSON path and
scope must be corrected before code is written.

## Wave 1 — catalog and publication

| ID | English rule | Applies to | Source / owner | Disposition | Data or compatibility note |
|---|---|---|---|---|---|
| TR-SF-001 | A Storefront catalog publication must identify the publishing BPP and publication timestamp, and must carry any profile/domain selector ultimately adopted for Storefront. | `catalog/publish`; equivalent catalog publication actions | SF Catalog | Align | `context.domain` is not in the current Context schema or examples; resolve profile scoping before implementation. |
| TR-SF-002 | Every published Storefront provider must have an ID, display name, operational status, at least one operating-hours entry, at least one provider category, an NIB, and an invoicing model. | Catalog publication and `on_discover` catalog snapshots | SF; Common/BusinessRegistration; Trade/TradeProvider | Implement | The rule applies only when the configured pattern is Storefront; it must not make NIB universal across all Trade patterns. |
| TR-SF-003 | Every Storefront provider availability location must include coordinates. | Catalog publication and `on_discover` | SF; Common/IdentifiableLocation; Trade/TradeProvider | Align | SF says `gps`; the current model and example use GeoJSON `geo`. |
| TR-SF-004 | Every Storefront resource must have an ID, name, short description, availability status, at least one media URI, origin country, and an explicit age-restriction declaration; an age-restricted resource must also state its minimum age. | Catalog publication and `on_discover` | SF; Trade/TradeResource | Align | Align descriptor paths and resolve SF's unconditional `minAge` listing against its own example. |
| TR-SF-005 | Every Storefront offer must have an ID and price consideration, and must declare cancellation, returns, warranty, dispute, settlement-basis, settlement-window, time-to-ship, COD availability, consumer-care contact, and display-language information. | Catalog publication and `on_discover` | SF; Trade/TradeOffer | Align | SF says `price`; the current example represents price with `considerations[]`. |
| TR-SF-006 | A resource whose structure is `COMPOSED` or `WITH_EXTRAS` must publish customization groups. | Catalog publication and `on_discover` | SF; Trade/TradeResource | Implement | Message-local if structure and groups are in the same resource. The actual inherited property spelling is `customisationGroups`. |
| TR-SF-007 | An age-restricted resource must declare a minimum buyer age. | Catalog publication and `on_discover` | Trade/TradeResource | Approve | The relationship is clear, but SF currently requires both fields on every resource; resolve the overlap with TR-SF-004. |
| TR-SF-008 | A provider with operational status `TEMPORARILY_CLOSED` must state when the closure ends. | `catalog`, `publish`, `on_discover` | Trade/TradeProvider | Existing | `ION-R2-TRD-0001`. |
| TR-SF-009 | A provider using `CENTRAL` invoicing must identify the invoicing entity. | `catalog`, `publish`, `on_discover` | Trade/TradeProvider | Existing | `ION-R2-TRD-0002`. |
| TR-SF-010 | A provider verification result of `APPROVED_WITH_CAVEATS` must include the caveats. | Catalog publication and `on_discover` | Trade/TradeProvider | Approve | Comes from an `x-ion-condition`; approving it makes existing schema-valid catalogs more restrictive. |
| TR-SF-011 | A published policy reference must resolve to a registered, non-deprecated ION policy of the expected policy type. | Catalog publication and `on_discover` | Trade/TradeOffer; shared policy registry; Trade errors ION-A2010/A2011 | Data | Bundle needs generated policy-registry data. The Rego response still uses a protocol `POL_*` code, not an `ION-A*` code. |
| TR-SF-012 | IDs for provider locations, resources, offers, customization groups, and customization options must be unique in their enclosing catalog scope. | Catalog publication and `on_discover` | Common/IdentifiableLocation; Trade/TradeOffer; Trade/TradeResource | Implement | Message-local cross-object uniqueness. Define the exact enclosing scope per ID type in tests. |
| TR-SF-013 | Every location ID used by operating hours, closures, serviceability, or another provider-local reference must identify a location published by that provider. | Catalog publication and `on_discover` | Common/IdentifiableLocation; Trade/TradeProvider | Implement | Message-local when the complete provider snapshot is present. |
| TR-SF-014 | A variant resource must identify its parent and variant group and must explicitly say whether it is the default variant. | Catalog publication and `on_discover` | Trade/TradeResource | Approve | Conditional prose was intentionally left out of the shared schema; approve exact resource-structure values first. |
| TR-SF-015 | A Storefront offer that declares a buyer finder fee must provide its fee type, value, and calculation base. | Catalog publication and `on_discover` | SF; Trade/TradeConsideration | Implement | Message-local; JSON Schema still owns the internal fee shape and numeric bounds. |

## Wave 2 — selection and quote

| ID | English rule | Applies to | Source / owner | Disposition | Data or compatibility note |
|---|---|---|---|---|---|
| TR-SF-020 | A Storefront `select` request must carry the transaction and message IDs, BAP and BPP IDs and URIs, domain, timestamp, TTL, and buyer city code. | `select` | SF Transaction | Implement | Action-specific envelope profile. |
| TR-SF-021 | Every selected commitment must identify the provider, offer, commitment, resource, unit quantity, and unit code. | `select` | SF; Trade/TradeCommitment | Implement | Message-local presence rule. |
| TR-SF-022 | Every selected performance must state its requested performance mode. | `select` | SF; Trade/TradePerformance | Implement | Message-local. |
| TR-SF-023 | Each selected provider, offer, resource, unit, and customization option must exist in the catalog version on which the selection is based. | `select` | Trade/TradeCommitment; Trade/TradeOffer | Data | Needs the referenced catalog snapshot or a trusted catalog lookup in policy input. |
| TR-SF-024 | Selecting a `COMPOSED` or `WITH_EXTRAS` resource requires customization selections that satisfy every mandatory group and each group's minimum and maximum selection counts. | `select` | SF; Trade/TradeCommitment; Trade/TradeOffer; Trade error ION-A3001 | Data | Needs the selected resource and offer customization definitions from the catalog. |
| TR-SF-025 | Every selected customization option must belong to the selected group and be valid for the selected resource or offer. | `select` | Trade/TradeCommitment; Trade/TradeOffer; Trade errors ION-A3002/A3007 | Data | Needs catalog customization and variant data. |
| TR-SF-026 | Voucher and offer stacking in a selection must obey each applicable offer's stacking rule. | `select`, possibly `init` | Trade/TradeOffer; Trade error ION-A3006 | Data | Needs all applicable offer terms and an approved precedence algorithm. |
| TR-SF-027 | A Storefront `on_select` quote must retain commitment and provider identity and must return a price breakup, total amount, selected performance mode, supported performance modes, and SLA. | `on_select` | SF; Trade/TradeConsideration; Trade/TradePerformance | Implement | Message-local response profile. |
| TR-SF-028 | Every `TAX` line in a Storefront quote breakup must state its tax rate. | `on_select`, `on_init`, and later full price considerations | SF; Common/Tax; Trade/TradeConsideration | Implement | Action-specific condition; do not make tax details mandatory on non-tax lines. |
| TR-SF-029 | The selected performance mode returned in `on_select` must be one of the returned supported performance modes. | `on_select` | Trade/TradePerformance | Implement | Message-local membership check. |
| TR-SF-030 | If selected resources require cold-chain or fragile handling, `on_select` must return the required handling instructions. | `on_select` | SF; Trade/TradePerformance | Data | Needs authoritative resource classification or handling metadata from the selected catalog snapshot. |
| TR-SF-031 | If selected offers carry buyer finder fees, the quote must state the order-level fee amount computed from the selected quantities and each offer's fee terms. | `on_select`, `on_init` | SF; Trade/TradeConsideration | Data | Needs the offer terms and a defined rounding rule. |
| TR-SF-032 | A delivery charge may appear at most once per order, must not appear for self-pickup, must remain while any item remains ordered, and must not form part of the buyer finder fee base. | Quote and later consideration snapshots | Trade/TradeConsideration | Implement / Data | Presence and single-line checks are message-local; persistence and fee-base derivation need earlier/catalog data. Split this candidate when implemented. |

## Wave 3 — initialization and confirmation

| ID | English rule | Applies to | Source / owner | Disposition | Data or compatibility note |
|---|---|---|---|---|---|
| TR-SF-040 | A Storefront `init` request must identify the provider, every commitment, and every performance. | `init` | SF; Trade/TradeContract | Implement | Message-local presence rule. |
| TR-SF-041 | The buyer participant in `init` must contain a person ID, name, telephone number, and billing address. | `init` | SF; Trade/TradeParticipant; Common/Address | Implement | Scoped to the participant whose role is `BUYER`. |
| TR-SF-042 | Every Storefront delivery stop in `init` must include an address, geometry, postal code, and Indonesian province code. | `init` | SF; Common/Address; Trade/TradePerformance | Implement | Message-local Storefront requirement. |
| TR-SF-043 | A Storefront `init` settlement must state method, payment rail, collector, status, currency, order amount, commission, and net payable. | `init` | SF; Common/Settlement | Implement | Message-local presence rule. |
| TR-SF-044 | A Storefront `on_init` response must return payment method details, final price breakup and total, currency, order amount, commission, net payable, and a BPP settlement account. | `on_init` | SF; Common/Payment; Common/Settlement; Trade/TradeConsideration | Implement | Message-local response profile. |
| TR-SF-045 | `QRIS` payment details must contain a QRIS string, `VIRTUAL_ACCOUNT` details must contain a VA number, and `EWALLET` details must contain a deep link. | `on_init` | SF; Common/Payment | Implement | Message-local method-to-detail relationship. |
| TR-SF-046 | If the BAP supplied its settlement account in `init`, `on_init` must return the same BAP account without changing its identity or allocation. | `on_init` | SF; Common/Settlement | Data | Requires the paired `init` request. |
| TR-SF-047 | For every settlement snapshot, net payable must equal order amount minus commission, withholding, recovery, and refund amounts, plus or minus every additional component according to its declared effect. | `init` through reconciliation | Common/Settlement | Implement | Confirm the exact treatment of absent values and decimal rounding before coding. |
| TR-SF-048 | The settlement commission must equal the order-level buyer finder fee amount in the contract's current price consideration. | `on_init`, `confirm`, reconciliation snapshots | Common/Settlement; Trade/TradeConsideration | Implement | Message-local when both values are present in the same full contract snapshot. |
| TR-SF-049 | A settlement with positive commission must contain a BAP settlement account. | Contract and reconciliation settlement snapshots | Common/Settlement | Schema | Already expressed by JSON Schema; no Rego duplicate unless equivalence testing shows an ONIX schema gap. |
| TR-SF-050 | A Storefront `confirm` request must retain provider, commitments, buyer, and performance data and must state settlement status, method, paid time, and order amount. | `confirm` | SF; Trade/TradeContract; Common/Settlement | Implement | Message-local binding-commit profile. |
| TR-SF-051 | A settlement whose status is `PAID` must contain `paidAt`. | `confirm`, `on_confirm`, `status`, `on_status` | Common/Payment; Common/Settlement | Existing | `ION-R2-COM-0001`; the underlying Settlement schema also contains this condition. |
| TR-SF-052 | Buyer business registration must be present when a business buyer requests a tax invoice and must be absent for an ordinary consumer buyer. | `confirm` | SF; Common/BusinessRegistration; Trade/TradeContract | Approve | Define a non-circular, machine-readable indicator of “business buyer” and “tax invoice requested” first. |
| TR-SF-053 | A Storefront `on_confirm` response must contain contract ID and status, performance ID and status, settlement status, and fulfilling location ID. | `on_confirm` | SF; Trade/TradeContract; Trade/TradePerformance | Implement | Message-local response profile. |
| TR-SF-054 | A performance using OTP proof of delivery must include a delivery OTP; a self-pickup performance must include a self-pickup code. | `on_confirm` and later full snapshots | SF; Trade/TradePerformance | Implement | Message-local cross-field rules. Secret-handling guidance is still required for logs and diagnostics. |
| TR-SF-055 | Every fulfilling location ID must resolve to a location of the selected provider. | `on_confirm` and later snapshots | Common/IdentifiableLocation; Trade/TradeProvider; Trade/TradePerformance | Data | Needs provider locations in the same snapshot or catalog lookup data. |

## Wave 4 — fulfilment, settlement, and reconciliation

| ID | English rule | Applies to | Source / owner | Disposition | Data or compatibility note |
|---|---|---|---|---|---|
| TR-SF-060 | A Storefront status request must identify the contract whose status is requested. | `status` | SF | Implement | Message-local. |
| TR-SF-061 | Every Storefront `on_status` message must carry a full current contract snapshot rather than a sparse patch. | `on_status` | SF Fulfilment | Approve | “Full” needs an exact field set per lifecycle state before it is testable. |
| TR-SF-062 | A `DISPATCHED` performance must include its state code, tracking number, tracking URL, and estimated delivery time. | `on_status` | SF; Trade/TradePerformance | Implement | Message-local state-to-fields rule. |
| TR-SF-063 | A performance fulfilled by an on-network logistics provider must identify that logistics provider. | `on_status` and other performance snapshots | SF; Trade/TradePerformance | Approve | Define the machine-readable indicator for on-network fulfilment. |
| TR-SF-064 | A `DELIVERED` update must mark the contract complete. | `on_status` | SF; Trade/TradeContract; States | Implement | Confirm exact contract status enum value from the core schema. |
| TR-SF-065 | When proof-of-delivery type is `PHOTO`, a delivered performance must include a delivery-proof URL. | `on_status` | SF; Trade/TradePerformance | Implement | Message-local. |
| TR-SF-066 | A performance may move only through an allowed transition in the standard Trade performance state machine. | `on_status` | States | Data | Requires the previously accepted state; a single current snapshot cannot prove a transition. |
| TR-SF-067 | An order may become `COMPLETE` only when all required performances and commitments are in terminal successful states. | `on_status` | Trade/TradeContract; Trade/TradeCommitment; States | Approve | Define required performance/commitment terminal-state mapping. Current SF only states the simple delivered case. |
| TR-SF-068 | A reconcile request must state settlement date and summary and, for every contract and settlement, the contract ID and commitments plus settlement ID, order amount, commission, net payable, order date, due date, and BPP account. | `reconcile` | SF; Common/Settlement | Implement | Message-local reconciliation profile. |
| TR-SF-069 | If a BPP splits net payable among recipients, every allocation must identify its purpose and the allocation amounts must add exactly to net payable. | `reconcile`, `on_reconcile` | SF; Common/Payment; Common/Settlement | Implement | Define decimal normalization and whether incomplete allocation sets are allowed. |
| TR-SF-070 | An `on_reconcile` response must state settlement date and reconciliation status, give each settlement an accord result, and report agreed, disputed, and pending counts and agreed and unreconciled commission and net-payable totals. | `on_reconcile` | SF; Common/Settlement | Implement | Message-local presence rule. |
| TR-SF-071 | Reconciliation summary counts and monetary totals must equal the classifications and values of the settlements included in that message. | `reconcile`, `on_reconcile` | Common/Settlement | Implement | Message-local aggregation; define handling of duplicate settlement IDs. |
| TR-SF-072 | A settlement with `accord: true` must contain a due date; one with `accord: false` must contain a dispute. | `on_reconcile` | SF; Common/Settlement | Schema | Already expressed in JSON Schema. |
| TR-SF-073 | When the answering participant changes a disputed monetary value, its `diffValue` must equal the answering value minus the requested value. | `on_reconcile` | SF; Common/Settlement | Data | Requires the paired reconcile request and exact sign convention. |
| TR-SF-074 | Settlement due date must be derived from the latest applicable settlement basis and window among the ordered offers; cancellation substitutes for an unoccurred basis event. | `reconcile`, `on_reconcile` | Common/Settlement; Trade/TradeOffer | Data | Needs offer terms and trusted event timestamps. |
| TR-SF-075 | A new reconcile attempt must keep the order transaction ID, use a new message ID, and contain only settlements that were disputed or pending in the prior attempt. | `reconcile` | SF Settlement reconciliation | Data | Requires prior messages and accepted reconciliation state. |

## Wave 5 — grievance rules used by Storefront

| ID | English rule | Applies to | Source / owner | Disposition | Data or compatibility note |
|---|---|---|---|---|---|
| TR-SF-080 | The BAP and BPP IDs in a grievance event must remain the participants of the order; buyer events use `support` and seller events use `on_support` according to the approved ION grievance profile. | `support`, `on_support` | SF; Common/Grievance | Data / Defer | Order-party comparison needs order state. Unsolicited seller `on_support` is still pending upstream profile approval. |
| TR-SF-081 | A direct grievance callback must repeat the request message ID; each new grievance event must use a new message ID; every event must retain the order transaction ID. | `support`, `on_support` | Common/Grievance | Data | Requires the event history. |
| TR-SF-082 | A grievance decision must identify the latest proposal ID and version and must be made by a participant other than the proposer. | `support` with `RESOLUTION_DECIDED` | Common/Grievance | Implement / Data | Different-actor check is message-local when the resolution is included; “latest version” needs history. Split on implementation. |
| TR-SF-083 | Every financial effect's allocation basis must match the resolution authorization type; a unilateral effect must make the funding NP, not the counterparty, liable. | Resolution events | Common/Grievance | Implement | Message-local cross-object rule. |
| TR-SF-084 | Every executed action ID must identify an action in the same resolution. | `ACTION_COMPLETED`, `RESOLVED` | Common/Grievance | Implement | Message-local reference-integrity rule. |
| TR-SF-085 | A resolved grievance must have an execution reference for every action whose execution method is not `NONE`, and explicit-agreement resolutions must include an accepted decision. | `RESOLVED` | SF; Common/Grievance | Implement | Message-local. Some presence conditions are also schema-owned; Rego should enforce the cross-array relationship only. |
| TR-SF-086 | If related references include a settlement, every refund financial effect must identify the settlement it affects. | Resolution events | Common/Grievance; Common/Settlement | Implement | Message-local. |
| TR-SF-087 | Only the originating participant may send `OBJECTION` or `CLOSED`. | `support`, `on_support` | Common/Grievance | Implement | Requires a reliable sender ID in the current context and the message's `originatingNpId`. |
| TR-SF-088 | Protocol acknowledgement, grievance resolution, deemed closure, and silence must never be interpreted as agreement to settlement figures; financial agreement occurs only through reconcile/on_reconcile. | Grievance and reconciliation | Common/Grievance; Common/Settlement | Defer | This is primarily routing/state-machine semantics, not a single-message rejection rule. Preserve it in operator and implementation guidance. |

## Rules already owned by JSON Schema

These remain important, but duplicating them would create two sources of truth.
Rego equivalence rules should be added only if ONIX schema validation cannot
reach the relevant generated schema or if a deliberate defense-in-depth
decision is recorded.

| Pack | Schema-owned rule |
|---|---|
| Common/BusinessRegistration | `PERORANGAN` registration requires `nikNumber`. |
| Common/Grievance | Event types require their corresponding opened, resolution, decision, execution, and terminal-status structures. |
| Common/Grievance | Policy-authorized resolutions require policy and verification data; unilateral resolutions require a funding NP. |
| Common/Payment | Credit-facility payments require credit terms; refunded payments require refund data. |
| Common/Payment | Seller, logistics, provider, and other settlement-account roles require holder and allocation identity. |
| Common/Settlement | Positive commission requires a BAP account; non-pending settlement requires a BPP account or BPP allocation; `PAID` requires `paidAt`. |
| Common/Settlement | `accord: true` requires `dueDate`; `accord: false` requires `dispute`. |
| Common/Settlement | Additional financial components require their declared effect on net payable. |
| Trade/TradeConsideration | Percentage fees are bounded at 100 and amount fees cannot declare `appliesTo`. |
| All packs | Required fields, types, enums, formats, closed-object constraints, and scalar bounds already expressed in the generated schemas. |

## Candidates needing a later scope decision

The current objects contain conditions that are not Storefront-wide rules.
They should not be silently enabled merely because the fields exist.

| Area | English candidate | Why not in the first Storefront implementation |
|---|---|---|
| Common/Address | Delivery addresses require `kelurahan` and `kecamatan`. | Pack annotation exists, but SF currently names postal code and province code rather than these fields. Reconcile the sources first. |
| Common/Payment | Gateway payments require `gatewayRef`; post-handover COD requires collected amount and time; short collection requires a reason. | Define exact actions and lifecycle points, then add to the relevant payment/COD pattern. |
| Common/Tax | Non-exempt taxes require regime/category and a reproducible computation trail. | The current annotation needs a normative rule and exact scope. |
| Trade/TradeProvider | Food, grocery, and quick-commerce providers require average preparation time. | Needs an authoritative category mapping. |
| Trade/TradeProvider | Providers in regulated categories require applicable, valid category licences. | Needs category and licence registry data plus date evaluation. |
| Trade/TradeResource | Food, packaged-goods, regulatory, fashion, electronics, beauty, produce, pharmaceutical, installation, warranty, and geographic-indication blocks become required for matching categories or claims. | Release 2 does not yet have one normative category-requirement registry. Implement category families only after that registry is approved and bundled as data. |
| Trade/TradeOffer | Cross-border offers include `en`; domestic logistics offers publish weight slabs; BNPL details appear only for BNPL; queue estimates appear with queue position. | Some are other-pattern rules; the remainder need explicit action scope. |
| Trade/TradeContract | Procurement requires purchase-order and buyer-registration data; subscriptions require billing cycle; partial and forced cancellations require their evidence. | Belongs to procurement, subscription, and cancellation pattern/variant inventories. |
| Trade/TradeSettlement | Completed trade settlement records use IDR for domestic Trade. | The pack intentionally avoids a schema constant so cross-border settlement can use another currency; pattern/network scope must be explicit. |
| Trade performance variants | Cancellation windows, return windows, RTO, and update eligibility must follow the selected offer policies. | Inventory with the corresponding variant. Cancellation rejection should use `POL_CANCELLATION_NOT_ALLOWED`. |

## Pack coverage

| Current pack | Candidate coverage |
|---|---|
| Common/Address | TR-SF-041, 042; later-scope address decision |
| Common/BusinessRegistration | TR-SF-002, 052; schema-owned registration rule |
| Common/Grievance | TR-SF-080 through 088; schema-owned event shapes |
| Common/IONParticipant | TR-SF-041, 050, 080 |
| Common/IdentifiableLocation | TR-SF-003, 012, 013, 055 |
| Common/Payment | TR-SF-045, 051; later-scope gateway and COD rules |
| Common/Settlement | TR-SF-043 through 049, 051, 068 through 075 |
| Common/Tax | TR-SF-028; later-scope tax decision |
| Trade/TradeCommitment | TR-SF-021, 023 through 025, 067 |
| Trade/TradeConsideration | TR-SF-015, 027, 028, 031, 032, 044, 048 |
| Trade/TradeContract | TR-SF-040, 050, 052, 053, 064, 067; later-pattern contract decisions |
| Trade/TradeOffer | TR-SF-005, 011, 012, 015, 023 through 026, 031, 032, 074 |
| Trade/TradeParticipant | TR-SF-041, 050 |
| Trade/TradePerformance | TR-SF-022, 027, 029, 030, 042, 053 through 055, 062 through 067 |
| Trade/TradePerformanceStates | TR-SF-064, 066, 067 |
| Trade/TradeProvider | TR-SF-002, 003, 008 through 010, 013, 055; later category/licence decisions |
| Trade/TradeResource | TR-SF-004, 006, 007, 012, 014, 023 through 025; later category-family decisions |
| Trade/TradeSettlement | Later-scope domestic-currency decision; Storefront reconciliation otherwise uses Common/Settlement |

## Recommended first implementation slice

After review, begin with a small catalog slice rather than all **Implement**
rows at once:

1. Reconcile the Storefront scoping and publication-path findings above and
   update the pattern and examples together.
2. Then implement the approved parts of TR-SF-001 through TR-SF-003 for
   Storefront catalog identity and provider presence requirements.
3. Implement TR-SF-012 and TR-SF-013 for catalog-local uniqueness and location reference
   integrity.
4. Add valid, single-failure, multiple-failure, unrelated-action, and
   non-Storefront fixtures.
5. Measure policy evaluation on a representative large catalog before adding
   per-resource and per-offer rules.

This slice exercises action scoping, pattern scoping, array traversal, and
cross-object references without requiring external state or a new bundled data
registry.
