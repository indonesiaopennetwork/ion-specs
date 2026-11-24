# ION Seller App (SNP/BPP): Reference Architecture and Build Inventory

Draft · Nov 24, 2026

## Scope and baseline

This document lists every component, interface, data store and screen a seller app needs to operate on ION as an SNP (BPP). It does not decide what to reuse or rebuild; each team maps its existing system against this inventory.

Baseline: ION Specs Release 1, published 21 November 2026, Trade sector. Storefront is the implementation-ready profile. The other six Trade profiles are reference-level, and Logistics is preview only.

Terms. A seller app is a Provider Node (PN), also written SNP and formerly BPP. The wire fields `bppId` and `bppUri` keep their names. ONIX is the protocol adapter runtime that signs, verifies and routes. The adaptor is the seller's own code between ONIX and the business services. A buyer app is a Consumer Node (CN), formerly BAP, and a Discovery Service (DS) is a separate role with its own identity.

Scope is the full seller lifecycle: onboarding, catalogue publication, select / init / confirm, status, track, update, cancel, support, rating and reconciliation. A seller app that is also a marketplace has extra requirements, set out in the Marketplace section.

Where the published sources are silent or contradict each other, the item stays in the inventory and is tagged **\[Spec gap\]**. The last section lists each gap so it can be closed in the specs repository.

Out of scope: exact field-level payloads (use the Release 1 schema files), non-Trade sectors, the buyer side, and Subscription, which is not in Release 1.

## Architecture

&#91;embedded content: seller app architecture · 4 layers, 3 shared services\]

The seller owns everything inside the green boundary. ONIX handles signing, verification and routing; the adaptor translates between ION messages and business services; business services hold the commercial logic. ONIX does not implement stock, pricing or order rules.

## Component inventory

The seller app needs 33 components in five groups. Not every component is a protocol requirement. The table below sorts them into what the protocol requires, what depends on the seller's setup, and what is recommended. An existing system can supply, merge or replace any component, and a team that already runs a seller app integrates only what is missing.

| Tier | What it covers | Examples |
| --- | --- | --- |
| Required to transact | What a counterparty will test: identity and keys, signing and verification, the order messages, catalogue publication, policy references on offers, order state | ONIX runtime, adaptor, `/select` to `/confirm` handlers, `/status`, catalogue service |
| Required for the launch scope | Phase 2 functions this programme includes at launch | `/support`, `/rate`, reconcile handling |
| Depends on the seller | Needed only if the seller offers the feature | Cash on delivery, tracking, marketplace functions, made-to-order states |
| Recommended | Operations that a seller can run with existing tools | Back-office screens, analytics, notification tools |

This tiering is this document's own classification. The spec does not define a minimum component list, so the final tier of each component is a decision for ION. \[Spec gap\]

### Network participation

| ID | Component | What it must do | Gap |
| --- | --- | --- | --- |
| N1 | Participant identity record | Hold the ION Central profile: role SNP, sector, segment, profile code, business registration (NIB), verification status and expiry dates |  |
| N2 | Key management | Generate and store the Ed25519 keypair, register the public key, rotate keys, build the keyId (`namespace/registry/record\|ed25519`) |  |
| N3 | ONIX BPP | Sign outbound messages, verify inbound ones, validate schema, route to the adaptor. Needs its own Redis for routing cache in the reference deployment |  |
| N4 | ONIX catalogue route | Sign and send `/catalog/publish` to the Cataloging Service through ONIX; accept `/catalog/on_publish` |  |
| N5 | Policy registry client | Resolve `ion://policy/...` IRIs against the shared policy registry; refuse unknown or deprecated IRIs at publish (ION-A2010, ION-A2011) |  |

### Catalogue

| ID | Component | What it must do | Gap |
| --- | --- | --- | --- |
| C1 | Catalogue management | Hold providers, catalogues, resources and offers; drive attribute forms from the Catalogue Resource Category (CRC); require at least one image per resource (ION-A2001) |  |
| C2 | Provider profile publisher | Publish TradeProvider attributes: operating hours, closure dates, provider category, licences, verification status, average preparation time |  |
| C3 | Catalogue validator | Check every resource and offer against the Release 1 packs and error registry before publish |  |
| C4 | Catalogue publisher | Build catalogues per provider, send `/catalog/publish`, republish on price, stock or hours change, track freshness |  |
| C5 | Cataloging Service client | Receive `/catalog/on_publish` results per catalogue (accepted, rejected, partial) and act on rejections; query `/catalog/search` where useful |  |

Catalogue publication has two paths, and the sources do not agree on which is current. `ion-beckn.yaml` marks `/catalog/publish` and the other `/catalog/*` endpoints deprecated in favour of decentralised publishing, in which the seller hosts signed catalogue files and an index that a Discovery Service crawls. The ION decision recorded for this document is that `/catalog/publish` is the starting point and is not deprecated. A seller app should build the catalogue service so that the same catalogue can leave through either path: a `/catalog/publish` call, and a signed file with an index entry. Buyer apps that run their own crawler read the second. The gap table records the question for ION to close. \[Spec gap\]

### Protocol runtime (the adaptor)

