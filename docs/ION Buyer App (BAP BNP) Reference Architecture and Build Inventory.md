# ION Buyer App (BAP/BNP): Reference Architecture and Build Inventory

Draft · Nov 25, 2026

## Scope and baseline

This document defines what a buyer app on ION must contain: the customer app, an admin panel, a curation layer, a discovery crawler and the app's own discover service, plus the order, payment, support and reconciliation functions that sit behind them. It mirrors the seller app reference architecture and uses the same layers, so the two can be read side by side.

**Role.** The buyer app is a Consumer Node (CN), formerly BAP or BNP. The wire fields `bapId` and `bapUri` stay as they are and read as the CN's identity and address. The buyer app owns the consumer relationship: it onboards consumers, creates or verifies their identity on the fabric, and starts every transaction on their behalf.

**Discovery is a separate actor.** The spec defines a Discovery Service (DS) with its own fabric identity and public key. A DS can be an independent SaaS that CNs consume, or the CN can implement it itself. Even when bundled in one platform, the CN and the DS use separate identities and keys. This document treats the buyer app's own discover service as a DS bundled with the CN.

**How a DS stays current.** It must keep its catalogue index fresh in one of two ways: by subscribing to the Cataloging Service (deprecated, superseded by NFH-014), or by crawling and independently verifying catalogue files that provider nodes host. The crawler in this document implements the second way, which is the path for new integrations.

**What the CN sends.** The CN sends `/discover` to a DS with an Intent. The Intent carries `textSearch`, a JSONPath filter per RFC 9535, optional spatial constraints and optional media search. The DS answers with `/on_discover` carrying matching catalogues, and the CN correlates the callback by `messageId`. The CN does not talk to the fabric for discovery.

**Baseline used here.**

- Spec: `ion-beckn.yaml` and `ion-additional.yaml` (Release 1), the entity hierarchy model, the ION reference app's technical artifact, and the marketplace patterns (listed and in-house).
- Reference stack: Go backend (Gin, sqlc, tern), React frontend, an ONIX adapter for signing and routing, Zitadel for human login, one Postgres database per app, Redis per adapter.
- Scope out: the seller side (see the seller reference architecture), registry operation, and settlement execution by SEAM.

The ION reference app sends `/discover` straight to a discover endpoint, signed, outside the ONIX adapter, and reads the answer in the response. Every other action goes through the adapter and returns as a callback. A production buyer app should decide which of these two behaviours it supports, because the spec describes `/on_discover` as an asynchronous callback.

## Architecture

&#91;embedded content: buyer app architecture · 4 layers, 3 shared services\]

The discover service is highlighted because it is the buyer-specific part: it has its own identity, its own index and its own ranking. The crawler feeds it from provider-hosted catalogue files, and the curation layer constrains what it can return.

## Component inventory

These are the components a buyer app team builds or buys. Rows marked Spec are required by the protocol. Rows marked Design are this document's recommendation and a team can change them.

**A. Customer app**

| Component | What it does | Basis |
| --- | --- | --- |
| Search and browse | Builds the Intent from the shopper's query and filters, calls the discover service, renders results | Spec |
| Product page renderer | Chooses fields, badges and filters from the item's category (CRC) so a pharmacy item and a food item look different | Spec (CRC guidance) |
| Cart and checkout | Holds selected offers; drives `/select`, `/init`, `/confirm` | Spec |
| Payment collection | Collects payment when the offer is prepaid; `/confirm` then means payment is done | Spec |
| Order tracking | Shows `/status` and `/track` results and unsolicited `on_*` updates | Spec |
| Cancel, return, support | Calls `/cancel`, `/update`, `/support`; shows grievance events | Spec |
| Ratings | Calls `/rate` after performance | Spec |
| Consumer account | Login, addresses, order history scoped to the logged-in buyer | Design |

**B. Admin panel (buyer side)**

| Component | What it does | Basis |
| --- | --- | --- |
| Catalogue health | Shows crawl status per provider node, last good fetch, rejected files and reasons | Design |
| Curation console | Manages collections, allow and deny lists, boosts, banners and home-page layout | Design |
| Order operations | Searches orders by transaction, shows the message log, retries stuck flows | Design |
| Support desk | Works grievance cases, records decisions, tracks SLA clocks | Spec for events, Design for UI |
| Finance | Settlement batches, finder fee, disputes, refunds | Spec for messages, Design for UI |
| Seller directory | Provider nodes and providers the buyer app has chosen to list or block | Design |
| Users and roles | Staff accounts, roles, audit log | Design |
| Partner config | Branding, enabled sectors and fee terms for partner-branded apps | Design |

