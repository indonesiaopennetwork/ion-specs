# ION Developer Integration Handbook

**From understanding the network to operating a live Buyer App or Seller App**

| Document | Details |
|---|---|
| Version | Draft 1.1 — 21 November 2026 |
| Audience | Application developers, architects, engineering leads, TSPs, and onboarding teams |
| Prior knowledge | Familiarity with HTTP/REST, JSON, APIs and application development; no Beckn/ION experience assumed |
| Learning example | Trade: one Buyer App, one Seller App, one seller and one physical-product order |
| Coverage | Complete participant journey, including development, testing, onboarding, live orders, operations and specification extensibility |
| Authority | **Guidance, not a normative API specification**. Use the applicable ION Specs version, policies and approved onboarding requirements for authoritative details. |

> **Release note:** ION Specs Release 1 has been released. Use **Release 1** as the starting point for this handbook, and confirm the applicable version/tag or commit, sector profile, required capabilities and environment-specific onboarding requirements with ION. Avoid mixing examples or schema files from different branches or versions.

---

## Quick start: How to use this handbook

You might be connecting an existing bank, telecom, marketplace or merchant application to ION. Or you might be creating a new Buyer App or Seller App from scratch. This single document is designed for both cases.

1. **Read Sections 1–5 in sequence.** They explain what ION is and how its network interactions differ from normal REST APIs.
2. **Use Sections 6–7 to find the right specifications and observe a reference transaction.** Do this before designing your adaptor.
3. **Choose your path in Section 8:** Buyer App (BNP/BAP) or Seller App (SNP/BPP); existing app or new app.
4. **Follow Sections 9–11** to design/build your application, test it, complete onboarding and go live.
5. **Use Sections 12–14** for operating guidance, checklists, resources and ready-to-copy ChatGPT/Claude prompts.

**Central principle: ION is an extensible network, not a fixed list of use cases.** Implement the published constructs when they fit; if they do not, identify the gap, propose a compatible extension in GitHub, validate it with the relevant counterparties and contribute it for wider reuse. A pull request starts the contribution process; it is not by itself a network-wide release or automatic deployment.

**This handbook teaches you to navigate — and, when needed, help extend — the official specifications. It deliberately does not reproduce full YAML schemas, production configuration values or sector-specific payloads.** References to `/select`, `/on_select` and other Trade actions are teaching examples; the applicable release and profile decide exact obligations.

### The result you should aim for

By the end, you should be able to explain ION to another developer, identify the code you need to write, configure the applicable network interface, make your app transact with an independent counterparty, pass the required tests, complete onboarding, execute a controlled production transaction and operate it reliably.

---

# Part I — Understand ION

## 1. What is ION?

**ION (Indonesia Open Network)** enables independently operated applications to discover offers and transact with one another through common specifications, network identity and shared interoperability services. **ION is not one centralized marketplace.**

A familiar analogy is email: a user of one email service can exchange messages with a user of another because both systems follow interoperable rules. Indonesia's QRIS demonstrates a similar principle for interoperable payments. ION applies interoperability to commerce and other sector transactions.

A Buyer App can discover eligible offers from independently operated Seller Apps. A Seller App can serve multiple compatible Buyer Apps rather than building a proprietary commercial integration with each one. Each participant retains its own application, business systems and customer/operational responsibilities.

ION supplies and operates relevant shared network infrastructure (including the Registry and onboarding services), while participants operate their own applications and transact under applicable common rules. **ION does not itself become the buyer, seller, or default holder of transaction funds.**

### 1.1 Who participates?

| Term | Meaning | Main responsibility |
|---|---|---|
| **Buyer App / BNP** | Buyer Network Participant, generally playing the Beckn **BAP** role | Customer-facing discovery/selection, order initiation, buyer-side order handling, support and applicable payment responsibilities |
| **Seller App / SNP** | Seller Network Participant, generally playing the Beckn **BPP** role | Seller onboarding and catalogue publication, checking offers, responding to transaction messages, orders and fulfilment |
| **Seller / provider** | Business providing the product or service | Supply, availability, price and fulfilment commitments through its Seller App |
| **TSP** | Technology Service Provider | Builds or operates applications/adaptors on behalf of participants; not automatically the contracting participant |
| **PJP** | Licensed payment-service provider | Performs regulated payment activities under its arrangements |
| **ION** | Network operator / shared-service provider | Specifications, Registry, onboarding, rules and relevant network services |

**Names matter:** Some material says *BNP/SNP* and some says *BAP/BPP*. These are related, but not identical concepts: BNP/SNP describes ION network participation; BAP/BPP describes buyer/seller protocol roles. This handbook uses **BNP (BAP)** and **SNP (BPP)** together until the distinction is familiar.

### 1.2 One company can have more than one role

A company may operate a Buyer App, a Seller App or both, if its permitted participant profiles and integrations support them. Each role has different message and operational obligations. Do not infer that building one role automatically implements the other.

### 1.3 What ION does not provide automatically

Joining the network does **not** automatically create your mobile UI, catalogue search, product inventory, order-management service, payment account, customer support team or seller operations. ION facilitates interoperability; **your application still needs the business capabilities required for its role**.

**Checkpoint:** Can you explain why an ION Buyer App can transact with an independent Seller App without ION being a single central marketplace?

## 2. The building blocks — and who owns them

```text
                     SHARED NETWORK SERVICES
                  +----------------------------+
                  | ION Registry               |
                  | Participant identity/keys  |
                  | Endpoints/catalogue paths  |
                  | ION Central / Devlabs      |
                  +-------------+--------------+
                                |
                 Identity / discovery lookup
                                |
    BUYER PARTICIPANT                              SELLER PARTICIPANT
  +---------------------+                      +----------------------+
  | Buyer UI / Backend  |                      | Seller UI / Backend  |
  | Search, cart, order |                      | Catalog, stock, OMS  |
  +----------+----------+                      +-----------+----------+
             |                                             |
  +----------v----------+                      +-----------v----------+
  | Buyer-side adaptor  |                      | Seller-side adaptor  |
  | Application logic   |                      | Application logic    |
  +----------+----------+                      +-----------+----------+
             |                                             |
  +----------v----------+     signed protocol  +-----------v----------+
  | Buyer-side ONIX     |<-------------------->| Seller-side ONIX     |
  +---------------------+     requests/callbacks+----------------------+

                  Seller-hosted catalogue files
                  discovered by compatible BNPs
```

*Conceptual model only; internal routing and deployment details depend on the selected ONIX/reference-app version. ION is not necessarily in the data path for each participant-to-participant business message.*

### 2.1 Beckn and ION Specs

**Beckn v2** provides the common interaction framework. **ION Specs** profile this framework for ION, including network conventions, sector schemas, applicable patterns, categories, attributes and policies. Think of Beckn as the protocol foundation and ION Specs as the applicable network contract.

### 2.2 ONIX