| ID | Component | What it must do | Gap |
| --- | --- | --- | --- |
| A1 | Inbound gateway | Expose the action endpoints, authenticate through ONIX, return a signed ACK or a NACK with an error code |  |
| A2 | Action handlers | One handler per inbound action (Protocol surface); each maps to business services and decides the callback |  |
| A3 | Callback dispatcher and outbox | Persist the `on_*` message, send it through ONIX, record the ACK, retry failed deliveries at your discretion |  |
| A4 | Contract state manager | Hold the order and performance state; reject illegal transitions; push `on_status` on every state change |  |
| A5 | Message and transaction log | Store every request, callback, ACK/NACK, latency and error against `transaction_id` and `message_id` |  |
| A6 | Duplicate guard | Detect repeated requests and callbacks so they cause no second order, reservation or refund |  |
| A7 | Timeout and delay monitor | Detect expired messages, callbacks not sent, ACKs not received and orders stuck between states |  |
| A8 | Error mapper | Translate transport, schema and trade errors into NACKs or `error` callbacks | Yes |

### Business services

| ID | Component | What it must do | Gap |
| --- | --- | --- | --- |
| B1 | Pricing and quote engine | Price items, delivery and tax; enforce customisation groups (ION-A3001, A3002), variant matrix (A3007), voucher stacking (A3006), stock caps (A3003) and offer validity (A3004) |  |
| B2 | Inventory and reservation | Check availability on select, reserve on init or confirm, release on cancel or expiry |  |
| B3 | Order management | Create the order on confirm, accept or reject, prepare, keep internal and ION state aligned |  |
| B4 | Fulfilment and delivery | Assign rider or logistics partner, send ETA and vehicle details, issue and verify delivery OTP, capture proof of delivery |  |
| B5 | Payment handling | Record the payment mode and status per offer terms. On a prepaid offer, a `/confirm` means the buyer app has confirmed payment |  |
| B6 | Cancellation, return and refund | Apply the offer's cancellation and return policy; support preview, full, partial and seller-initiated cancellation; trigger refunds |  |
| B7 | Support case management | Receive `IONGrievance` events, run SLA timers, record resolution and remedy |  |
| B8 | Reconciliation and settlement ledger | Compute settlement figures for each contract falling due; answer `/reconcile`; start the exchange with the seller's figures when the seller is the initiating party; record agreement, differences and dispute codes; resend disputed items; track payout after agreement |  |
| B9 | Rating handler | Receive and store ratings, return `on_rate` |  |
| B10 | Tax and invoice records | Hold tax breakdown per order; produce tax invoices where the profile requires them |  |

### Operations

| ID | Component | What it must do | Gap |
| --- | --- | --- | --- |
| O1 | Seller admin application | Web UI with OIDC login, user-to-provider mapping and roles (section 8) |  |
| O2 | Observability | Structured logs and traces keyed by `transaction_id` and `message_id`; dashboards; alerting |  |
| O3 | Conformance test harness | Repeatable happy-path and negative-path tests for Devlabs and counterparty testing |  |
| O4 | Configuration management | Per-environment `bppUri`, ONIX config, Registry, catalogue and discover URLs, key references |  |
| O5 | Notification service | Alert staff on failed callbacks, SLA breaches, stock issues and expiring licences |  |

## Protocol surface

The seller exposes the action endpoints below at its `bppUri` and sends the matching callbacks to the buyer's `bapUri`. Each callback carries exactly one of `message` (success) or `error` (processing failure).

| Action | Seller receives | Seller sends back | Handler must |
| --- | --- | --- | --- |
| `/catalog/publish` | No: the seller sends it first, to the Cataloging Service | Receives `/catalog/on_publish` | Submit catalogues per provider; read the per-catalogue result; fix rejections. Buyer apps can find the seller only after a catalogue is accepted |
| `/catalog/search` | No: seller sends it (optional) | Receives the result | Query indexed catalogues |
| `/select` | Yes | `on_select` | Check availability, price and serviceability; return the quote (items, delivery, total) |
| `/init` | Yes | `on_init` | Validate buyer and delivery details; return order terms and accepted payment options |
| `/confirm` | Yes | `on_confirm` | Create the contract, set performance to accepted, return SLA; issue a delivery OTP where the item requires it |
| `/status` | Yes | `on_status` | Return current order and performance state |
| `/track` | Yes (optional) | `on_track` | Return the live tracking handle |
| `/update` | Yes | `on_update` | Apply buyer changes |
| `/cancel` | Yes | `on_cancel` | Preview fees, apply full or partial cancellation, or reject under the offer policy |
| `/support` | Yes | `on_support` | Accept the grievance event, respond within the SLA, state the remedy |
| `/rate` | Yes | `on_rate` | Store the rating, acknowledge |
| `/reconcile` | Yes | `on_reconcile` | Answer settlement figures for contracts due on a date: agree, or disagree with your own figures, differences and a dispute code. Disputed items come back in a new request |
| none (unsolicited) | No | `on_status` | Push on every state change, such as out for delivery (rider, vehicle, ETA) and delivered (proof URL) |
| none (unsolicited) | No | `on_update` | Tell the buyer app of a seller-side change to the order |
| none (unsolicited) | No | `on_cancel` | Tell the buyer app the seller has cancelled |
| none (unsolicited) | No | `on_track` | Push tracking changes |
| none (unsolicited) | No | `on_reconcile` | Send settlement figures without waiting for a request |
| none (unsolicited) | No | any other `on_*` | Whenever the seller needs to tell the buyer app of a change. The seller generates a fresh `messageId` |

A transaction starts with the seller's catalogue publish. Each order then begins with a buyer `/select`. Solicited callbacks answer a buyer request. Unsolicited callbacks are sent by the seller when something changes, with no request to answer.

Unsolicited callbacks are signed with the plain three-line signing string. Endpoint names were checked against `ion-beckn.yaml` and `ion-additional.yaml`; field-level payloads were not.