**C. Discovery crawler**

| Component | What it does | Basis |
| --- | --- | --- |
| Source resolver | Finds provider nodes and their published catalogue index through the registry and DeDi | Spec (NFH-014), not read in full |
| Fetcher | Pulls index and catalogue files on a schedule and on change signals | Spec |
| Verifier | Checks signatures and schema validity before a file enters the index | Spec ("independently verifying") |
| Normaliser | Maps catalogue JSON to the index document, keeps attribute packs intact | Design |
| Scheduler and backoff | Per-source cadence, retry, quarantine for bad sources | Design |

**D. Discover service (the buyer app's own DS)**

| Component | What it does | Basis |
| --- | --- | --- |
| Discover endpoint | Receives `/discover`, returns `/on_discover` with catalogues | Spec |
| Query engine | Evaluates `textSearch`, JSONPath filters (RFC 9535), spatial constraints and media search | Spec |
| Search index | Stores resources and offers with their attributes, location and freshness | Design |
| Ranking | Orders results; applies curation boosts and demotions | Design |
| Identity | Own fabric namespace, address and signing key, separate from the CN | Spec |

**E. Order, payment and post-order services**

| Component | What it does | Basis |
| --- | --- | --- |
| Order service | State per transaction; matches each `on_*` to its request by `transactionId` and `messageId` | Spec |
| Payment service | Collects, refunds, records `collections` and `refund` objects | Spec |
| Grievance service | Opens, escalates and closes cases as `IONGrievance` events | Spec |
| Reconciliation service | Builds `/reconcile` batches per `settlementDate`, handles `/on_reconcile` | Spec |
| Notification service | Push, email and in-app messages from order events | Design |
| Message log | Stores every outbound request and inbound callback with status and latency | Design (reference app does this) |

**F. Platform**

| Component | What it does | Basis |
| --- | --- | --- |
| ONIX adapter | Signs, validates, routes; one instance per role identity | Spec |
| Identity provider | Human login for shoppers and staff (OIDC) | Design (reference app uses Zitadel) |
| Data stores | One relational database per service, a cache per adapter, an object store for crawled files | Design |

## Protocol surface

The buyer app sends requests and receives callbacks. Any `on_*` message can also arrive without a request, so the buyer app must accept them at any time and match them by `transactionId`.

| Direction | Message | Buyer app does |
| --- | --- | --- |
| Send to DS | `/discover` | Sends an Intent: `textSearch`, JSONPath filter, spatial, media |
| Receive from DS | `/on_discover` | Reads matching catalogues; correlates by `messageId` |
| Send to PN | `/select` | Requests a priced quote on discovered offers |
| Send to PN | `/init` | Submits billing details and fulfilment preferences |
| Send to PN | `/confirm` | Commits the order; for a prepaid offer it means payment was collected |
| Send to PN | `/status`, `/track` | Asks for order state and live position |
| Send to PN | `/update`, `/cancel` | Amends or cancels; cancel carries `reason`, `commitmentIds`, `forced` |
| Send to PN | `/support`, `/rate` | Opens a support request; submits ratings |
| Both | `/reconcile`, `/on_reconcile` | Batched per `settlementDate`; the response is AGREED, DISPUTED or PENDING |
| Receive from PN | `/on_select`, `/on_init`, `/on_confirm`, `/on_status`, `/on_track`, `/on_update`, `/on_cancel`, `/on_support`, `/on_rate` | Updates the order record and the shopper |

**Discovery is the one buyer-specific exchange.** The seller side never receives `/discover`. The buyer app owns the whole exchange: it builds the Intent, chooses a DS, and decides what to show.

**Catalogue intake has two paths.**

1. *Decentralised publishing (NFH-014, the current model).* Providers' nodes host signed catalogue files and an index. The crawler fetches, verifies and indexes them. The reference app's seller side publishes to a public bucket and serves `.well-known/dedi.index.json`, which points to a registry entry and then to the catalogue files.
2. *Cataloging Service subscription (deprecated).* The DS subscribes to the Cataloging Service and receives catalogues pushed to it. The endpoints stay defined for existing integrations. New buyer apps should not start here.

**Signing.** Every outbound message carries an Ed25519 HTTP signature from the role's registered key. The CN and the DS each have their own namespace, address and key. Staff and shopper logins are a separate layer and do not authenticate network messages.

**Filters and attributes.** The `filters.expression` field is JSONPath over the catalogue document, for example `$[?(@.rating.value >= 4.0 && @.electronic.brand.name == 'Premium Tech')]`. The index must therefore keep attribute packs under their published paths, or filters written against the spec will not match. Participant extension fields that sellers add (for example `map:` fields) are not validated by the network, so the buyer app should treat them as optional display data and never as filter keys it depends on.

## Discovery and curation

This section is mostly design. The spec fixes the `/discover` contract and the duty to keep the index fresh and verified. It does not fix how a DS crawls, indexes or ranks, so the rules below are recommendations.

**Crawler.**

1. Resolve sources. Read the registry for provider nodes on the subnet, then each node's published index file.
2. Fetch on a schedule per source, and again when a source signals a change.
3. Verify before indexing. Reject files with a bad signature, a schema failure, or a provider that is not registered. The spec requires independent verification and does not say how.
4. Normalise into index documents. Keep the catalogue's attribute packs under their published paths so JSONPath filters work.
5. Quarantine a source after repeated failures. Show it in the admin panel with the reason.
6. Record freshness per document: fetched at, catalogue timestamp, and a stale flag after a set age.

**Index.** One document per offer, joined to its resource and provider. Store text fields for search, the full attribute tree for JSONPath, geometry for spatial queries, and the provider node's `bppId` and `bppUri` so a later `/select` goes to the right node. The index is a cache. The published catalogue file stays the source of truth.

**Query handling.**

- `textSearch` runs against name, description, brand and category terms.
- `filters` runs as JSONPath over the indexed attribute tree. Reject expressions the engine cannot evaluate with a bad-request response instead of returning partial results.
- `spatial` uses CQL2-JSON semantics. The index needs a geospatial type.
- `mediaSearch` is optional. Declare in the service description whether it is supported.

**Ranking.** Start with text relevance, then apply freshness, availability, provider quality signals and the buyer app's curation rules, in that order. Keep the final score explainable in the admin panel, so staff can answer why a result ranked where it did.

**Curation.** Curation is the buyer app's own editorial control over what its shoppers see. It never changes a seller's catalogue. It filters and orders what the DS returns.

| Control | Effect | Example |
| --- | --- | --- |
| Allow list | Only listed providers or categories appear | A partner app limited to member businesses |
| Deny list | Hidden from results | A provider under investigation |
| Collection | A named set of offers shown on a page | Back-to-school |
| Boost or demote | Adjusts rank within a query | Promote in-stock bestsellers during a campaign |
| Banner and layout | Home page and category page content | Campaign banners |
| Regulatory gate | Hides items that need a licence the buyer app does not support | Prescription items |

**Two rules for curation.**

- Record every curation change with who made it and when. A deny rule that hides a seller is a business decision that a seller may later dispute.
- Do not let a boost depend on the finder fee without disclosing it to the shopper. The spec has the seller pay `buyerFinderFee` to the buyer app, so ranking on it creates a conflict of interest. This document recommends a visible label for any paid placement.

**Decision for the team: shared or own DS.** The spec allows an independent DS offered as SaaS. A small buyer app can consume one and skip the crawler. The cost is that the buyer app cannot apply its own index, ranking or freshness rules. Build the crawler and index when the buyer app needs its own ranking, its own allow list or sub-minute freshness.

## Order lifecycle, payments, finder fee and reconciliation

**Order flow.** Discovery ends with a catalogue in hand. The transaction starts at `/select`, not at discovery.

1. `/select` with chosen offers. The reply, `/on_select`, returns the priced quote and, where it applies, the offer's `codEligibilityForBuyer`.
2. `/init` with billing and fulfilment details. `/on_init` returns the draft contract and payment terms for the shopper to accept.
3. `/confirm`. For a prepaid offer the buyer app has already collected payment. `/on_confirm` returns the contract.
4. Performance. The seller sends `/on_status` and `/on_update` as the order moves. The buyer app polls with `/status` and `/track` and also accepts unsolicited callbacks.
5. Post-order. `/cancel`, `/update`, `/support`, `/rate`, then `/reconcile`.

Hold one order record per `transactionId`. Store each request and callback in a message log. An order screen should show the log's latest state and never infer state from an unmatched callback.

**Payments the buyer app handles.**

| Case | Who collects | Buyer app does |
| --- | --- | --- |
| Prepaid | Buyer app (`collectedBy` BAP in the marketplace-listed pattern) | Collects before `/confirm`; records the collection; refunds through the `refund` object on cancel or return |
| Cash on delivery | Courier, not the buyer app | Shows the COD terms from the offer; does not collect; reconciles against the courier's remittance |
| Refund | Whoever collected | Sends `/cancel` or `/update`; records the refund; checks it against the seller's `/on_cancel` settlements |

**Finder fee.** The offer carries `buyerFinderFee` with a `feeType` of PERCENT or AMOUNT, applied to ITEM\_TOTAL or ORDER\_TOTAL. The seller pays it to the buyer app out of the seller's payout. At reconciliation it appears as `commission.value`. The buyer app earns it after the settlement agrees, not at order time. On a cash-on-delivery order the seller app still funds it, even though the buyer app never holds the cash.

**Reconciliation.** Either party sends `/reconcile` for a `settlementDate` with the contracts in that batch. The other answers `/on_reconcile` with AGREED, DISPUTED or PENDING. The sender then sends only the disputed and pending contracts again. Agreed settlements go on to SEAM.

The buyer app agrees totals, not the seller's internal split. Build these checks:

- Every contract in the batch matches an order the buyer app holds.
- Collected amount, refunds and commission add up to the settlement total.
- Dispute codes such as REFUND\_MISMATCH and COMMISSION\_MISMATCH map to a named cause in the admin panel.

**Support and grievance.** Grievances travel as `IONGrievance` events in `supportAttributes`: OPENED, ACKNOWLEDGED, STATUS\_CHANGED, RESOLUTION\_PROPOSED, RESOLUTION\_DECIDED, ACTION\_COMPLETED, RESOLVED, OBJECTION and CLOSED. Three rules apply on the buyer side. The party that decides is never the party that proposed. `originatingNpId` never changes once set. The shopper's case record must keep the full event trail, because a regulator or an SLA check will ask for it.

**Policies.** Cancellation, returns, warranty, dispute, grievance SLA and payment terms reach the buyer app as `ion://policy/<category>.<scope>.<terms>` references on the offer. The buyer app resolves each to plain language for the shopper before `/confirm`. If an IRI is unknown to the buyer app, it must show the raw reference and flag it in the admin panel, not hide the offer.

**Gaps the team needs to settle.**

- Cash-on-delivery finder fee: decided. The fee stays with the buyer app and the seller app funds it, including on a COD cash order. The spec does not say how the seller app pays it when the courier remits the cash, so the buyer app should invoice or settle it through \`/reconcile\`.
- Whether a buyer app may show a result in the same transaction when a DS answers `/discover` synchronously, as the reference app does, or must wait for `/on_discover`.

## Data, screens and variants

**Data.** One database per service. The reference app keeps one per application, so the buyer side owns its own. Core tables, by purpose:

| Table group | Holds |
| --- | --- |
| `transactions` | One row per order: status, counterpart `bppId`, owning shopper |
| `message_log` | Every request and callback with payload, ACK or NACK, latency |
| `catalogue_sources` | Provider nodes, index URL, last fetch, state, quarantine reason |
| `catalogue_documents` | Crawled files: hash, signature result, catalogue timestamp |
| `search_index` | Offer documents for query and ranking |
| `curation_rules` | Rule type, scope, effect, author, start and end dates, change history |
| `payments` | Collections, refunds, method, rail, status |
| `grievance_cases` | Case, event trail, deadlines, decider |
| `settlements` | Batches per `settlementDate`, totals, status, dispute codes |
| `staff_audit` | Who did what in the admin panel |

Keep the original catalogue file for each indexed document. A dispute about what a shopper saw is settled from the file and the index timestamp.

**Screens: customer app.**

| Screen | Content |
| --- | --- |
| Home | Collections, banners, categories from curation |
| Search results | Filters built from the category's attribute pack; ranking labels |
| Product page | Fields and badges chosen by category; seller, price, policies in plain language |
| Cart and checkout | Quote, billing, delivery, payment method, accepted terms |
| Order detail | Status timeline, tracking, cancel, return, support |
| Support | Case list and event trail |
| Account | Profile, addresses, order history |

**Screens: admin panel.**

| Screen | Content |
| --- | --- |
| Catalogue health | Sources, freshness, rejected files |
| Index inspector | One offer: indexed document, source file, rank explanation |
| Curation | Rules, collections, banners, change history |
| Orders | Search by transaction; message log; retry |
| Support desk | Cases, SLA clocks, decisions |
| Finance | Batches, finder fee, disputes, refunds |
| Sellers | Provider nodes listed, blocked or under review |
| Settings | Staff, roles, branding, enabled sectors |

**Variants.**

| Variant | What changes |
| --- | --- |
| Own-brand buyer app | Everything in this document, one operator |
| Partner-branded buyer app on a managed platform | The operator runs the crawler, index and order services once. Each partner gets its own branding, curation rules, allow list and fee terms. Each partner still needs a distinct buyer identity if it is a separate legal operator. |
| Agent-led buyer app (for example VIONA) | The customer app is replaced by a conversational agent that builds the Intent and calls the same discover and order services. Curation and the finder fee disclosure rules still apply. |
| Consumer of a shared DS | No crawler or index. The buyer app sends `/discover` to an external DS and keeps curation as a filter on the results it gets back. |

The managed variant raises a question this document cannot answer from the spec: whether one operator may hold several CN identities on one platform, and how settlement and finder fee are separated per partner. See the gap table.

## Guidance, spec gaps and sources

**Build order.**

1. ONIX adapter, identity, signing, and the order flow from `/select` to `/on_confirm` against a test seller.
2. Customer app on a consumed DS. This gives a working buyer app before any crawler exists.
3. Message log, order record, status and cancel.
4. Payment collection, refund, and `/reconcile`.
5. Grievance events and the support desk.
6. Crawler, index and own discover service.
7. Curation console and ranking rules.

**Rules to keep.**

- Sign every message with the key of the role that sends it. The CN and DS use different keys.
- Accept any `on_*` at any time and match it by `transactionId`.
- Show the shopper the policies in plain language before `/confirm`.
- Never rank on the finder fee without a visible label.
- Keep the source catalogue file for every indexed offer.

**Spec gaps and open decisions.**

| Topic | What is unclear | Effect on the buyer app |
| --- | --- | --- |
| Decentralised publishing (NFH-014) | The `ion-beckn.yaml` description refers to it, but its full text was not read for this document | Crawler source resolution, file format and change signals are described only at the level the spec description gives |
| `/discover` response mode | The spec describes an asynchronous `/on_discover`. The reference app calls a discover endpoint directly and reads the response | Decide which mode your DS supports |
| COD finder fee | The buyer app never holds COD cash, and the fee comes out of the seller's payout | Rule set by ION: the fee stays with the buyer app and the seller app funds it, even on COD. The payment mechanism for COD is not defined in the spec |
| Several buyer identities on one platform | Not covered in the files read | Affects the managed partner-branded variant |
| Ranking and crawl rules | The spec defines none | The sections above are recommendations |
| Policy IRIs not in the registry | New terms go through the contribution process; `CONTRIBUTING.md` was not read | Buyer app must handle unknown IRIs |
| Marketplace finder fee reconciliation | The marketplace-listed pattern leaves post-delivery finder fee reconciliation out of its transaction-time flow | Rely on the root reconcile pack, not on the pattern |

**Sources read.**

- `ion-beckn.yaml`: actors, `/discover`, `/on_discover`, `Intent`, `DiscoverAction`, `OnDiscoverAction`, Cataloging Service endpoints.
- `ion-additional.yaml`: `/reconcile` and `/on_reconcile`.
- ION Reference App technical artifact: services, request flows, data model.
- ION Entity Hierarchy Model: catalogue plane, CRC guidance for buyer apps, patterns.
- Marketplace listed and in-house patterns.
- Seller app reference architecture (this project), for structure and message handling.

**Not read.** The full NFH-014 text, DeDi index format, `CONTRIBUTING.md`, the policy registry files and the TradePerformanceStates pack.