**ONIX** is a participant-side protocol runtime. It supports network connectivity concerns such as message signing/verification, validation, routing and Registry-related operations, subject to the deployed configuration. It is **not** your order engine, inventory system or buyer-facing UI.

Your **adaptor** connects the protocol side to your business application. It translates events and data between network contracts and your internal services. It can be a separate microservice or a logical integration component; the exact implementation architecture is your choice, subject to network requirements.

### 2.3 Registry

The ION Registry identifies permitted participants, roles, network endpoints and public keys; it also supports Seller App catalogue location registration. A participant must distinguish **organization identity**, **participant/profile identity**, **application endpoint** and **seller/provider identity**. These are not interchangeable.

### 2.4 Distributed catalogues

In the described Trade model, Seller Apps prepare catalogue files and indexes, host them on the seller side and register their locations; Buyer Apps discover and ingest these catalogues or use applicable optional discovery tools. **This is not a central ION catalogue into which every seller uploads inventory.** Verify the current publication/index format and mechanisms in the selected Trade specifications.

### 2.5 Identity, security and message tracking

- **Private signing keys** remain with participants; public keys are registered and discovered as required.
- The Technical Overview describes **Ed25519** signed messages. Follow the selected transport/signing contract for exact headers, canonicalization, timestamps and verification rules.
- A **transaction ID** links messages in the same business exchange; a **message ID** identifies an individual protocol message. Do not use one as a substitute for the other.
- Internal systems must account for duplicate deliveries, retries, callback timing and network errors; the exact protocol retry and idempotency rules belong to the normative transport specification.

### 2.6 Validation, policies, OPA and Rego

An API contract is more than its JSON shape. Developers should distinguish **three different questions**:

| Layer | Developer question | Typical owner/source |
|---|---|---|
| Structural validation | Does this message follow the applicable schema, field definitions and types? | ION Specs and the configured protocol validator |
| Network/sector policy | Is the interaction allowed under the relevant network, participant, sector, offer or transaction rules? | Policy references and applicable policy evaluation/enforcement configuration |
| Application business decisions | Can my application actually fulfil this request—for example, given availability, pricing, eligibility or credit rules? | Participant application and business systems |

**Policy IRIs** identify policy rules or conditions referenced by a network interaction or offer. **Open Policy Agent (OPA)** is a general-purpose policy engine, and **Rego** is its policy language. A machine-readable rule may be authored in Rego and evaluated against inputs to produce a decision. That does **not** mean every Policy IRI is itself a Rego file, or that every rule is enforced in the same location. Refer to the selected ION policy source and ONIX implementation to establish which rules are loaded, when they run, how they are versioned, and what happens on failure.

Example of the *concept* (not an ION normative rule): a request might be valid JSON but fail an applicable participant-eligibility policy. Or it might pass both schema and network-policy checks, but the seller application may reject it because stock is unavailable. These are different failures with different owners and responses.

**What to do as a developer:**

1. Find the applicable Policy IRI and rule definition in the relevant specification/`policies/` resources.
2. Identify the enforcement point for your deployed ONIX/application configuration; do not assume ONIX automatically evaluates every business rule.
3. Test an allowed case and a rejected case; record which component rejected the request and the documented error response.
4. Record policy version and evidence with the transaction trace, avoiding exposure of sensitive policy inputs.
5. When proposing a new rule, consider both its policy definition and its deployment/compatibility implications (see **Section 6.4**).