## Message handling rules

A signed ACK means the request arrived and authenticated. It never means the order, price or stock is confirmed. The business result always comes in a separate callback.

### Signing outbound

- Catalogue requests and unsolicited callbacks (`on_status`, `on_update`, `on_cancel`, `on_track`, `on_reconcile`): `Authorization: Signature` header, algorithm `ed25519`, signed headers `(created) (expires) digest`. The digest is BLAKE2b-512 over the exact body bytes, base64-encoded. Recommended lifetime is 600 seconds.
- Solicited callbacks: add a fourth signing line, `request-signature`, holding the signature copied from the buyer's original request. Signed headers become `(created) (expires) digest request-signature`.
- Every 200 ACK is itself signed, in a `Signature` response header.
- Sign the bytes you actually send. Re-serialising the JSON after signing breaks verification.

### Verifying inbound, before reading the body

1. Parse `keyId`, `created`, `expires` and `signature` from `Authorization`.
2. If `expires` has passed, NACK with ION-1001.
3. Resolve `keyId` against the Registry. If unknown, ION-1005.
4. Rebuild the signing string from the raw body and check the Ed25519 signature. On failure, HTTP 401 with ION-1002.

### Error handling

| Family | Meaning | Examples |
| --- | --- | --- |
| ION-1001 to ION-1005 | Signature and transport (transport guide) | Expired, failed, missing, malformed, unknown key |
| CTX\_, AUT\_, SCH\_, NET\_, BIZ\_ | Beckn error codes in `ion-beckn.yaml` | `CTX_TTL_EXPIRED`, `CTX_MESSAGE_ID_DUPLICATE`, `AUT_REPLAY_DETECTED`, `NET_ACK_TIMEOUT`, `BIZ_OFFER_NOT_FOUND` |
| ION-8xxx | Schema validation | Rejected at the boundary |
| ION-A2xxx, A3xxx, A8xxx | Trade (10 codes, below) | Catalogue, transaction and schema errors |
| ION-A4xxx to A6xxx | Fulfilment, post-order, settlement | Ranges reserved, no codes published yet |

The ten Trade codes in Release 1:

| Code | HTTP | Meaning | Raised on |
| --- | --- | --- | --- |
| ION-A2001 | 400 | Resource has no image | Catalogue publish |
| ION-A2010 | 400 | Policy IRI not in the registry | Catalogue publish |
| ION-A2011 | 410 | Policy IRI deprecated | Catalogue publish |
| ION-A3001 | 400 | Mandatory customisation group not chosen | `/select` |
| ION-A3002 | 400 | Customisation option ID does not exist | `/select` |
| ION-A3003 | 409 | Offer stock cap reached | `/select` |
| ION-A3004 | 410 | Live session ended | `/select`, `/init`, `/confirm` |
| ION-A3006 | 409 | Vouchers cannot be combined | `/select`, `/init` |
| ION-A3007 | 400 | Variant combination not allowed | `/select` |
| ION-A8001 | 400 | Food classification not supported | Discovery payloads |

- A callback carrying `error` ends the callback sequence for that `messageId`. A retry needs a new request with a new `messageId`. The transaction itself stays open.
- Where the transport guide and the contract name different codes for the same failure, use the contract's code. The guidance section below covers what the specs leave to the seller.

## Data the seller app must hold

The app needs 17 data stores. The ION reference app's seller backend has tables only for providers, catalogues, resources, offers, users and the message log, so the rest are new in any implementation built from it.

| Store | Holds | Linked by |
| --- | --- | --- |
| Participant profile | Organisation, role, sector, segment, profile code, registration numbers, verification status, expiry dates | participant ID |
| Keys and endpoints | Key references (not private keys in plain text), keyId, `bppUri`, per-environment URLs | participant ID |
| Providers | One per seller identity; operating hours, closures, licences, preparation time | provider ID |
| Catalogues, resources, offers | Products with CRC attributes, images, offers with price, validity, stock cap, policy IRIs | resource ID, offer ID |
| Publication runs | Each publish: catalogues sent, result per catalogue, errors, timestamp | run ID |
| Inventory and reservations | Stock by item, reserved quantity per transaction, release time | resource ID, transaction ID |
| Transactions and contracts | Quote, order terms, commitments, contract status, performance status, SLA | transaction ID, order ID |
| State history | Every state change with time, cause and triggering message | order ID |
| Message log | Every inbound and outbound message, payload, ACK/NACK, latency, error code | transaction ID, message ID |
| Outbox | Callbacks waiting to send, attempts, last result | message ID |
| Duplicate guard | Message IDs and request signatures already processed, with the response sent | message ID |
| Fulfilment | Rider or partner, vehicle, ETA, OTP state, proof of delivery | order ID |
| Payments and refunds | Payment mode, status, amounts, refund records | order ID |
| Cancellations and returns | Requests, policy applied, fees, decision, refund link | order ID |
| Support cases | Grievance event, category, severity, SLA clocks, resolution, remedy | order ID, case ID |
| Settlement positions | Base amount, fee, withholding, net, method, agreement status, payout reference | order ID, settlement ID |
| Ratings | Ratings received | order ID |

Seller-internal fields stay in the seller's own namespace and never travel on the network.

Add users, roles, a user-to-provider mapping and an audit log for the admin application.

## Order lifecycle and state handling

The seller moves each order through the stages below and tells the buyer app at each step. State names come from the Release 1 `TradePerformanceStates` pack, which was not read for this draft; the names shown are those that appear in the published journey.

