# ION — Indonesia Open Network

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE.md)
[![Spec Version](https://img.shields.io/badge/Spec-v0.6.0--draft-orange.svg)](CHANGELOG.md)
[![Beckn](https://img.shields.io/badge/Built%20on-Beckn%20v2.0.0-green.svg)](https://beckn.io)

ION is Indonesia's open digital commerce network. Any buyer app and any seller app on ION can transact with each other — without bilateral integration agreements.

A seller who registers on ION is reachable by every buyer app on the network, across food, grocery, fashion, electronics, beauty, agritech, and the logistics network that moves goods between them.

> **Status.** v0.6.0-draft. Not yet in production. Production launch schedule is set by ION Council.

---

## What this repository is

This repository is the **ION Network Specification** — the single source of truth for how ION works. It contains:

- The schema definitions for every field in every ION message
- The flow specifications for every transaction pattern
- The policy registry that governs commercial terms
- The error registry that defines what ION rejects and why

It is **not** an SDK, a client library, or a running service. It is the spec that all of those are built from.

---

## How ION relates to Beckn

ION is built on top of **Beckn Protocol v2.0.0** — an open protocol for interoperable commerce networks. ION does not fork or modify Beckn. It extends it.

Think of it this way:

```
Beckn Protocol v2.0.0
  └── defines: 30 API endpoints, core data model
       (Contract, Resource, Offer, Commitment, Consideration,
        Performance, Settlement, Provider, Participant...)
       Each core object has an *Attributes slot for extensions.

ION Network (this repo)
  └── extends Beckn with:
       ├── 8 additional endpoints  (/raise family, /reconcile)
       ├── Indonesian network rules  (signing, NPWP, data residency)
       ├── 11 cross-sector attribute packs  (address, identity, payment, tax...)
       └── 18 sector attribute packs  (trade: 8, logistics: 10)
```

The extension mechanism is simple: every ION schema pack declares which Beckn object it extends, using the `x-beckn-attaches-to` annotation. For example:

```yaml
# In releases/release1/extension/trade/TradeResource/v1/attributes.yaml
TradeResource:
  x-beckn-attaches-to: Resource.resourceAttributes
  # ...fields for product type, availability, category-specific attributes
```

This means a Beckn `Resource` object — which has an `id`, a `descriptor`, and a `resourceAttributes` slot — gets ION's trade fields packed into that slot. Beckn stays unchanged. ION adds fields on top.

---

## The two spec files

The two primary API contracts in the Release 1 draft live at:

```
releases/release1/core/api/v2.0.0/ion.yaml
releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml
```

`beckn.yaml` is the candidate vendored copy of Beckn's upstream spec. Its
provenance and transitive dependencies must be completed before Release 1 can be
published.

`ion.yaml` contains ION extensions. References affected by the migration use the
absolute Release 1 `schema.ion.id` namespace so they resolve through the public
proxy and map deterministically back into this repository.

> **You do not need to read `beckn.yaml` unless you are upgrading the vendored Beckn version or debugging a protocol-level issue.** `ion.yaml` is your implementation target.

---

## Repository structure

```
ion-specs/
│
├── releases/release1/          ← Mutable draft until publication
│   ├── core/api/v2.0.0/        ← Native ION API contract
│   ├── common/                 ← Common packs included in the draft
│   ├── extension/trade/        ← Trade packs included in the draft
│   └── vendored/beckn/         ← Release-local upstream dependencies
│
├── schema/extensions/          ← Unmigrated packs awaiting review and mapping
│   ├── core/
│   ├── logistics/
│   ├── hospitality/
│   └── finance/
│
├── flows/                      ← Transaction flow specifications
│   ├── trade/                  ← 12 commerce patterns (storefront, made-to-order, subscription,
│   │                              live-commerce, digital-goods, business-procurement,
│   │                              marketplace-inhouse, marketplace-listed, forward-auction,
│   │                              reverse-auction, cross-border, government)
│   └── logistics/              ← 6 logistics archetypes (parcel, freight...)
│
├── policies/                   ← Machine-readable policy terms (return, cancellation, SLA...)
├── errors/                     ← Error registry (ION-1xxx through ION-9xxx)
└── docs/                       ← Reference documents and developer guides
```

**How the parts connect.** A flow spec in `flows/` references field paths like `message.catalog.resources[].resourceAttributes.food.classification`. That field is defined in `releases/release1/extension/trade/TradeResource/v1/attributes.yaml`. Its commercial terms (what happens if it is wrong) are in `policies/`. The error code if ION rejects it is in `errors/`.

### docs/ — Developer guides vs. internal working documents

**Developer guides** (read these):
- `docs/ION_Bu_Sari_Wizard.md` — Plain-language seller journey; start here if you're new to ION
- `docs/ION_Bu_Sari_Complete_Journey.md` — Technical companion: full API calls and JSON payloads
- `docs/ION_Entity_Hierarchy_Model.md` — Onboarding classification model (sectors, categories, CRCs, patterns)
- `docs/ION_Resource_Categories.md` — Complete CRC reference table (all 46 categories across 6 sectors)
- `docs/ION_Schema_Design_Guide.md` — ION schema design rationale: three-plane model, CRC taxonomy, two-schema split, context engineering posture, and beckn-agents authoring workflow
- `docs/ION_Schema_Style_Guide.md` — Technical file-format rules for schema pack authors (YAML structure, JSON-LD syntax, naming)
- `docs/ION_Release_Architecture.md` — Accepted target architecture for permanent integer releases, release-qualified public schema URLs, and vendored dependencies
- `docs/ION_Transport_and_Signing.md` — HTTP transport layer: Ed25519 signing, body digest, signature verification, Python quickstart. Read this before implementing any endpoint.

**Internal working documents** (for contributors and maintainers):
- `docs/ION_Release1_Migration_Inventory.md` — Working inventory, readiness gates, and staged migration plan for the first permanent integer release
- `docs/ION_Deferred_Issues.md`, `docs/ION_Open_Observations.md`, `docs/ION_Schema_Review_Response.md` — These are not part of the normative spec. They record open items and design decisions in progress.

---

## The five-layer model

ION composes with Beckn in five distinct layers. The table below shows which layer something belongs to and, critically, **whether you as a developer need to read it directly**.

| Layer | What it is | Where it lives | Do you read this? |
|---|---|---|---|
| **L1 — Beckn core** | The upstream protocol: 30 endpoints, core data model, `*Attributes` extension slots. ION never modifies this. | `releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml` | Only when debugging protocol-level issues |
| **L2 — ION network profile** | Network-wide rules: Ed25519 signing, NPWP/NIB mandatory fields, allowed payment rails, data residency Indonesia, 90-day upgrade policy. | `ion.yaml → x-ion-profile block` | Read `docs/ION_Transport_and_Signing.md` for signing; read the mandatory fields table below for field requirements |
| **L3 — ION endpoint extensions** | 8 endpoints that ION adds to Beckn's 30: the `/raise` family for dispute escalation (6 endpoints) and `/reconcile` + `/on_reconcile` for settlement. | `ion.yaml → paths: block` | Read the flow pattern for your sector |
| **L4 — Cross-sector attribute packs** | Fields that apply across every ION sector: Indonesian address format, business identity (NPWP, NIB), payment methods (QRIS, COD, BNPL...), tax (PPN, PPnBM), participant roles, product certifications (halal, BPOM). | `schema/extensions/core/` | Read the pack README for each field you send |
| **L5 — Sector attribute packs** | Fields specific to one sector. Trade packs cover product structure, offers, performance, contracts. Logistics packs cover shipments, rate logic, customs, tracking. | `schema/extensions/trade/` and `schema/extensions/logistics/` | Read the pack README for each field you send |

A concrete example: when a BPP publishes a nasi goreng listing, the catalog message carries:

```
Beckn Resource (L1)
  └── resourceAttributes:
       ├── IONCatalogLocalization  (L4 core/localization)  — name.id: "Nasi Goreng Spesial"
       ├── IONProductCertifications (L4 core/product)     — halalStatus: HALAL
       └── TradeResource  (L5 trade/resource)   — food.classification: HALAL
                                                           — food.spiceLevel: HIGH
                                                           — preparationTime: PT15M
                                                           — availability.status: IN_STOCK
```

---

## What you implement

### If you are a BPP (seller app, merchant platform, LSP)

You implement Beckn's 30 endpoints **plus** ION's 8 extensions. You publish catalogs using the ION schema packs to populate the `*Attributes` fields. You declare policy IRIs from `policies/` on every offer.

**Fast path — trade BPP selling physical goods:**
1. Open `flows/trade/patterns/storefront/v1/README.md` — this is the reference pattern for your integration
2. Open `releases/release1/extension/trade/TradeResource/v1/README.md` — this defines every field in your catalog
3. Open `releases/release1/extension/trade/TradeOffer/v1/README.md` — this defines policy IRIs and offer terms
4. Read `docs/ION_Transport_and_Signing.md` — HTTP signing is required on every request before any other integration work
5. Run `python tools/ion_required_fields.py --sector trade --pattern storefront --crc <your-crc>` to get your mandatory field checklist (see [How to find your required fields](#how-to-find-your-required-fields))

**Fast path — hospitality BPP (food delivery):**
1. Open `flows/hospitality/patterns/delivery-order/v1/README.md` — this is the reference pattern for food delivery
2. Open `schema/extensions/hospitality/delivery/v1/README.md` — this defines every field in your menu
3. Open `schema/extensions/hospitality/fnb-delivery/v1/README.md` — food-and-beverage specific fields

### Mandatory fields that ION Central will reject if missing

The table below covers the most critical regulatory fields. It is a **highlight, not the complete list** — the full mandatory field declaration is in `ion.yaml → x-ion-field-requirements.alwaysRequired`. Your pattern's `pattern.yaml` gives the per-step field list for your specific commerce flow. Check both.

| Field | Payload location | Why mandatory |
|---|---|---|
| `npwp` | `Contract.participants[N].npwp` (direct Participant property) | Indonesian tax law (PMK 112/2022) |
| `nib` | `Contract.participants[N].nib` (direct Participant property) | Business registration (PP 5/2021) |
| `halalStatus` | `Resource.resourceAttributes.halalStatus` | Halal product law (UU 33/2014) — food and beverage |
| `countryOfOrigin` | `Resource.resourceAttributes.countryOfOrigin` | Consumer protection (PerBPOM 31/2018) |
| `ageRestricted` | `Resource.resourceAttributes.ageRestricted` | All products — determines if age verification needed |
| `name.id` | `Resource.resourceAttributes.name.id` | Bahasa Indonesia product name — all products |
| `contactDetailsConsumerCare` | `Offer.offerAttributes.contactDetailsConsumerCare` | Consumer protection (UU 8/1999 Pasal 7) |

### If you are a BAP (buyer app, marketplace, aggregator)

You implement Beckn's 30 endpoints plus the ION extensions that apply to your role. You subscribe to catalogs. You construct `Contract` messages using ION field paths. You render policy terms to consumers.

### If you are building ONIX (the reference implementation)

ONIX handles the transport layer — HTTP signatures, ACK/callback routing, registry integration, `/publish_catalog`, `/subscribe`, schema validation, error formatting. You build on top of it.

---

## How to find your required fields

Knowing which fields are mandatory for your integration requires consulting four sources — none of which points to the others by default. Here is how they relate:

| Source | What it declares | Where it lives |
|---|---|---|
| `ion.yaml → x-ion-field-requirements.alwaysRequired` | Fields always required on every ION transaction, per schema | `releases/release1/core/api/v2.0.0/ion.yaml` |
| `ion.yaml → x-ion-crc-rules` | Fields required only when a resource carries a specific CRC (product category) | Same file |
| `ion.yaml → x-ion-conditional-rules` | Fields required only when a field in a different schema bag has a specific value | Same file |
| `flows/{sector}/patterns/{pattern}/v1/pattern.yaml` | The exact full list of fields ONIX will check at each API step for this specific pattern | e.g. `flows/trade/patterns/storefront/v1/pattern.yaml` |
| `schema/extensions/{pack}/v1/profile.json → minimalForDiscovery` | Minimum fields for a resource to appear in discovery results | Each pack's `profile.json` |

**The `pattern.yaml` for your commerce flow is the primary implementation reference** — it lists every field ONIX validates at each API step. If ONIX rejects your message, the `requiredFields` list in `pattern.yaml` for that step is the first thing to check.

> **Missing `minimalForDiscovery` fields causes silent non-indexing** — your resource is accepted but does not appear in search results. Check each pack's `profile.json` for this list.

---

## Validation and errors

Schema validation at ION Central (ONIX) is **synchronous** — you receive an immediate NACK with an error code if your message is rejected. There is no async callback for schema failures.

- Schema rejections use the `ION-8xxx` code range
- Look up any error code in `errors/registry.json` by the `code` field
- The `resolution.en` field in the entry tells you what to fix
- The `affected_field` field identifies which payload field caused the rejection

See `errors/README.md` for the full code range reference.

---

## Transaction lifecycle

A standard B2C purchase on ION:

```
Phase 1 — Catalog (async, BPP pushes, BAP subscribes)
  BPP publishes catalog → ION Catalogue Service
  BAP subscribes → receives /on_discover callbacks

Phase 2 — Transaction (direct, BAP ↔ BPP)
  BAP → /select   → BPP → /on_select    (pick items, get quote)
  BAP → /init     → BPP → /on_init      (delivery address, payment method)
  BAP → /confirm  → BPP → /on_confirm   (binding order, contract created)
  BPP → /on_status (×N, unsolicited)    (PACKED → DISPATCHED → DELIVERED)

Phase 3 — Post-fulfilment
  BAP → /rate     → BPP → /on_rate      (ratings)
  BAP → /reconcile → BPP → /on_reconcile  (ION extension: settle financials)
  BAP or BPP → /raise → ION             (ION extension: escalate if needed)
```

See `flows/trade/patterns/storefront/v1/pattern.yaml` for the full field-by-field breakdown of every step.

---

## Start here by role

**I'm new to ION and need to understand where my business fits:**
1. Read `docs/ION_Bu_Sari_Wizard.md` — a plain-language walkthrough of a pharmacy joining ION. All hierarchy layers in practice.
2. Read `docs/ION_Entity_Hierarchy_Model.md` — the formal model: sectors, categories, CRCs, patterns
3. Read `docs/ION_Resource_Categories.md` — find the right category code for your product or service
4. Read this README fully
5. Read `schema/core/v2/api/v2.0.0/README.md` — the two-file spec model explained

**I'm a developer building a trade BPP (most common — physical goods seller):**
1. Open `flows/trade/patterns/storefront/v1/README.md` — start here
2. Open `releases/release1/extension/trade/TradeResource/v1/README.md` — your catalog fields
3. Open `releases/release1/extension/trade/TradeOffer/v1/README.md` — your offer terms and policy IRIs
4. Read `schema/extensions/README.md` — how attribute packs work
5. Run the required-fields tool for your CRC (see above)

**I'm a developer building a hospitality BPP (food delivery):**
1. Open `flows/hospitality/patterns/delivery-order/v1/README.md` — start here
2. Open `schema/extensions/hospitality/delivery/v1/README.md` — your menu fields
3. Read `schema/extensions/README.md` — how attribute packs work

**I'm a developer building a BAP or marketplace:**
1. Read this README fully
2. Read `schema/core/v2/api/v2.0.0/README.md` — the two-file model explained
3. Pick your commerce pattern: `flows/trade/README.md` or `flows/logistics/README.md`
4. Open the pattern for your scenario and read it step by step

**I already know Beckn:**
1. Read `schema/core/v2/api/v2.0.0/README.md`
2. Read `schema/extensions/core/README.md` — what L4 adds to Beckn
3. Pick your sector: `schema/extensions/trade/README.md` or `schema/extensions/logistics/README.md`

**I want to contribute a new schema field or product example:**
1. Read `docs/ION_Schema_Design_Guide.md` — ION-specific design principles, the three-plane model, CRC taxonomy, two-schema split, and beckn-agents workflow
2. Read `docs/ION_Schema_Style_Guide.md` — file format rules
3. Read `docs/ION_Bu_Sari_Complete_Journey.md` to understand what real payloads look like
3. Find the right pack in `schema/extensions/`
4. Follow the contribution workflow in `CONTRIBUTING.md`

**I want to understand a specific error:**
1. Look up the error code in `errors/registry.json`
2. The entry references the schema field (`schema_ref`) and the flow step (`flow_ref`) where it applies

---

## Active sectors

| Sector | Covers | Schema | Flows |
|---|---|---|---|
| **Trade** | B2C, B2B, marketplace, subscription, auction, cross-border, government procurement | `schema/extensions/trade/` | `flows/trade/` |
| **Logistics** | Hyperlocal, parcel, freight, Ro-Ro, cross-border, warehousing | `schema/extensions/logistics/` | `flows/logistics/` |
| **Hospitality** | Food delivery and online ordering (`HSC-delivery`) — partial activation | `schema/extensions/hospitality/` | `flows/hospitality/` |

Mobility, finance, tourism, and healthcare are reserved. Other Hospitality CRCs (accommodation, restaurant table, events, wellness) are reserved until their working groups ratify.

**Food classification rule:** Restaurant meals and food delivery apps (GoFood, GrabFood, any prepared-to-order food) → **Hospitality** (`HSC-delivery`, `delivery-order` pattern). Packaged food products sold on e-commerce (Indomie, bottled water, protein powder) → **Trade** (`TRC-food-bev`, `storefront` pattern). The test: is the item made fresh after the order? If yes → Hospitality.

---

## Policy registry

Sellers declare policy intent using IRIs — compact identifiers that resolve to ratified terms documents. ION Central validates and enforces them.

```yaml
# Example: a trade offer's policy declarations
offerAttributes:
  policies:
    returns:
      policyRef: ion://policy/return.standard.7d-sellerpays
    cancellation:
      policyRef: ion://policy/cancel.prepacked.free
    warranty:
      policyRef: ion://policy/warranty.manufacturer.1y-distance-service
    dispute:
      policyRef: ion://policy/dispute.consumer.bpsk
    grievanceSla:
      policyRef: ion://policy/grievance-sla.consumer.standard
    paymentTerms:
      policyRef: ion://policy/payment-terms.upfront.full
```

Each IRI resolves to a YAML document in `policies/` that defines the window, fee structure, and enforcement behaviour. ION Central rejects catalogs with unknown IRIs and rejects runtime actions that violate declared terms.

To find the right IRI for your use case, open `policies/README.md` — it lists every available IRI grouped by category.

---

## Versioning

ION versions follow `MAJOR.MINOR.PATCH-STAGE`. Implementations receive **90 days' notice** before any mandatory upgrade. Notice is published in `CHANGELOG.md` and broadcast to registered network participants via ION Council announcements. Watch this repository and `CHANGELOG.md` for version announcements.

Current: **v0.6.0** — targeting Beckn `core-v2.0.0`. See [CHANGELOG.md](CHANGELOG.md) for what is in this release.

---

*ION Network Specification — Indonesia Open Network*