**Further reading:** [ION policy directory](https://github.com/indonesiaopennetwork/ion-specs/tree/main/policies), [ION contributing rules](https://github.com/indonesiaopennetwork/ion-specs/blob/main/CONTRIBUTING.md), [OPA and Rego documentation](https://www.openpolicyagent.org/docs).

### 2.7 ION Observability & Intelligence — and what you still need to monitor

**ION Observability & Intelligence** is ION's shared service for network-level events, operational diagnostics and reporting. It helps participants and ION operations investigate network interactions. It does **not** replace the participant's own application logs, order records, inventory/fulfilment traces, customer support tools or payment-provider records.

| Where to look | What it helps answer | What it does **not** establish by itself |
|---|---|---|
| Participant application logs | Did our business handler accept the request, update internal state and issue the next action? | Whether the counterparty actually completed its business step |
| ONIX/runtime telemetry | Did signing, validation, delivery, callback acceptance or related protocol operations succeed? | Whether stock, payment or fulfilment was correct |
| ION Observability & Intelligence | What network-level events and correlated diagnostic information are visible to the shared service? | A complete authoritative record of all participant internal processing |
| Payment/fulfilment providers | Did a payment, refund, payout or real-world delivery complete? | Whether all protocol exchanges were correctly handled |

**Practical trace:** record the `transaction_id` across the whole journey, capture the distinct `message_id` of each request/callback, note its timestamp, action, sender/receiver, transport acknowledgement, business result and internal order state. Correlate those identifiers across application, ONIX and available ION observability views. Mask personal/payment data.

**Implementation boundary:** available dashboards, log fields, retention, participant access permissions and alerting are environment-dependent. Consult ION's actual Devlabs/production documentation and access rights; this handbook does not promise a particular dashboard, public endpoint or complete payload visibility.

**Checkpoint:** Explain whether a failed order is a schema failure, policy rejection, application/business rejection or lost/delayed callback—and name which evidence source you would inspect first.

**Checkpoint:** Sketch your app, adaptor, ONIX, counterparty ONIX and shared Registry. Label who operates each component.

---

# Part II — Understand two-sided APIs before opening Swagger

## 3. Familiar REST integration versus ION interaction

### 3.1 The familiar case

```text
YOUR APPLICATION                            A SERVICE YOU CALL
       |                                             |
       |----- POST /check-availability ------------->|
       |<---- HTTP response: availability/price -----|
       |                                             |
```

In many conventional REST integrations, the HTTP response contains the immediate business result. The mental model is **client calls provider**.

### 3.2 ION: two independent participants, two messages

```text
      BUYER APP       BUYER ONIX       SELLER ONIX       SELLER APP
          |               |                 |                |
          |--- /select -->|---- request --->|-- /select ---->|
          |               |<--- ACK/NACK ---|<-- ACK/NACK ---|
          |               |                 |                |
          |               |                 |   Business checks
          |               |                 |   price, stock, etc.
          |               |                 |                |
          |<-- on_select -|<--- callback ---|<-- on_select --|
          |--- ACK ------>|---- ACK ------->|                |
          |               |                 |                |
```

*Illustrative logical sequence, not a wire-level routing trace. Follow actual ONIX handlers and the selected API contract for exact transport paths and ACK forwarding.*

There are **two distinct responses** to understand:

1. **ACK/NACK:** A prompt transport acknowledgement indicating a message was received/accepted or rejected at the relevant protocol boundary. An ACK **does not** mean that price, availability, payment or order is confirmed.
2. **`on_*` callback:** A separate business message returned later after the counterparty processes the request. That callback is itself acknowledged at transport level.

**The critical mental-model shift:** A Buyer App is both a **sender** (`/select`) and a **receiver** (`/on_select`); a Seller App is both a **receiver** (`/select`) and a **sender** (`/on_select`). These are different application responsibilities and may be exposed through different endpoints at the relevant participant boundaries.

### 3.3 An API table is easier when viewed by role

| Trade exchange | BNP role | SNP role | What it means |
|---|---|---|---|
| `/select` | Initiate | Receive/process | Request evaluation of selected offer(s) |
| `/on_select` | Receive/process | Initiate callback | Return selection business result |
| `/init` | Initiate | Receive/process | Begin finalizing checkout/order terms |
| `/on_init` | Receive/process | Initiate callback | Return terms/details for confirmation |
| `/confirm` | Initiate | Receive/process | Request order commitment |
| `/on_confirm` | Receive/process | Initiate callback | Communicate confirmation business result |
| `/status` and `/on_status` | Often query/receive | Often process/respond | Exchange order status |
| `/track`, `/update`, `/cancel` and corresponding callbacks | Depends on applicable flow | Depends on applicable flow | Tracking, changes and cancellation |
| `/support` / `/on_support` | Defined case roles | Defined case roles | Order-related support where implemented |
| `/reconcile` / `/on_reconcile` | May initiate/respond | May initiate/respond | Two-party settlement-position agreement |
| `/rate` / `/on_rate` | Depends on applicable profile | Depends on applicable profile | Post-order rating exchange |

**Do not treat this illustrative Trade table as a complete mandatory endpoint list.** Some exchanges support different initiators or sector-specific patterns. Obtain the approved **role + sector + profile + release capability matrix** before coding.

### 3.4 How an asynchronous application should behave

A production application should not treat “HTTP ACK” as “order accepted.” A typical design must:

- Persist a pending transaction state after initiating a request.
- Correlate the later callback using the specified identifiers.
- Verify and process callbacks safely even if they arrive after a UI request or mobile session ends.
- Update business state only when a valid business result is received.
- Handle failure, timeout, duplication, retransmission and user re-entry without creating duplicate orders.
- Publish the updated state to the UI or other internal systems through suitable event processing or polling.

**Illustrative application state model, not an ION schema:**

```text
USER INITIATES ACTION
      -> request queued/sent
      -> protocol ACK received (not business success)
      -> waiting for business callback
      -> callback received and validated
      -> business outcome accepted/rejected/pending
      -> internal order state updated
      -> UI / operations notified
```

### 3.5 What to look for in an actual callback

The applicable JSON contract may include a `context` holding identifiers, sender/receiver details, action and timing information and a `message` holding business data. **Do not copy generic field assumptions into production code.** Open the selected YAML definition and example for the exact field names, types, requirements and accepted values.

**Checkpoint:** Explain aloud: *“The ACK confirms protocol receipt, not business success. The callback comes later and must be received at my side.”* If you cannot explain this clearly, revisit this section before Swagger.

## 4. Why Swagger can be confusing — and how to read it

Swagger/OpenAPI lets you inspect a **single API contract**. It does not, by itself, tell the complete story of a multi-party transaction: which independent party calls which API, which callback follows, what ONIX does, who owns the underlying data, or when a business process is complete.

For **each API**, use this seven-question method:

1. **Business event:** What happened to trigger the call?
2. **Initiator:** Which participant sends it in this pattern?
3. **Receiver:** Which participant must expose/handle it?
4. **Immediate result:** What does ACK/NACK represent here?
5. **Business callback:** What separate `on_*` message follows, and to whom?
6. **Application work:** What is my adaptor/business service expected to do?
7. **Contract:** Where in the approved release are its schema, errors, policies and examples defined?

For every relevant endpoint, record this in an integration matrix rather than relying on memory.

| Action | I send? | I receive? | Required callback | Backend handler | State change | Schema link | Test result |
|---|---|---|---|---|---|---|---|
| Example `/select` (BNP) | Yes | No | Receive `/on_select` | Selection service | Pending → outcome | Fill from approved release | Pending |
| Example `/select` (SNP) | No | Yes | Send `/on_select` | Pricing/availability | No order yet | Fill from approved release | Pending |

The rows above are **illustrative**, not a substitute for approved endpoint matrices.

---

# Part III — See one complete business transaction

## 5. Trade learning example: one product, complete lifecycle

Use a simple purchase to understand the **whole** transaction and operational lifecycle: **one BNP, one SNP, one seller, one physical product**. This is a teaching scenario, not a promise that all optional or post-order extensions are implemented by every production participant.

The complete happy path is **publish → discover → select → initiate → confirm → pay → fulfil → status/track → reconcile → settle → rate**. The developer must also understand **cancel/refund**, **order support** and **participant dispute** branches, even though those are not triggered in every purchase.

### 5.1 The lifecycle map

| Business stage | BNP / buyer-side responsibility | SNP / seller-side responsibility | What to find in ION resources |
|---|---|---|---|
| **1. Publish** | Not yet ordering; prepare ingestion/curation | Generate and host seller catalogue/index; maintain updates; register location | Catalogue packs, seller hierarchy, publication/index rules |
| **2. Discover** | Locate, ingest and display eligible offers, subject to coverage and curation | Keep registered catalogue accessible and accurate | Registry/catalogue discovery reference implementation |
| **3. Select** | Initiate selection; wait for callback; reflect pricing/serviceability result | Check availability, pricing and fulfilment options; return callback | `/select`, `/on_select` and applicable Trade flow |
| **4. Initiate** | Supply applicable buyer, fulfilment and payment-choice details; wait for callback | Return applicable order terms | `/init`, `/on_init` |
| **5. Confirm** | Ask for order commitment; process callback | Create/commit order and return confirmation | `/confirm`, `/on_confirm` |
| **6. Payment** | Coordinate permitted payment collection and status under current arrangements | Receive relevant commercial/payment status; fulfil only per agreed terms | Applicable payment attributes/policies; payment integration is not merely an ION protocol call |
| **7. Fulfil/track** | Display status, alerts, tracking and completion | Arrange fulfilment and send appropriate status/tracking events | `/status`, `/track`, `/update` and their relevant callbacks |
| **8. Cancel/refund branch** | Handle customer request and show outcome | Apply applicable cancellation/return/fulfilment policies and provide result | `/cancel` and other applicable update/support patterns; payment-provider refund steps |
| **9. Support branch** | Receive buyer issue and exchange case information | Respond to relevant issue and resolution workflow | `/support`, `/on_support` and applicable policy |
| **10. Reconcile** | Calculate and exchange settlement positions; agree with counterparty | Calculate and exchange its corresponding settlement positions; agree | `/reconcile`, `/on_reconcile` and reconciliation spec |
| **11. Settlement** | Under the described current model, arrange applicable seller-side remittance; maintain evidence | Receive/record agreed settlement and handle accounting with sellers | Relevant participant/PJP arrangements; SEAM if applicable |
| **12. Ratings** | Record/communicate applicable feedback | Process relevant rating information | `/rate`, `/on_rate`, applicable profile |
| **13. Participant dispute branch** | Raise/handle qualifying participant-level matter | Raise/handle qualifying participant-level matter | ION SATU through ION Central (not the same as customer order support) |

### 5.2 Important details across the lifecycle

**Catalogue before order:** A buyer cannot discover a product merely because the seller created a `/select` endpoint. The SNP must publish valid catalogue information, and a compatible BNP must discover/ingest it. Visibility is still subject to buyer-app curation, eligibility and serviceability.

**Selection is not confirmation:** `/select` checks the proposed selection; `/init` progresses checkout terms; `/confirm` seeks an actual order commitment. Treat these as different business states even when the UI makes them look like one checkout flow.

**Payment is not just another ACK:** Regulated money movement happens through licensed payment arrangements. In the Technical Overview's current model, the BNP collects the customer payment via a PJP and remits agreed amounts to the seller side. **ION does not hold transaction funds**. The SEAM-assisted payout model is a separate integration track; the Technical Overview describes it as under PJP integration testing, not as a default requirement for every participant.

**Reconciliation is not settlement:** Participants exchange calculated settlement positions and explicitly agree; then the authorized money movement is executed under the applicable arrangement. Reconciliation is between BNP and SNP; an SNP may handle its internal seller/logistics splits separately. Exact financial payloads and agreement rules must come from the selected reconciliation specification.

**Support is not the same as a participant dispute:** Order-level customer complaints may be exchanged through the support APIs where implemented. Commercial/operational disputes between participants are handled through **ION SATU** in ION Central under the model described by the Technical Overview.

**Don't confuse a specified extension with production adoption:** The Technical Overview dated November 2026 describes core Trade transactions as live, while support/reconciliation/ratings are specified/reference-tested with production participants implementing them, and SEAM/PJP connectivity is being tested. Check current participation and readiness requirements with ION; do not assume every counterparty supports every extension today.

### 5.3 A complete transaction has more than a happy path

Walk through these branches during design and testing:

- Product price or stock changes before confirmation.
- Buyer abandons checkout; prior selection remains incomplete.
- ACK arrives but callback is delayed or never arrives.
- Callback is retried or duplicated.
- Seller cannot fulfil an already confirmed order.
- Cancellation occurs before or after payment and may require a refund.
- Customer raises an issue and the counterparty must respond.
- Participant settlement positions differ; reconciliation cannot be marked agreed prematurely.
- Payment or payout fails even though the business order was accepted.
- A participant-to-participant dispute requires ION SATU escalation.

**Checkpoint:** Draw the journey from catalogue to settlement and identify the responsible participant at every step. Show at least one cancellation and one support branch.

---

# Part IV — Navigate the official specifications and tools

## 6. Learn where to look, instead of copying the YAML

| Resource | What to use it for | Link |
|---|---|---|
| **ION Specs** | Released specifications, API contracts, schemas, sector profiles and policies | https://github.com/indonesiaopennetwork/ion-specs |
| **ION Specs Release 1** | Review Release 1 schemas, validation guidance and applicable sector requirements | https://github.com/indonesiaopennetwork/ion-specs/tree/main/releases/release1 |
| **Transport/signing guide** | Network messaging, signatures, transport ACK/NACK, callbacks | https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Transport_and_Signing.md |
| **Entity hierarchy model** | Understand organization, participant, role, sector and related entities | https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Entity_Hierarchy_Model.md |
| **Bu Sari complete journey** | Read a worked Trade journey and its corresponding examples | https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Bu_Sari_Complete_Journey.md |
| **ION Reference App** | See BAP/BPP applications, ONIX deployments, discovery and supporting services | https://github.com/indonesiaopennetwork/reference-app |
| **Postman2Onix** | Run a learning environment and inspect test API interactions | https://github.com/indonesiaopennetwork/reference-app/tree/main/Postman2Onix |
| **ION documentation repo** | Common developer and network documents | https://github.com/indonesiaopennetwork/ion-docs |
| **Contributing to ION Specs** | Extension PR format, compatibility, validation and review | https://github.com/indonesiaopennetwork/ion-specs/blob/main/CONTRIBUTING.md |
| **ION policy sources** | Explore policy definitions and registered IRIs | https://github.com/indonesiaopennetwork/ion-specs/tree/main/policies |
| **ION Central** | Organization and participant onboarding, agreements and participant services | https://central.ion.id |
| **ION Devlabs** | Developer testing and validation services | https://devlabs.ion.id |
| **Beckn Protocol v2** | Upstream protocol foundation | https://github.com/beckn/protocol-specifications-v2 |

**Link/version rule:** Repository paths are navigational entry points, not immutable production contracts. Before implementation, pin the approved commit or release and confirm that each linked document matches it. If a link has moved, find the corresponding resource in the selected release rather than silently switching branches.

### 6.1 Recommended order for reading ION Specs

1. Read the repository README and the selected release README/release metadata; verify **version and status**.
2. Read the entity hierarchy model and transport/signing material.
3. Find the selected **sector and transaction pattern**, then its supported **variants**.
4. Identify applicable **Catalogue Resource Categories (CRCs)** and the associated **attribute packs**.
5. Find referenced **policies/Policy IRIs**, conditions and remedies.
6. Open the relevant **OpenAPI/YAML schemas** in Swagger or another compatible viewer.
7. Trace a complete request–ACK–callback exchange using the reference flow and sample payload.
8. Create your own **role-specific interface and field mapping**, with references back to the exact source file and version.

### 6.2 Useful concepts developers should recognize

- **CRC (Catalogue Resource Category):** Helps classify what is being offered and which information applies.
- **Attribute pack:** Defines relevant groups of attributes for entities/offers in a profile.
- **Transaction pattern and variant:** Describe how an interaction is structured for a particular use case.
- **Policy IRI:** References applicable machine-readable network or offer rules; do not treat a human explanation as the policy itself.
- **TLC (Transaction Level Contract):** A transaction-level record/commitment concept referenced in the Technical Overview, used where adopted.
- **Core versus extension:** Distinguish upstream Beckn-based contracts from ION-specific additions and sector profiles.

### 6.3 Practical specification-reading worksheet

For each selected action, capture:

| Item | Your answer |
|---|---|
| Approved baseline | Branch / tag / commit / release |
| Sector and pattern | Which exact profile/variant? |
| Participant role | BNP or SNP; BAP/BPP direction |
| API / callback pair | Initiating action and callback |
| Required input/output | Exact schema file links and required fields |
| CRC / attributes / policy | Applicable files and IRIs |
| Error/cancellation behavior | Exact documented outcomes |
| Existing system mapping | Application service, data fields, state transitions |
| Validation evidence | Postman/ref-app case and observed result |

**Checkpoint:** Find a `/select`-related contract and explain its sender, receiver, callback, applicable variant and sample payload **without** claiming that the HTTP ACK is the business result.

### 6.4 Extending ION Specs — a core capability, not a last resort

> **You can build on ION without waiting for every future use case to be pre-designed.** Its specifications include reusable, extensible constructs. When a capability is missing, the developer can propose improvements through GitHub so that other participants can benefit too.

This is important both for an existing participant connecting a new product and for a developer creating an entirely new application. **First reuse what exists; then extend only the smallest missing piece.** Avoid private, incompatible meanings for shared fields.

#### Where an extension might fit

| Need | First inspect | Possible contribution if not already covered |
|---|---|---|
| A new category of product or service | CRC/category definitions and sector packs | New or refined CRC and associated structure |
| Additional fields describing an offer | Existing attribute packs, vocabulary and JSON-LD terms | Compatible attribute-pack enhancement or extension |
| A different business journey | Existing sector patterns, variants, flows and state transitions | New/refined pattern, variant or flow |
| Additional conditions or remedies | Policy IRIs and policy sources | New registered policy/rule with defined scope and tests |
| A new validation/error outcome | Relevant schema, error registry and policy mapping | Documented, unique error definitions and examples |
| A completely new sector use case | Common entity hierarchy and reusable packs | Sector profile built from shared constructs before adding new ones |

This table is a **navigation aid**, not permission to add arbitrary fields or API actions. The selected release's schema/style/design guidance determines the correct shape.

#### From unmet requirement to contribution

1. **Describe the real use case.** State which BNP and SNP need to exchange what information and what breaks without it. Include expected business and technical behavior.
2. **Find the closest existing construct.** Search the selected release for CRCs, attribute packs, flow patterns, policy IRIs, common definitions and error models. Sometimes configuration, data mapping or a supported extension point solves the problem without a spec change.
3. **Define the smallest compatible change.** Say whether it is additive or breaking; identify affected schemas, flows, policies, vocabularies, examples, validation and consumer behavior.
4. **Create a branch and submit a PR.** Follow [CONTRIBUTING.md](https://github.com/indonesiaopennetwork/ion-specs/blob/main/CONTRIBUTING.md), the [schema style guide](https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Schema_Style_Guide.md) and [schema design guide](https://github.com/indonesiaopennetwork/ion-specs/blob/main/docs/ION_Schema_Design_Guide.md). Use the repository's correct contribution target; do not modify a published immutable release in place.
5. **Include proof.** Add aligned schema artifacts/examples/registry changes where required, document compatibility, run relevant repository validators and report actual test results. The contributing guide gives the applicable validation entry points; use those for the target release rather than blindly copying an example command.
6. **Test with willing counterparties in an agreed environment.** Confirm both ends interpret the extension consistently, that unaffected participants remain compatible, and that policy or runtime configuration is actually deployed where needed.
7. **Track review and adoption.** An open PR records a proposal; merging/release publication and the activation of a configuration are separate steps. Record the agreed scope before using an extension in production.
8. **Contribute the learning back.** Supply an understandable example, a changelog entry and migration/compatibility notes so that other developers can implement the same feature.

**Simple rule:** _Raise a PR and begin collaborating/testing without waiting for a complete network-wide rollout; do not assume that opening a PR alone authorizes universal production behavior._ Two participants may agree to a controlled extension only within applicable network policies, conformance requirements and production permissions. Check those boundaries with ION.

#### What a useful extension PR explains

```text
Use case / user problem:
Existing ION construct reviewed:
What is missing and why current options do not work:
Proposed schema / CRC / attribute / flow / policy change:
Affected roles and sectors:
Backwards compatibility (additive, compatible, breaking):
Examples and negative cases:
Validation commands and actual results:
Required runtime/policy deployment or participant coordination:
Proposed pilot counterparties and adoption scope:
Open questions for ION review:
```

**Repository-specific detail:** ION's contribution guide currently distinguishes changes to published immutable releases from work in an active development release, maintains policies in the root `policies/` tree and requests extra review for certain release/publication and semantic changes. Follow its current instructions even if an older document or AI assistant suggests a different directory. These are repository contribution rules, not a claim that every proposed extension is instantly production-approved.

**Checkpoint:** Given a missing capability, can you show (a) why an existing construct is insufficient, (b) the smallest proposed extension, (c) the GitHub contribution target, and (d) how two counterparties would test it without affecting others?

---

## 7. First hands-on exercise — before building your adaptor

The purpose is to **observe**, not to complete your production integration.

### Prepare

- Confirm the ION-approved learning baseline with the team and identify the matching Postman/ONIX environment.
- Read the Reference App README and Postman2Onix instructions for prerequisites and exact startup commands. Do not invent credentials or assume a public production endpoint can be used as a sandbox.
- Identify the sample Buyer App, Seller App, catalogue and test identities.

### Execute and record

1. Start the required reference components and ONIX instances using the repository instructions.
2. Publish or load the sample catalogue as instructed and verify discovery from the buyer side.
3. Execute **selection**, **initiation** and **confirmation** from Postman or the reference UI.
4. At each exchange, capture: sending participant, receiving participant, URL/path at the exposed boundary, transaction/message IDs, transport ACK/NACK, callback action and business result.
5. Follow the order through status/fulfilment and the applicable post-order demos. If a flow is unsupported in the chosen reference environment, **record the limitation** and inspect the relevant specs rather than claiming it passed.
6. Simulate at least one negative scenario (e.g., unavailable product or delayed callback) supported by the test harness.
7. Compare the observed messages to the matching release contracts.

### Evidence to produce

- One annotated message sequence showing both participant sides and their ONIX boundaries.
- A sample transaction trace (IDs redacted as needed) from catalogue/discovery through order confirmation.
- A list of **what the reference app did**, **what ONIX did** and **what your own adaptor would need to do**.
- A list of unsupported or unclear capabilities to clarify with ION.

**Checkpoint:** You can demonstrate an end-to-end *reference* transaction and show that a request ACK and an `on_*` business callback are different events.

---

# Part V — Choose your path and design your application

## 8. Two independent choices: role and starting point

**Choice 1 — Role:** BNP (Buyer App) / SNP (Seller App) / both.

**Choice 2 — Starting point:** Existing application / New application from scratch.

| | Existing application | New application |
|---|---|---|
| **BNP / BAP** | Connect existing customer app, search/cart/checkout/payment/order systems to ION; fill gaps for asynchronous interactions and discovery | Build customer UI and business services *plus* ION integration, discovery and callback/event handling |
| **SNP / BPP** | Connect existing catalogue, inventory, OMS, fulfilment and seller operations to ION; implement catalogue publication and inbound protocol handling | Build seller and operations UI/backends *plus* catalogue publisher, fulfilment processes and ION integration |

**Keep the protocol bar the same.** Building from scratch adds application work; it does not relax ION requirements. Having an existing app may reduce UI development but can create significant state-model and data-mapping work.

### 8.1 Application capability assessment

For an **existing application**, mark each relevant capability **Already available / Needs adaptation / Missing / Not applicable**:

| Area | BNP examples | SNP examples |
|---|---|---|
| UI and identity | Login, buyer experience, product browse, cart, checkout, order history | Seller operations UI, product/catalogue admin, order desk |
| Core domain services | Search, cart, order state, customer support | Product, price, inventory, OMS, fulfilment |
| Payment and accounting | Payment provider, receipts, refunds, settlement obligations | Receivables, reconciliation, seller-side accounting |
| Network integration | Buyer adaptor, ONIX, discovery, inbound callbacks | Seller adaptor, ONIX, catalogue publisher, inbound requests |
| Reliability and operations | Persistent events, retries, logs, alerting | Persistent events, retries, logs, alerting |

For a **new application**, use this as a minimum capability planning checklist, not a complete product-requirements document. ION's handbook is not a general course in frontend development or ecommerce platform design.

## 9. The BNP / Buyer App implementation path

### 9.1 What you need to build or connect

```text
Buyer UI / Channel
      |
Buyer domain services (users, browse, cart, checkout, orders, support)
      |                     ^
      |                     | events / callback state changes
Buyer ION adaptor <----> Buyer-side ONIX <----> Seller-side ONIX / SNP
      |
Catalogue discovery/ingestion and indexing
      |
Seller-hosted catalogue locations discovered through Registry
```

**BNP workstreams:**

1. **Architecture and mapping:** Choose adaptor boundary; map ION entities to existing cart/order/payment/customer services.
2. **Catalogue discovery:** Implement or configure an approved mechanism to locate and ingest distributed seller catalogues, track index changes, apply eligibility and serviceability, and display curated offers.
3. **Request initiation:** Implement buyer-side business logic to construct and send relevant requests (e.g., select/init/confirm) through configured ONIX.
4. **Inbound callbacks:** Expose/process required `on_*` callbacks; authenticate/validate through the configured boundary and correlate to pending transactions.
5. **Business state and UI:** Handle pending/confirmed/rejected states; expose accurate status without treating an ACK as confirmation; notify users as outcomes arrive.
6. **Payment and order operations:** Connect existing payment/provider arrangements, order lifecycle, tracking, cancellation/refunds and customer support as required.
7. **Post-order:** Add applicable support, rating, reconciliation and settlement-related handling per approved scope.
8. **Operational controls:** Idempotency, timeout strategy, tracing, reconciliation of internal/network states and error recovery.

### 9.2 Existing BNP versus new BNP

**Existing application:** Start with capability and data mapping; retain functioning authentication/UI/payment services where appropriate; add ION discovery, adaptor, callback endpoints and state management. Expect UI changes for asynchronous pending outcomes.

**New application:** In parallel with ION integration, design buyer registration/login, browsing, cart, checkout, order history, tracking, cancellation/support and payments. Treat these as **your application responsibilities**, not ONIX features.

### 9.3 BNP completion evidence

- Eligible catalogue offers appear in the Buyer App with the right seller and offer references.
- The app can complete the applicable select → init → confirm exchange with a test SNP.
- Callback processing survives browser/app-session closure and updates the correct internal order.
- Relevant status, cancellation, support, payment and reconciliation flows are verified for the agreed pilot scope.
- Duplicate/delayed callbacks and failed requests do not create duplicate business orders.

## 10. The SNP / Seller App implementation path

### 10.1 What you need to build or connect

```text
Seller UI / Admin / Existing commerce platform
      |
Product, inventory, pricing, OMS, fulfilment, support/accounting
      |
Seller ION adaptor <----> Seller-side ONIX <----> Buyer-side ONIX / BNP
      |
Catalogue generator / publisher and index updates
      |
Seller-hosted files / registered catalogue location
```

**SNP workstreams:**

1. **Seller/entity mapping:** Decide inventory-owned seller versus marketplace-led seller model and map its identities to the applicable ION entity hierarchy.
2. **Catalogue publication:** Generate valid files and index, publish at accessible seller-hosted locations, register the path and maintain updates.
3. **Inbound handlers:** Process relevant buyer requests (select/init/confirm and operational actions), map to internal pricing, stock, order and fulfilment services.
4. **Business callbacks:** Generate and send the correct `on_*` results via ONIX, keeping message context and transaction correlation intact.
5. **Order state:** Prevent double acceptance/fulfilment on duplicate requests; maintain transitions when cancellations or updates arrive.
6. **Fulfilment:** Integrate order handling, delivery/service milestones and status communication.
7. **Post-order:** Implement applicable support, refund/cancellation, reconciliation, settlement records and ratings.
8. **Operational controls:** Catalogue freshness, serviceability, business error responses, tracing and recovery.

### 10.2 Existing SNP versus new SNP

**Existing application:** Integrate product master, catalogue content, stock, prices, OMS and fulfilment; add publication pipeline and protocol adaptor. Ensure offers remain accurate when the internal catalogue changes.

**New application:** Build seller/product management, inventory/price update workflow, OMS, fulfilment interface and operator tools in addition to protocol integration. A reference BPP can illustrate a pattern, but is not automatically a production-ready marketplace product.

### 10.3 SNP completion evidence

- Buyer-side discovery finds the published eligible catalogue and can use the offer IDs correctly.
- The SNP validates selection, processes order initiation/confirmation and emits business callbacks.
- Inventory/order transitions and fulfilment events stay consistent across internal and network systems.
- Cancellation, support, duplicate-request handling and financial records are tested as applicable.
- Seller operations can monitor and resolve failed or delayed transactions.

## 11. One shared implementation plan, two parallel tracks

### 11.1 Technical integration track

| Milestone | Key activities | Exit evidence |
|---|---|---|
| **T1 — Understand** | Fundamentals, roles, messages, ONIX and Registry | Can explain request/ACK/callback, boundaries and transaction stages |
| **T2 — Experience** | Reference ONIX/Postman journey | Trace from discovery to confirmation with IDs and callbacks |
| **T3 — Scope** | Approved baseline/profile, endpoint matrix, capability inventory | Agreed build scope and mapping |
| **T4 — Design** | Architecture, event/state model, security, persistence and error handling | Reviewed technical design |
| **T5 — Build** | Catalogue integration, adaptors, business systems, relevant UI | App-to-reference counterparty integration works |
| **T6 — Validate** | Happy path, negative paths, protocol, operations and sector tests | Test evidence and resolved defects |
| **T7 — Production** | Production endpoint/configuration and controlled live transaction | Successful and traceable live order |

### 11.2 Organization and network onboarding track

Run this **in parallel** with T1–T6 where ION allows it:

1. Register organization in **ION Central** and assign appropriate contacts/roles.
2. Create relevant BNP/SNP participant profile with sector and activity scope.
3. Complete applicable business/KYB checks and network participation agreement.
4. Complete prescribed Devlabs validations, participant conformance and certification/approval gates, as applicable.
5. Register approved production identity, public keys, endpoints and SNP catalogue locations.
6. Agree operational owner, support escalation, payment arrangements and launch counterparties.

**Important:** This sequence is an onboarding roadmap, not a claim that each portal step is available in precisely this order or that ION approvals apply to all steps. Follow the current ION Central workflow and published participation policies.

### 11.3 Three distinct statuses

- **Technically integrated:** Working against a compatible test counterparty.
- **Production enabled:** Has met ION's applicable production-activation requirements.
- **Commercially live:** Actually completes and supports real participant transactions.

Production registration is not the same as a functioning business launch.

---

# Part VI — Test, go live and operate

## 12. Validation: what must be demonstrated?

A passing Swagger schema validation is necessary where required but **not sufficient**. A usable integration must also prove business flow, routing, callback processing, persistence and operational recovery.

| Test area | Representative questions |
|---|---|
| Protocol/schema | Is each sent/received message valid for the approved release, profile and policy? |
| Policy enforcement | Are registered policy IRIs resolved and their applicable Rego/other policy evaluations tested where deployed? |
| Extension compatibility | If using a proposed extension, have both endpoints, schema validators and policy configurations agreed on its version and scope? |
| Observability | Can application/ONIX/network-level evidence be correlated by transaction and message IDs, subject to access rights? |
| Identity/security | Are participants, endpoints, signatures, timestamps and keys handled correctly? |
| Async processing | Do ACK/NACK and callbacks behave as separate events? What if callback is delayed? |
| Ordering | Does select/init/confirm produce valid states; can you recover from failure mid-journey? |
| Catalogues | Can a BNP discover a changed catalogue? Can an SNP maintain a valid published index? |
| Data/IDs | Are transactions correlated correctly across callbacks and internal orders? |
| Duplicates/retries | Does a repeated request or callback cause unintended double side effects? |
| Business exceptions | Out of stock, price change, cancellation, refund, unsupported fulfilment? |
| Post-order | Status, tracking, support, reconciliation, settlement records and ratings where applicable? |
| Operations | Logs, dashboards, alerts, escalation, deployment rollback and support ownership? |

### 12.1 Suggested evidence pack

Keep an **approved test plan and results**, message traces with sensitive data masked, schema validation output, runbooks, error/retry demonstrations, conformance evidence and a list of any exemptions or unsupported features. ION must define which tests are mandatory for a particular production role/profile.

### 12.2 Common mistakes to catch

- Treating transport ACK as stock or order confirmation.
- Implementing only outbound API calls, without inbound callback handlers.
- Assuming ONIX implements the business rules for the application.
- Using an unpinned `main` YAML as if it were a certified production contract.
- Hard-coding one seller endpoint rather than using applicable network discovery/identity rules.
- Treating catalogue publication as equivalent to guaranteed Buyer App visibility.
- Confusing customer support with an inter-participant dispute.
- Equating reconciliation agreement with movement of funds.
- Assuming all valid YAML/JSON automatically passes policy evaluation or business validation.
- Treating an open extension PR as network-wide approval, or assuming merging a policy immediately deploys it to all participants.
- Assuming ION Observability replaces participant logs and monitoring.

## 13. Go-live checklist

**Network identity and scope**

- [ ] ION-approved spec baseline, sector, role and profile identified and pinned.
- [ ] Organization and participant profiles completed in ION Central.
- [ ] Applicable agreement, business verification and conformance gates completed.
- [ ] Approved production endpoints, signing keys, public-key registrations and secret management configured.

**Functionality**

- [ ] Applicable complete order flow tested with an independent counterparty.
- [ ] Catalogue publication/discovery and updates validated for this role.
- [ ] Callback handling, correlation, duplicate detection and retry/error handling validated.
- [ ] Payments, fulfilment, cancellations, support and financial flows validated as required.

**Operations and business launch**

- [ ] Payment/provider, settlement, refund and accounting responsibilities agreed.
- [ ] Seller/serviceability/offer readiness or buyer discovery coverage confirmed.
- [ ] Monitoring, tracing, alerting, escalation and recovery runbooks ready.
- [ ] Transaction/message IDs can be correlated across participant logs, ONIX and available ION Observability views.
- [ ] Applicable policies, rule versions, validation outcomes and enforcement locations are known and tested.
- [ ] Any pilot extension has a documented PR/version, counterparty agreement, compatibility checks and permitted deployment scope.
- [ ] Support contacts and incident-management owners appointed.
- [ ] Controlled production transaction planned with an eligible counterparty.
- [ ] Real transaction verified end to end and any issues recorded and resolved.

### 13.1 After the first live order

Monitor callback timeliness, message failures, order-state divergence, catalogue freshness, support case aging, financial reconciliation outcomes and successful/failed payouts under applicable arrangements. Plan regression tests for release changes and key rotation. Production readiness is a continuing responsibility, not a one-time checkbox.

### 13.2 Troubleshooting with ION Observability and policy evidence

When something fails, **do not assume the network is down**. Follow a repeatable evidence path:

1. Locate the `transaction_id` and the failing action's `message_id` from your application logs.
2. Confirm your application emitted/received the correct message and persisted the intended state.
3. Check local ONIX diagnostics for signing, schema/policy validation, routing, acknowledgement and callback behavior.
4. Where authorized, correlate the same identifiers in ION Observability & Intelligence; distinguish missing telemetry from a missing business event.
5. If the message was rejected, classify the reason: transport/signature, schema, network/sector policy, participant eligibility or business-domain rule.
6. If a callback is missing, check delivery and handler logs at both ends; apply only the documented retry/idempotency behavior.
7. If money or fulfilment differs from the order state, compare participant and payment/logistics provider evidence; use the applicable support/reconciliation/dispute process.
8. Record the root cause, fix, regression test and whether a spec/Policy IRI/extension PR is appropriate.

**Example:** a properly signed and schema-valid request can still be rejected because a relevant eligibility policy fails. The correct fix may be participant configuration or policy inputs, not changing the JSON payload. Conversely, a valid policy decision cannot make an out-of-stock item fulfillable.

---

---

# Part VII — AI-assisted learning and reference directory

## 14. Use ChatGPT or Claude as an integration mentor

This handbook is intended to be uploaded as **one Markdown file**. The prompts below work best when the developer also supplies (or links to) the **approved spec release**, the relevant reference-app files and their own architecture/data model.

### Prompt A — Teach me ION using ordinary REST as a starting point

```text
Act as an ION integration tutor. I understand REST APIs and JSON but I am
new to Beckn and ION. Use the attached ION Developer Integration Handbook.
Start by comparing a normal synchronous REST request with an ION
request -> ACK/NACK -> later on_* callback. Explain where the BNP, SNP,
ONIX, adaptor and Registry sit. Ask me three questions to verify that I
understand the difference before moving on. Do not invent spec fields.
```

### Prompt B — Find my implementation path

```text
Using the attached ION handbook, guide me to a practical build plan.
My role: [BNP/SNP/both].
My starting point: [existing application/new application].
My sector/use case: [e.g., Trade physical product].
My stack and existing services: [describe].
First, assess what I already have and what I must build, separating UI,
business services, catalogue, adaptor, ONIX, callbacks, testing, onboarding
and production operations. Output a staged plan and open questions.
```

### Prompt C — Help me read the YAML correctly

```text
I am looking at the ION specification in Swagger and am confused about
which endpoints I call and which I expose. Using ONLY the attached approved
spec version and the handbook, build a role-specific table with action,
initiator, receiver, ACK behavior, on_* callback, schema file reference,
application handler and test. Clearly mark anything not established by the
provided sources. Do not treat an HTTP ACK as business success.
```

### Prompt D — Walk through a transaction from both ends

```text
Trace one Trade order from catalogue publication and discovery through
select, init, confirm, payment, fulfilment, status, support (if needed),
reconciliation, settlement and rating. For every step show BNP action,
SNP action, ONIX responsibility, internal state/event changes and source
links. Distinguish the happy path, optional branches and not-yet-adopted
features. Avoid fabricated JSON payloads.
```

### Prompt E — Design an adaptor around my existing systems

```text
Here are my existing services, APIs and internal order states: [paste].
Use the ION handbook and approved specs to design the smallest reliable
BNP/SNP adaptor for this application. Identify inbound/outbound protocol
interactions, callbacks, persistence, event queues, idempotency, errors,
security boundaries and data mapping. Challenge any assumption that ONIX
provides business logic. Flag missing schema or policy inputs.
```

### Prompt F — Review my go-live readiness

```text
Act as an independent ION integration reviewer. Review my architecture,
endpoint map, transaction traces, test results and onboarding state against
the attached handbook and the explicitly provided approved ION specs.
Separate: confirmed pass, failed, missing evidence, not applicable and
requires ION decision. Do not issue a certification claim or infer that a
a feature is mandatory or available in production merely because it appears in the specifications.
```

### Prompt G — Explain Rego, policy enforcement and observability

```text
Using this handbook and the linked ION policy/transport sources, explain
schema validation versus policy evaluation versus business decisions.
Show how OPA/Rego may fit and explicitly verify whether a given rule is
actually implemented by our ONIX/runtime configuration. Explain how to
trace one failed message through participant logs, ONIX and ION
Observability & Intelligence using transaction_id and message_id.
Do not invent dashboard URLs, rule files, enforcement locations or errors.
```

### Prompt H — Help me extend ION Specs through a PR

```text
I want to support this new ION use case: [describe]. My role and sector:
[BNP/SNP, sector]. Read the attached handbook and inspect the selected
ION Specs release, existing CRCs, attribute packs, flows, Policy IRIs,
and CONTRIBUTING.md. First try to solve it with existing constructs.
If a gap remains, propose the smallest compatible extension and produce
(a) change rationale, (b) affected repository files, (c) schema/flow/policy
impacts, (d) examples/tests, (e) validation checklist, (f) draft PR text,
and (g) experimental adoption versus published release implications.
Never say that opening or merging a PR alone deploys functionality.
```

### 14.1 Rules for safe AI-assisted work

- Always identify **the exact approved release/commit** and the selected sector/profile.
- Treat this handbook as **educational navigation**, not the schema authority.
- Require the AI to cite source paths and distinguish **documented fact**, **suggested architecture** and **unverified assumption**.
- If the linked source is inaccessible to the AI, provide that file or ask the AI to state the gap rather than guess.
- Do not upload production secrets, private keys, customer personal data, payment credentials or unredacted commercial records.
- Validate generated code and claims using actual tests and the ION team before production use.

## 15. Glossary

| Term | Short meaning |
|---|---|
| ACK / NACK | Immediate protocol acknowledgement or rejection; not the business result |
| Adaptor | Participant-owned integration layer connecting ION messages to application systems |
| BAP / BPP | Beckn buyer-side / provider-side platform roles |
| BNP / SNP | ION Buyer Network Participant / Seller Network Participant |
| Callback (`on_*`) | A separate message carrying the result of a previously initiated protocol action |
| CRC | Catalogue Resource Category |
| ION Central | Participant/organization onboarding and network services portal |
| ION Devlabs | Developer test and validation environment/services |
| ION SATU | Participant-level dispute management portal |
| ONIX | Participant-side protocol/runtime tooling |
| PJP | Licensed payment-service provider |
| Policy IRI | Identifier/reference for applicable policy rules |
| OPA / Rego | Open Policy Agent policy engine / its policy language; actual ION enforcement depends on configuration |
| ION Observability & Intelligence | ION shared network event visibility, diagnostics and reporting services |
| Specification extension / PR | Proposed change to shared schema, flow, attributes or policy submitted through the repository contribution process |
| Registry | Network identity, role, key, endpoint and catalogue-location directory |
| Reconciliation | Two-party agreement of relevant settlement positions; not itself fund transfer |
| SEAM | Settlement assurance mechanism integrated with applicable PJP arrangements |
| TSP | Technology Service Provider |
| Transaction ID / Message ID | Correlate business exchange / identify individual messages, respectively |

## 16. Maintainer notes — confirm before external publication

This document is a **working developer-handbook draft** based on the uploaded ION Technical Overview (18 November 2026), the existing seller-app exploration guide (used only for journey structure), and inspected public ION repositories (21 November 2026). It intentionally does **not** name a specific partner or present pilot-specific assumptions as universal requirements.

ION documentation owners should confirm and maintain:

1. The correct **Release 1 version/tag or commit**, applicable profile matrix, and any published changes or compatibility guidance.
2. Current **Registry, ONIX, catalogue publishing/discovery and message transport** setup guidance for the selected environment.
3. Verified **Postman2Onix** quickstart and supported reference-app features (some post-order flows may be illustrative rather than complete).
4. Required **BNP and SNP conformance tests** and which post-order exchanges are mandatory, conditional or optional for each role and profile.
5. Current **payment/SEAM/PJP**, support, rating and reconciliation production boundaries.
6. Actual **ION Central/Devlabs onboarding workflow** and go-live approval owners.
7. Stable, preferably version-pinned resource links and a change log for this handbook.
8. Actual **OPA/Rego** rule sources, ONIX policy enforcement points, rule versioning, test tools and policy rejection/error behavior.
9. **ION Observability & Intelligence** access model, available event fields, dashboard/tool links, retention, permissions and incident escalation.
10. **Specification-extension adoption policy:** which PRs may be piloted, under what bilateral/network permissions, how review/publication is handled, and how participants enable new rules or packs.

**Working rule:** Explain the construct here. Follow released ION Specs and applicable policies for exact requirements; if the construct is missing, propose a compatible extension and test it within an agreed scope. Use official examples and reference applications to learn how to implement them. Test against a real counterparty before calling an app live.