| Stage | Seller does | Message | Internal change |
| --- | --- | --- | --- |
| Publish | Send each provider's catalogue to the Cataloging Service and read the result | `/catalog/publish`, receives `/catalog/on_publish` | Catalogue live or rejected; orders can follow |
| Quote | Check stock and serviceability, price the selection | `on_select` | None; nothing reserved yet |
| Terms | Validate address and payment choice, fix terms | `on_init` | Reservation per seller policy |
| Commit | Accept the order, set the SLA, create the OTP if required | `on_confirm` | Contract active, performance accepted |
| Fulfil | Prepare, hand to rider or partner | `on_status` | Performance moves forward |
| Deliver | Verify OTP where required, capture proof | `on_status` (out for delivery, then delivered) | Performance delivered, stock committed |
| Change or cancel | Apply the offer's policy, refund if paid; or tell the buyer app of a seller-side change | `on_update`, `on_cancel`, `on_status` | Release stock, refund record |
| Support | Respond inside the SLA, deliver the remedy (for example, reship) | `on_support` | Case resolved |
| Reconcile | Send settlement figures for contracts due, or answer the buyer app's figures; agree or contest each settlement | `/reconcile` (either party), `on_reconcile` | Settlement agreed, then committed |
| Rate | Store the rating | `on_rate` | Rating recorded |

Reconciliation, step by step. It runs between the two participants of an order, the buyer app and the seller app, and uses only `/reconcile` and `/on_reconcile`.

1. Either participant sends `/reconcile` for a `settlementDate`, with the contracts whose settlements fall due that day and its own figures.
2. The other participant answers `/on_reconcile` and sets `accord` on each settlement. `accord: true` means both agree on the buyer app's `commission` and the seller's `netPayable`. `accord: false` carries its own figures, the difference per component and a dispute code.
3. Agreement is per settlement. An agreed settlement stays agreed whatever happens to the others in the batch. `reconciliationStatus` only summarises the answer: AGREED when every settlement is agreed, DISPUTED when any is disputed, otherwise PENDING.
4. The sender sends only the disputed and pending settlements again, in a new `/reconcile` with the same `transactionId` and a new `messageId`.
5. `accord: true` is not a payout instruction. SEAM verifies funds, accounts and double payment, then pays `netPayable` to the seller and `commission` to the buyer app. Payout status reaches the participants by the payment provider's webhook, which the spec leaves out of scope.

Source: `ion-additional.yaml`. A seller app can start the exchange or answer it, so build both directions.

Branches the app must handle:

- Price or stock changes between select and confirm.
- Buyer abandons after select or init; reservations expire and release.
- Seller cannot fulfil a confirmed order and cancels.
- A repeated `/confirm` or callback must not create a second order.
- Payment or payout fails after the order is accepted.
- Delivery proof is disputed, and a support case follows.
- Settlement positions differ; do not mark them agreed.

Flows other than Storefront add states, such as `PREPARING` for made-to-order. Support them only when the seller adopts that profile.

## Screen inventory

This section lists 41 screens across eight areas. ION does not mandate screens. The list shows what the components above need so staff can run the business. A seller can merge screens, reuse existing back-office tools, or leave out screens for features it does not offer. The reference app's seller dashboard covers only overview, catalogue, inventory and orders.

### A. Access and onboarding

| # | Screen | Contents |
| --- | --- | --- |
| A1 | Login | OIDC sign-in, session, map the signed-in user to a seller |
| A2 | Seller profile and registration | Business details, NIB, licences, verification status, expiry warnings |
| A3 | Business classification | Sector, segment, profile, permitted CRCs |
| A4 | Hours, closures and preparation time | Operating hours, closure dates, average preparation time |
| A5 | Network identity | Participant ID, endpoints, key status and rotation, Registry registration state |
| A6 | Conformance and go-live status | Devlabs test results, approvals, open items |

### B. Catalogue

| # | Screen | Contents |
| --- | --- | --- |
| B1 | Catalogue overview | Counts, validation state, last publish, freshness |
| B2 | Resource list | Search and filter by CRC, status and validation result |
| B3 | Resource editor | Attribute forms driven by CRC, images, regulated fields such as BPOM registration, halal status, prescription flag |
| B4 | Variants and customisation | Customisation groups, options, required selections, variant matrix |
| B5 | Offer editor | Price, validity period, stock cap, payment terms, voucher rules |
| B6 | Policy picker | Choose returns, cancellation, warranty, dispute, grievance SLA and payment-terms policy IRIs; warn on deprecated ones |
| B7 | Validate and publish | Errors by resource, fix links, publish action |
| B8 | Publication history | Each run, index version, outcome, failed publishes |
| B9 | Bulk import | Upload product data, map columns, review errors |

### C. Orders and fulfilment

| # | Screen | Contents |
| --- | --- | --- |
| C1 | Orders dashboard | Active, pending and today's orders; delayed callbacks; SLA risks |
| C2 | Order list | Filter by ION state, buyer app, date; flag orders waiting on a callback |
| C3 | Order detail and actions | Items, quote breakdown, delivery, payment, state timeline, message trail; accept, reject, prepare |
| C4 | Fulfilment board | Assign rider or partner, set ETA, push status |
| C5 | Delivery verification | OTP entry, proof-of-delivery capture |
| C6 | Cancellation requests | Buyer requests, fee preview, approve or reject, start a seller cancellation |
| C7 | Returns and refunds | Return requests, pickup, inspection, refund status |

### D. Support

| # | Screen | Contents |
| --- | --- | --- |
| D1 | Support inbox | Open cases, category, severity, SLA clocks |
| D2 | Case detail | Grievance event, order link, history, evidence |
| D3 | Resolve case | Choose and record the remedy, such as reship or refund, and send the response |

### E. Finance

| # | Screen | Contents |
| --- | --- | --- |
| E1 | Settlement requests | Positions awaiting your answer |
| E2 | Settlement detail | Base amount, fee, withholding, net, method, status; agree or return your figures |
| E3 | Settlement ledger | Agreed and committed settlements, payout references |
| E4 | Payments and refunds | Payment status per order, refund log |
| E5 | Tax and invoices | Tax breakdown, invoice download |

### F. Ratings

| # | Screen | Contents |
| --- | --- | --- |
| F1 | Ratings | Ratings received, by order |

### G. Operations

| # | Screen | Contents |
| --- | --- | --- |
| G1 | Message explorer | Search by `transaction_id` or `message_id`; ACK/NACK, latency, masked payload |
| G2 | Transaction trace | One order's full message sequence with timings |
| G3 | Failed and delayed callbacks | Queue with retry and manual resend |
| G4 | Error reference | ION error codes with the fix for each |
| G5 | Health and alerts | Failure rates, latency, key expiry, publish freshness |
| G6 | Notification settings | Who is alerted for what |
| G7 | Audit log | Who changed what, when |

### H. Administration

| # | Screen | Contents |
| --- | --- | --- |
| H1 | Users and roles | Invite, assign roles, deactivate |
| H2 | Stores and providers | Map users to providers; needed if the seller runs several stores |
| H3 | Environment settings | Endpoints and configuration references; never display secrets |

## Marketplace seller app

If the seller app is a marketplace, it stays one network participant with one set of keys, but serves many sellers and brands. That adds 12 components, 10 data stores and 14 screens, and it changes how catalogue, configuration, orders and money are organised.

### Which marketplace model

| Model | Who is the merchant | Release 1 coverage |
| --- | --- | --- |
| Marketplace as merchant (first-party or consignment) | The marketplace holds stock, invoices centrally and fulfils from its own centres | `marketplace-inhouse`, reference-level. The marketplace is one provider |
| Marketplace hosting independent sellers | Each seller is its own provider under the marketplace's seller app and keeps its own fulfilment | No pattern **\[Spec gap\]**. Storefront with one provider ID per seller is the working assumption |

`marketplace-listed` is the opposite case: there the marketplace is the buyer app routing to independent seller apps. It is not covered here.

The in-house pattern fixes some values. The provider carries an invoicing model of CENTRAL, an invoicing entity ID, an operational status and a NIB. Fulfilment passes through packed, dispatched and delivered, with a tracking number at dispatch. Cancellation, returns, warranty, dispute, grievance SLA and payment terms each use one named policy IRI. The pattern states that brand consignment and payout are internal and not represented on the wire.

### What changes

| Area | Single seller | Marketplace |
| --- | --- | --- |
| Identity | One organisation, one provider | One participant; one provider per hosted seller, with its own NIB, licences, verification and operational status |
| Catalogue | One catalogue | One catalogue per provider, built and published separately, republished when a seller's status or stock changes |
| Order routing | Only one provider | The provider ID in `select`, `init` and `confirm` decides whose stock, price and rules apply. Release 1 patterns name one provider per contract, so expect a multi-seller cart to arrive as separate transactions |
| Configuration | One set of settings | A cascade from marketplace down to offer (next section) |
| Fulfilment | Own locations | Fulfilment location per seller or warehouse, reported on the order |
| Policies | One set of policy IRIs | Per seller, brand or category, always from the ratified registry |
| Invoicing and tax | Own | Central or per seller; **\[Spec gap\]** for hosted sellers |
| Money | Own ledger | Commission, platform fee, seller shares, holdbacks, payouts, brand consignment. `/reconcile` stays between marketplace and buyer app. The buyer app agrees the totals only. The split of `netPayable` among sellers can be stated in `settlementAccounts` (holder role PROVIDER, with `allocationFor` BPP and `allocatedAmount`) so SEAM can pay each account; the contracts behind it stay internal |
| Support | Own team | A case is routed to the right seller, timed against that seller's SLA, and answered to the buyer app by the marketplace |
| Compliance | One licence set | A seller's expired licence suspends its offers and updates its provider status |
| Access | Staff only | Marketplace staff, seller users and brand users, each limited to their own data |

### Seller and brand configuration

Every setting resolves from the most specific level that defines it: offer, then resource, then brand, then seller, then category (CRC), then marketplace default. Decision for this build: one provider per brand. A brand is a provider entry under the marketplace's BPP, so brand-level values publish as provider attributes. A seller with several brands has several providers; a brand sold by more than one seller can also be modelled as several providers under one brand, which the design allows but the first build does not need. The other levels are the marketplace's own data, resolved before publishing, and only provider, resource and offer attributes travel on the wire. Record which level supplied each value.

| Setting | Marketplace | Category | Seller | Brand | Resource or offer |
| --- | --- | --- | --- | --- | --- |
| Operating hours, closures | Default |  | Yes |  |  |
| Preparation time | Default | Yes | Yes |  | Yes |
| Fulfilment location, delivery options | Default |  | Yes |  | Yes |
| Returns, cancellation, warranty policy IRIs | Default | Yes | Yes | Yes | Yes |
| Grievance SLA, payment-terms policy IRIs | Default | Yes | Yes |  |  |
| Price rules, stock caps, vouchers |  |  | Yes | Yes | Yes |
| Commission and platform fee | Default | Yes | Yes | Yes |  |
| Invoicing model and tax | Default |  | Yes |  |  |
| Required regulated fields (for example BPOM, halal) |  | Yes |  |  | Yes |
| Support contact and SLA | Default |  | Yes |  |  |

A lower level may only choose values the level above allows, such as a policy IRI in the ratified registry.

### Adapting Storefront for hosted sellers

Release 1 has no pattern for one seller app hosting independent sellers. Read the Storefront pattern with these changes:

1. Keep every Storefront action, callback and performance state as is.
2. Give each brand its own provider entry, with a stable provider ID that is never reused. A seller with several brands has several providers. Brand-level details sit in the same provider fields.
3. Publish one catalogue per provider.
4. On `/select`, `/init` and `/confirm`, read the provider ID in the participants list. Load that seller's resolved settings, stock and fulfilment location.
5. Build the quote from that seller's values. Show any marketplace fee as its own line in the breakup.
6. Report the seller's fulfilling location and move performance states per seller order.
7. Send every callback under the marketplace's identity and keys, with the seller's provider details inside the message.
8. State the split of the seller's share in `settlementAccounts` (PROVIDER accounts with `allocatedAmount`). Keep commission agreements and payout contracts off the wire.

### Seller shares and payout

- Record each provider's invoicing model (marketplace invoices centrally, or the seller invoices), the invoicing entity ID and the tax treatment.
- `/reconcile` runs between the marketplace and the buyer app for the contracts due on a date. The buyer app agrees the totals, not the split. Release money to sellers after the settlement is agreed.
- For each order, keep a ledger line: amount collected, less commission, platform fee, withholding and holdback, equals the seller's share. Link every line to the contract and the reconcile exchange.
- Pay a seller after the reconcile for that contract is agreed and any return window or holdback has passed. Consignment brands settle under their consignment terms, internally.
- If a contract is disputed in reconcile, hold that seller's share until the resend is agreed.
- Give each seller a statement per period listing orders, deductions and payout references.

### Extra components

| ID | Component | What it must do |
| --- | --- | --- |
| M1 | Seller registry and onboarding | Invite sellers, verify NIB and licences, set status, assign permitted categories |
| M2 | Brand registry | Hold brands, and which sellers may sell which brand, with proof |
| M3 | Configuration cascade service | Store overrides at each level, resolve the effective value, record its source |
| M4 | Provider catalogue builder | Build and publish one catalogue per provider from resolved settings |
| M5 | Catalogue approval queue | Review seller listings for completeness before publish |
| M6 | Order router | Read the provider ID, load that seller's rules, create a seller-scoped order, notify the seller |
| M7 | Seller stock and locations | Stock and fulfilment locations per seller or warehouse |
| M8 | Commission and fee engine | Compute commission and platform fee; disclose fees in the quote where required |
| M9 | Seller ledger and payout | Seller share per order, holdbacks, payout schedule, statements, consignment settlement |
| M10 | Seller compliance monitor | Watch licence and verification expiry; suspend offers; update provider status; republish |
| M11 | Multi-tenant access control | Scope every query and screen by seller and brand |
| M12 | Seller support routing | Assign cases to sellers, run per-seller SLA clocks, escalate |

### Extra data

Sellers, brands, seller-brand authorisations, configuration overrides by level, locations, commission rules, seller ledger entries, payouts and statements, catalogue review records, and seller and brand users with roles.

### Extra screens

| # | Screen | Contents |
| --- | --- | --- |
| MA1 | Seller list and onboarding queue | Applications, verification state, status |
| MA2 | Seller detail | Profile, licences, status, permitted categories, locations |
| MA3 | Brands and authorisations | Brands, which sellers may sell them, supporting documents |
| MA4 | Marketplace defaults | Default settings and allowed values |
| MA5 | Overrides and effective values | Set overrides by category, seller, brand, resource or offer; see the resulting value and which level supplied it |
| MA6 | Catalogue approval queue | Listings awaiting review, errors, approve or reject |
| MA7 | Publish status by seller | Last publish, result per catalogue, failures |
| MA8 | Commission and fee rules | Rates by level, effective dates |
| MA9 | Seller ledger and payouts | Order shares, holdbacks, payout runs |
| MA10 | Seller statements | Per-seller statement for a period, downloadable |
| MA11 | Suspensions and compliance alerts | Expiring licences, suspended sellers and offers |
| MA12 | Seller support performance | Cases and SLA results by seller |
| MA13 | Locations and fulfilment centres | Locations per seller, linked to orders |
| MA14 | Seller statement view (seller portal) | The seller's own commission, payouts and statements |

Sellers use a portal made from the catalogue (B), orders (C), support (D) and ratings (F) screens above, plus MA14, each limited to the signed-in seller's providers with a brand filter.

## Extension attributes

The seller app may add its own fields to the provider, resource and offer attribute bags. The ION Schema Design Guide calls these participant extension fields. The rules are fixed: the field uses the participant's own prefix (for example `map:`) and never `ion:` or `beckn:`. The prefix is declared by adding an entry to the bag's `@context`. A bag carries at most 10 such fields. ONIX does not validate them. Other participants see them only if they resolve the prefix IRI. A field that more than one participant needs belongs in an ION schema pack, not in a participant extension.

The resource pack also has `additionalAttributes`: up to 30 name and value pairs, with an optional unit, for facts a shopper should read. Use it for display facts. Use a prefixed field for facts the seller's own systems read. Price, policy, settlement, fulfilment, tax and regulatory facts stay in ION fields.

The layers and services in this document do not change. The catalogue service gains four duties:

- **Extension registry.** The namespace, each field, its type, its bag, and which seller system reads it.
- **Pre-publish check.** ONIX will not check these fields, so the seller app does: correct prefix, no more than 10 per bag, no clash with an ION field name, no price, policy or settlement value.
- **Namespace hosting.** A stable URL the seller owns, serving the context document that defines each field.
- **Per-field visibility.** Each field is marked as published or internal. Internal fields are removed before `/catalog/publish`.

Two things to confirm with the ONIX team: that a list-valued `@context` is accepted in a published bag, and that the protected ION contexts do not block a second context entry that defines only new terms.

### Changes found when the journeys were checked against the Release 1 packs

- **Support service.** `/support` and `/on_support` carry `IONGrievance` events in `supportAttributes`. Each message is one event: OPENED, RESOLUTION\_PROPOSED, RESOLUTION\_DECIDED, ACTION\_COMPLETED, RESOLVED and the others. The service keeps a case state per `grievanceId` and must not change `originatingNpId`. A proposal needs a decision from the other side, never from the proposer.
- **Order service.** A partial cancellation names the lines in `cancellation.commitmentIds`. The reason is a code. The pack has no field for who started the cancellation.
- **Payment and settlement.** Cash on delivery uses the `CashOnDelivery` method detail. Reconcile carries `collections` and `settlementObligations` (purpose `COD_REMITTANCE`) for cash held by the courier.
- **Offer.** Cash on delivery is declared through `paymentMethodEligibility`, with `codEligibilityForBuyer` returned in `/on_select`.
- **Participant role.** The buyer's role is `BUYER`.

The attribute dictionary is a separate document. It lists every attribute used in the Fashion and Electronics journeys, with its meaning, allowed values and the pack it comes from, and it lists the fields used that the packs read do not define.

## Policy requests

An offer does not carry a rule. It points to a registered policy with `policyRef`, and the policy holds the terms for cancellation, returns, refunds, warranty, grievance response times and penalties. The registry (`policies/registry.json` in the `ion-specs` repository) is governed by ION, outside the release cycle. A seller app cannot create a policy IRI and use it. When it needs a rule the registry does not have, it asks for one and waits until it is registered.

The seller app needs a **policy catalogue** and a **policy request workflow**:

- **Policy catalogue.** Which registered policy IRI each brand, resource and offer uses, for every policy type. The order, returns and support services read it. It is the single place where a rule is chosen.
- **Search before asking.** The catalogue service checks the registry for the category and scope. If a term fits, no request is made.
- **Request workflow.** A request has an owner at the seller, a draft policy document that copies the format of an existing file under `policies/<category>/v1/`, a rationale, and a status: DRAFT, SUBMITTED, IN REVIEW, REGISTERED or REJECTED. The seller app's policy owner submits it through the ION contribution process (`CONTRIBUTING.md` in `ion-specs`: discussion, then a pull request). The technology provider can prepare the files.
- **Publish gate.** The catalogue service refuses to publish an offer whose `policyRef` is not in the registry. Until a request is registered, the offer keeps the nearest existing policy.
- **Interim controls.** `customTermsAddendum` on the offer (free text up to 1000 characters) adds to the policy IRIs and cannot override them. A per-offer `policies.penalty.policyRef` can be used and cannot be weaker than the seller-tier minimum.
- **Enforcement.** The policy sets the rule and one service applies it each time. Cancellation: the order service checks the window and allowed reasons on `/cancel`. Return and refund: the returns service checks window and evidence on a return `/update` and sets the refund in the settlement. Grievance SLA: the support service starts a timer on each OPENED event and escalates before it runs out. Warranty: the support service checks the period and records it as the `verification`. Penalty: the reconciliation service carries it as a PENALTY line in the settlement `breakup`.
- **Registry sync.** The seller app reads `https://schema.ion.id/policies/registry.json` on a schedule, so it learns when a requested policy is registered or when an existing one changes.

The submission format, review criteria and timeline were not read. This section describes the shape of the process. The Fashion and Electronics journeys (Step 5) show a worked request in each.

## Guidance where the specs are silent

These are recommended practices for choices the specs leave to the seller. They are guidance, not requirements.

### Duplicates and replays

- Key each inbound message on sender ID, action and `messageId`. Store the key with the response you sent, for at least the message `ttl` plus a margin.
- Same key, same body: return the same ACK and run no business logic. Same key, different body: NACK with `CTX_MESSAGE_ID_DUPLICATE`.
- Make business actions safe on their own. A second `/confirm` for the same `transactionId` returns the existing contract. A repeated cancel or refund does nothing new.

### Time limits

- Every message carries `context.timestamp` and a `context.ttl` (an ISO 8601 duration). Set `ttl` on everything you send. Reject an inbound message past its window with `CTX_TTL_EXPIRED`.
- The signature has its own lifetime (`expires`); the transport guide recommends 600 seconds. It is separate from `ttl`.
- The specs give no time for sending a callback. Set your own target for each action, and alert when one is missed.

### Callback delivery retries

- Retry is at the participant's discretion. A reasonable approach: retry on timeouts and 5xx or rate-limit responses with exponential backoff and jitter, and honour `Retry-After`.
- Do not retry a 400 or 401 until the cause is fixed.
- On a delivery retry, keep the same `messageId` and body. Sign again with fresh `created` and `expires`.
- After your limit, keep the callback in the outbox, raise an alert and allow a manual resend.
- This is separate from a business retry: after an `error` callback, the buyer app must send a new request with a new `messageId`.

### Payment status

- On a prepaid offer, a `/confirm` means the buyer app has collected and confirmed payment. It carries a draft settlement entry with the payment proof or reference.
- Record that reference, create the order, and return the settlement status in `on_confirm`. Do not wait for a separate payment message.
- On cash-on-delivery variants, `/confirm` commits the order and collection happens at delivery. Record it then.

### Policy enforcement

- At publish, check every policy IRI against the registry and refuse unknown or deprecated ones. Cache the registry and note its version.
- At runtime, when a cancel, return or support request arrives, resolve the offer's policy reference and apply its rule in the handler, because the rule depends on order state.
- Do not assume ONIX enforces policy. Confirm what your deployment loads.
- Log each decision with the IRI and registry version. Test one allowed and one rejected case per policy.

### Verifying solicited callbacks

- A reply to your request is signed with a fourth line, `request-signature`, holding the signature from your original request.
- Rebuild that line from the signature you stored with the request, matched by `messageId`. The callback's `Authorization` header does not carry it. Store the signature of every request you send in the message log.

### Unsolicited callbacks

- Any `on_*` may be sent without a request. Generate a fresh `messageId`, sign with the three-line string, and let the buyer app correlate by `transactionId`.

## Spec gaps and inconsistencies

Nine items in the published sources need a decision or a correction in the specs repository.

| # | Gap | What the sources say | Needed in the specs |
| --- | --- | --- | --- |
| 1 | Callback time | `ttl` is defined in the context. No expected time to send a callback per action | Target times per action, if wanted |
| 2 | Error code systems | Transport guide uses ION-1001 to ION-1005. The contract's error enum uses CTX\_, AUT\_, SCH\_, NET\_ and BIZ\_ names | One list, or a mapping between them |
| 3 | Catalogue publication model | `ion-beckn.yaml` marks `/catalog/publish` and every `/catalog/*` endpoint deprecated, in favour of decentralised publishing. This document treats `/catalog/publish` as the starting point and not deprecated. The reference app publishes signed files with an index | Remove the deprecation, or state which path is current; align the reference app |
| 4 | Transport guide vs contracts | Guide lists the `/raise` family and `/catalog/publish` as seller-exposed endpoints, and omits `/status` | Remove `/raise`; show `/catalog/publish` as a seller call; add `/status` |
| 5 | Trade error codes | 10 codes exist (A2xxx, A3xxx, A8xxx); A4xxx, A5xxx, A6xxx are reserved but empty; A3005 is skipped | Codes for fulfilment, cancel, refund and settlement failures |
| 6 | Callback verification sample | Sample code looks for `request-signature` in the `Authorization` header, where it is not | Corrected sample and test vector |
| 7 | Hosted-seller marketplace pattern | Release 1 has `marketplace-inhouse` and `marketplace-listed` only. Neither covers one seller app hosting independent sellers, with brand carried in the provider fields | A pattern for a seller app hosting independent sellers |
| 8 | Invoicing for hosted sellers | `marketplace-inhouse` fixes the invoicing model to CENTRAL. Both marketplace flows exclude reconciliation | Allowed invoicing models for hosted sellers. Release 1 has `CENTRAL` and `PER_FULFILMENT_CENTRE`; where a per-location invoicing entity is carried is not defined |
| 9 | Setup to first transaction | The reference app instructions and Postman examples exist. No verified path was found that takes a developer from ONIX and testnet setup to a first completed order, with configuration values, expected output and fixes for common failures | A tested quickstart: prerequisites, ONIX and testnet setup, Postman2Onix, catalogue publish, then select, init and confirm, with expected results |

One smaller inconsistency: the journey reconciles a Panadol order "after the return window", but the item is non-returnable and settles in one day.

## Sources and what was not verified

Read for this draft:

- [Release 1 README](https://github.com/indonesiaopennetwork/ion-specs/blob/main/releases/release1/README.md)
- [Transport and signing guide](https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Transport_and_Signing.md)
- [Entity hierarchy model](https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Entity_Hierarchy_Model.md)
- [Bu Sari complete journey](https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Bu_Sari_Complete_Journey.md)
- [Release 1 Trade flows README](https://github.com/indonesiaopennetwork/ion-specs/blob/main/releases/release1/flows/trade/README.md) and [Trade error registry](https://github.com/indonesiaopennetwork/ion-specs/blob/main/releases/release1/errors/trade.yaml)
- [Reference app README and technical artifact](https://github.com/indonesiaopennetwork/reference-app/blob/main/TECHNICAL_ARTIFACT.md)
- ION Developer Integration Handbook, Draft 1.1
- [marketplace-inhouse and marketplace-listed pattern files](https://github.com/indonesiaopennetwork/ion-specs/tree/main/releases/release1/flows/trade/patterns)

Read for endpoint paths and descriptions only, not payload schemas: [ion-beckn.yaml](https://github.com/indonesiaopennetwork/ion-specs/blob/main/releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml) and [ion-additional.yaml](https://github.com/indonesiaopennetwork/ion-specs/blob/main/releases/release1/schema/core/api/v2.0.0/ion-additional.yaml).

Not read, so not checked against this document:

- Field-level payloads in both contract files
- The Storefront flow files, state machines and `TradePerformanceStates` pack
- The policy registry and the Trade attribute packs
- The reference app's seller backend code, so its handler list is inferred from the README and technical artifact

First task for the team: check the order lifecycle and state names in section 7 against the Storefront flow files.
