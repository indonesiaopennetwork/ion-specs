# ION Schema Design Guide

> **Release 1 scope note:** Release 1 publishes standalone Trade and required
> common packs only. This guide also discusses the unreleased `ion.yaml`
> aggregate and future sectors as design inputs; those sections are not part of
> the normative Release 1 contract.

**Audience:** Contributors authoring or reviewing schema packs, flow patterns, or `ion.yaml` changes.  
**Relationship to NFH-012:** This document does not replace NFH-012. It translates NFH-012's three design principles into ION-specific terms, adds the ION structural constraints that sit above NFH-012, and gives contributors the decision framework for choices that NFH-012 leaves open.

Read this document before authoring. Read `docs/ION_Schema_Style_Guide.md` for file-format rules.

---

## 1. Why ION needs its own design guide

NFH-012 governs the Beckn schema layer across the entire ecosystem — retail networks in the UAE, energy grids in India, mobility networks globally. Its three principles (Semantic Invariance, Unification over Standardization, Agent-First Design) apply universally.

ION sits on top of that. It inherits all of NFH-012's constraints and adds three ION-specific structures that NFH-012 cannot anticipate:

1. **The three-plane model** — ION classifies every aspect of network participation across three planes (business/policy, catalogue, protocol/technical), each with its own governance. Schema contributions must respect these plane boundaries.

2. **The CRC taxonomy** — ION's Catalogue Resource Category system classifies every product and service into one of 46 named categories. CRCs drive which fields are conditionally required. This has direct consequences for schema design that NFH-012 — which is domain-agnostic — cannot address.

3. **The two-schema split** — ION's pattern of separating a generic, network-agnostic layer from an Indonesia-specific layer within every sector schema. This is an ION architectural decision that emerged from the need to maintain upstream compatibility while carrying Indonesian regulatory requirements.

This guide covers these three structures and their implications for schema authoring. NFH-012 covers everything else.

---

## 2. NFH-012 principles in ION context

### Principle 1: Semantic Invariance — what it means for ION

A schema term means the same thing everywhere on the ION network. `halalStatus` on a `TradeResource` means the same thing whether the catalog is published by a merchant in Surabaya or Jakarta. The Indonesian-specific *regulatory enforcement* of halal certification (UU 33/2014) is a **policy-layer** concern, not a schema-layer concern. The meaning of the term is invariant.

The practical implication for ION contributors: **never create a field whose meaning depends on which region, city, or network participant is reading it.** If a field means something different in different contexts, it belongs in two separate fields with distinct, context-free meanings — or it belongs in policy, not in the schema.

Common violation: adding `provinsiCode` as a field whose *interpretation* varies by province. The field meaning is invariant (2-digit BPS province code); what changes per province is the regulatory policy that references it.

### Principle 2: Unification over Standardization — what it means for ION

ION does not pre-emptively standardize narrow schemas. The right move, when a new use case appears, is always to ask: can this use case be expressed by making an existing schema more general?

ION-specific translation: **the CRC taxonomy is not a schema taxonomy.** CRCs classify what products exist; they do not dictate that each CRC needs its own schema. The trade sector's approach — one `TradeResource` schema with CRC-conditional field blocks — is the correct expression of this principle. A contributor who proposes a separate `FashionResource` schema because the fashion CRC has fashion-specific fields is working against unification.

When CRC-specific fields genuinely form a distinct semantic cluster that does not share meaning with other CRCs, a sub-object within the existing schema is appropriate (e.g. `fashion`, `food`, `electronics` blocks within `TradeResource`). A new top-level schema is not.

### Principle 3: Agent-First Design — what it means for ION

ION schemas are read by AI agents — both the agents operating on the ION network (buyer apps, recommendation engines, catalogue indexers) and the AI tools used to author and validate schemas (beckn-agents skills). This principle drives two things:

**Schemas must be designed for AI agents.** Field descriptions must be prose that an agent can use to understand the concept without any other context. CRC codes, regulatory references, and business rules should be explained in the description, not assumed as shared knowledge.

**Schemas must be designed with AI agents.** The beckn-agents skills are the ION implementation of the "AI as primary authoring instrument" posture. Using them is not optional for non-trivial contributions. See Section 5 for the ION-specific authoring workflow.

---

## 3. The three-plane model and its schema implications

Every aspect of ION participation belongs to one of three planes. Schema contributions must understand which plane they are in, because the design rules differ.

```
─────────────────────────────────────────────────────────────────────
  PLANE 1: BUSINESS / POLICY COMPLIANCE
  Governed by: Indonesian regulation + ION governance policy
  Schema home: L4 core packs (core/identity, core/participant, core/address)
─────────────────────────────────────────────────────────────────────
  Who is this participant? What are they permitted to do?
  NPWP, NIB, PKP status, legal entity type, data residency, KBLI codes.
  Fields here are mandatory network-wide regardless of sector.
  Regulatory basis is always cited (PMK 112/2022, PP 5/2021, UU 27/2022).

─────────────────────────────────────────────────────────────────────
  PLANE 2: CATALOGUE
  Governed by: ION Sector Working Groups
  Schema home: L4 core/product, L5 sector resource packs
─────────────────────────────────────────────────────────────────────
  What does this participant sell or offer?
  CRC classification, category-specific attributes (food, fashion, electronics),
  halal status, BPOM registration, SNI certification, country of origin.
  Fields here are mandatory per CRC — declared in x-ion-crc-rules, not in the schema.

─────────────────────────────────────────────────────────────────────
  PLANE 3: PROTOCOL / TECHNICAL COMPLIANCE
  Governed by: Beckn Protocol v2.0 + ION extensions
  Schema home: L5 sector offer, commitment, consideration, performance, contract packs
─────────────────────────────────────────────────────────────────────
  How does this participant transact?
  Performance states, delivery modes, payment rails, cancellation windows,
  AWB numbers, tracking URLs, reconciliation amounts.
  Fields here are mandatory per pattern step — declared in pattern.yaml.
```

### What goes wrong when planes mix

**Plane 1 fields in a sector schema.** NPWP and NIB are Plane 1 fields. They belong in `core/identity/v1` and `core/participant/v1`, not in `trade/resource/v1`. A contributor who adds `npwp` to `trade/contract/v1` thinking "contracts need tax IDs" is mixing planes. The correct approach: `core/identity/v1` declares the NPWP field; `trade/contract/v1` references the participant who holds it via a participant ID.

**Plane 2 fields in Plane 1 packs.** Halal certification is a Plane 2 (catalogue) field. It belongs in `core/product-compliance/v1` and `trade/resource/v1`, not in `core/participant/v1`. A participant's halal *licence* belongs in Plane 1 (who are they). A product's halal *status* belongs in Plane 2 (what do they sell). These are different fields.

**Plane 3 fields treated as Plane 2.** The performance mode (DELIVERY vs SELF_PICKUP) is a Plane 3 field — it is a transaction-time decision made per order, not a catalogue-level product attribute. A contributor who adds `deliveryMode` to `trade/resource/v1` is making a Plane 3 field appear as a Plane 2 field. The correct home is `trade/performance/v1`.

---

## 4. The CRC taxonomy as a schema design input

The ION Catalogue Resource Category system assigns every product or service to one of 46 CRCs (defined in `ion.yaml → x-ion-crc-registry`). CRCs are ION's answer to the question "what kind of thing is this?" They sit in the catalogue plane.

### How CRCs drive schema design

A CRC is not a schema. A CRC is a *classification* that tells ONIX which field blocks to require. The relationship is:

```
CRC: TRC-food-bev
  → triggers x-ion-crc-rules entry
  → requires: food.*, packaged.*, regulatory.*
  → enforced by ONIX at catalog/publish time
  → NOT expressed as required: in the schema
```

This means schema contributors designing a new field block should ask: **which CRCs will trigger this block?** If the answer is "all of them" — the field belongs in the base schema as an always-required field. If the answer is "just electronics CRCs" — the field belongs in the `electronics` sub-object and a new rule in `x-ion-crc-rules`.

### CRC alignment review

When proposing a new pack or field, contributors must declare in their Discussion:
- Which CRC(s) this field serves
- Whether an `x-ion-crc-rules` entry is needed
- Whether the `minimalForDiscovery` array in `profile.json` should include it

A field added to a schema without a corresponding CRC entry or an always-required declaration is invisible to ONIX and will not be enforced. This is one of the most common silent errors in schema contributions.

### CRCs are not schema names

This bears repeating: `TRC-fashion` is a CRC, not a schema. `FashionResource` is not a valid schema name — `TradeResource` with a `fashion` sub-object is the correct pattern. The CRC lives in the resource's `crc` field at runtime. It does not change what schema the resource uses.

---

## 5. The two-schema split

Every L5 sector schema that attaches to a Beckn core object follows the two-schema split pattern:

```
Generic layer (e.g. TradeResource)
  └── inherits from upstream beckn.io/schema parent
  └── carries fields that are meaningful outside Indonesia
  └── no Indonesia-specific regulatory fields
  └── additionalProperties: true

ION-specific layer (e.g. IONTradeResource)
  └── inherits from generic layer via allOf
  └── carries Indonesia-specific regulatory and compliance fields
  └── this is the layer profile.json points to
  └── this is the layer x-ion-crc-rules references
```

### Why this split exists

ION needs to be both a conformant Beckn network and an Indonesia-specific regulatory environment. The generic layer satisfies Beckn conformance — it is a schema that any Beckn participant could understand without knowing anything about Indonesia. The ION-specific layer carries the fields that Indonesian law requires and that make no sense outside that context.

This also preserves upstream compatibility. When schema.beckn.io publishes a new version of `RetailResource`, ION updates the generic layer's parent reference without touching the ION-specific layer.

### Applying the split to a new schema

When authoring a new pack:

1. **Define the generic layer first.** Ask: what fields would a non-Indonesian Beckn network need from this schema? Put only those in the generic layer.

2. **Define the ION-specific layer second.** Ask: what does Indonesian law, ION governance, or Indonesian market convention require that is not in the generic layer? Put those in the ION-specific layer.

3. **Name correctly.** The generic layer uses a domain-neutral name (`TradeResource`, `LogisticsResource`). The ION-specific layer prefixes with `ION` (`IONTradeResource`, `IONLogisticsResource`). Do not use `ION` prefix on the generic layer.

4. **Do not leak.** Indonesia-specific fields (NPWP, Halal certification, BPOM numbers, provinsiCode) must not appear in the generic layer even if they seem like "useful global information." They are Indonesia-specific by nature.

### Exception: ION-native schemas

Some schemas have no meaningful generic layer because they model concepts that exist only in the ION context. Examples: `IONReconcile` (ION's settlement reconciliation protocol), `IONTicket` (ION's network dispute mechanism), `IONTax` (Indonesian PPN/PPnBM regime). These are ION-native and do not require a split. They are identified in `ion.yaml → x-ion-schema-dependencies` with status `ION_NATIVE`.

---

## 6. Extension zones

Every `*Attributes` bag on ION is divided into four zones. Contributors must understand which zone their fields belong in.

### Zone 1: beckn_defined
`@context` and `@type`. Governed by `beckn.yaml`. Never add fields here.

### Zone 2: ion_mandated
ION core and sector fields. This is where schema pack fields live. Governed by `ion.yaml` and the schema packs in `schema/extensions/`. Fields here use the `ion:` IRI prefix.

### Zone 3: participant_extensions
NP-declared fields that a specific network participant needs but that are not standardised across ION. Governed by the participant. Rules:
- Maximum 10 fields per bag
- Must use the participant's own IRI prefix (e.g. `acme:fieldName`) — never `ion:` or `beckn:`
- Not validated by ONIX
- Not visible to other participants unless they resolve the IRI

Schema contributors should never put fields in Zone 3. If a field is needed by more than one participant, it belongs in Zone 2 via a schema pack contribution.

### Zone 4: experimental
Pilot fields proposed by a Sector Working Group (SWG) that are not yet ratified. Rules:
- Must carry `x-ion-experimental: true` in the schema definition
- Auto-expire after one ION release cycle if not ratified
- Governed by the relevant ION Sector Working Group

New fields in an experimental state go into Zone 4 in `ion.yaml` with the SWG's endorsement. Once ratified through the contribution process, they move to Zone 2 in a schema pack.

---

## 7. Context engineering posture

NFH-012 Section "Context Engineering" establishes that schema design is context engineering at the protocol layer. ION operationalises this through a concrete rule for where information lives:

**`Descriptor` carries the bulk of semantic meaning. `Attributes` carries only what machines must act on structurally.**

In ION terms:
- Product description, usage instructions, marketing copy, origin story → `Descriptor.longDesc`
- Product images, demo videos, datasheets → `Descriptor.mediaFile[]` and `Descriptor.docs[]`
- Facts that ONIX filters on (status codes, classification codes) → `Attributes` as structured fields
- Facts that participate in arithmetic (price, weight for shipping) → `Attributes` as typed numerics
- Facts that cross-reference other resources (coveredResourceId, compatibleWith) → `Attributes` as ID references
- Everything else → `Descriptor.longDesc` prose

### The ION test for a new structured field

Before adding a structured field to a schema pack, apply this test:

> "If a BAP's AI agent reads the `longDesc` and looks at the `mediaFile[]` images, would it still need this field in structured form to do its job correctly?"

If the answer is no — the information is already accessible from `Descriptor` in a form an agent can process — demote the field to prose in `longDesc`. If the answer is yes — the field participates in ONIX filtering, arithmetic, or cross-resource reference — keep it as a structured field.

Reviewers will apply this test to every new structured field proposed. Fields that fail it will be returned with a request to move the content to `Descriptor`.

---

## 8. The beckn-agents authoring workflow for ION

This section makes the beckn-agents skills concrete for ION contributions. It expands on the brief workflow in `CONTRIBUTING.md`.

### Phase 1: Concept and placement (before opening a Discussion)

Use the `beckn-schema-builder` skill to:

1. **Locate the concept in the three-plane model.** Describe what you are trying to model. The skill will suggest which plane it belongs to and which layer (L4 vs L5).

2. **Check for existing coverage.** Describe the fields you need. The skill will search for existing ION schemas that might already cover them and surface candidates you may not have found manually.

3. **Identify the upstream parent.** For L5 schemas, the skill will suggest the most specific upstream parent from `schema.beckn.io` and propose the generic-layer + ION-specific-layer split.

Record the skill's output and your curatorial decisions in your Discussion thread. Reviewers will want to see this reasoning.

### Phase 2: Naming and description authoring

Use the `beckn-schema-builder` naming workflow:

```
Prompt template for schema naming:
"I am authoring an ION schema for [concept]. It belongs to the [trade/logistics/core]
sector at L[4/5]. It attaches to [Beckn object]. Suggest a name following ION
conventions: 1-2 words, PascalCase, no generic Beckn suffixes, industry-standard
terminology preferred. Provide 3 candidates with provenance for each."
```

For descriptions:

```
Prompt template for descriptions:
"Write a description for the ION schema [SchemaName] that:
1. Names the real-world concept this schema models
2. States which actor produces it and which consumes it
3. States where in the ION value-exchange lifecycle it appears
4. States its relationship to [parent schema / related schemas]
5. Does not use structural restatements ('an object containing...')
6. Does not assume knowledge of Indonesian regulation without citing the law
The description should be readable by an AI agent encountering this schema
for the first time, with no other context."
```

The human curator's job after receiving these outputs:
- Verify the name against ION naming conventions and the CRC taxonomy
- Verify the description is accurate to the regulatory context (the skill may not know the specific Indonesian law)
- Check the description against existing schema descriptions in the repo for vocabulary consistency

### Phase 3: Structural validation

Use the `beckn-payload-builder` skill to validate your `examples/` JSON. Paste the example and ask the skill to check:
- `@context` is a single string URL in every `*Attributes` bag
- No `@context`/`@type` on core objects
- All field names are in `lowerCamelCase`
- All enum values are in `SCREAMING_SNAKE_CASE`
- No `items[]` or `fulfillments[]` legacy terms
- The example is consistent with `x-ion-crc-rules` for the CRC the example uses

### Phase 4: Review preparation

Before raising your PR, use `beckn-schema-builder` to run the schema pack through its validation checklist. The skill will surface:
- Missing `rdfs:subClassOf` or `skos:broader` linkages
- Missing `@version: 1.1` or `@protected: true` in `context.jsonld`
- `required:` arrays that should be in `ion.yaml` policy instead
- Field descriptions that are structural restatements rather than semantic prose

Document which skill checklist items were flagged and how you resolved them. This goes in the PR description.

---

## 9. Decision tree for common authoring questions

### "Should this be a new pack or an extension to an existing pack?"

```
Does an existing pack cover the same Beckn object (Resource, Offer, etc.)
in the same sector?
  YES → Add an optional field to the existing pack (minor version bump)
  NO  → Does a pack in an adjacent sector cover a superset of this concept?
    YES → Abstract upward: extend the adjacent pack or propose a new L4 core pack
    NO  → Is this concept genuinely new with no overlap to existing packs?
      YES → Propose a new pack (follow the Discussion → PR process)
      NO  → Reconsider — the overlap means you need to extend, not create
```

### "Should this field be in the generic layer or the ION-specific layer?"

```
Would a non-Indonesian Beckn network find this field meaningful?
  YES → Generic layer
  NO  → Is it required by Indonesian law or ION governance policy?
    YES → ION-specific layer, cite the regulation in x-ion-regulatory annotation
    NO  → Is it a market convention specific to Indonesia?
      YES → ION-specific layer, document the market rationale in README.md
      NO  → Reconsider whether this field belongs in the schema at all
```

### "Should this field be structured or go in longDesc?"

```
Does ONIX need to filter, sort, or validate this field at the protocol layer?
  YES → Structured field in Attributes
  NO  → Does this field participate in arithmetic (price, weight, duration)?
    YES → Structured field in Attributes
    NO  → Does this field reference another resource by ID?
      YES → Structured field in Attributes (ID reference)
      NO  → Move to Descriptor.longDesc (or mediaFile/docs if it's media)
```

### "Which layer — L4 core or L5 sector?"

```
Does this field apply to more than one ION sector?
  YES → L4 core (schema/extensions/core/)
  NO  → L5 sector (schema/extensions/{sector}/)

Note: "might apply to another sector in the future" is not sufficient for L4.
L4 is for fields that genuinely apply now, across active sectors.
```

---

## 10. Relationship to NFH-012 by conformance requirement

For each NFH-012 conformance requirement (CON-012-xx), here is the ION-specific operationalisation:

| NFH-012 requirement | ION operationalisation |
|---|---|
| CON-012-02 — required artifact files | Seven files required per pack. See `docs/ION_Schema_Style_Guide.md` §2. |
| CON-012-18 — no mandatory fields in schema | Mandatoriness declared in `ion.yaml → x-ion-field-requirements` (always-required) or `x-ion-crc-rules` (CRC-conditional). Schema `required:` arrays are only permitted on Action schemas and within sub-object internal constraints. |
| CON-012-22 — `@context` as single string | The ION network publishes a single composed context document per sector. The wire always carries one URL. Multi-context composition happens in the published document, not in the payload. |
| CON-012-27 — AI-first design + vocabulary linkages | Every ION-specific class in `vocab.jsonld` must have `rdfs:subClassOf beckn:{parent}` or `skos:broader beckn:{parent}`. beckn-agents skill validation checks this. |
| CON-012-28 — thin Attributes, dense Descriptor | Apply the ION structured-field test in Section 7. Reviewers will reject new structured fields that fail it. |
| CON-012-29 — context engineering precedence | ION's `Descriptor` is designed as a map of where the product lives (media URLs, datasheets, social handles) not as a verbose database label. Schema contributions must leave good homes for `mediaFile[]` and `docs[]` content. |

---

## Summary: the ION schema author's decision sequence

1. **Locate in the three-plane model.** Which plane does this belong to? Business/policy → L4 core identity or participant. Catalogue → L4 core product or L5 sector resource. Protocol/technical → L5 sector offer/performance/contract.

2. **Check the CRC taxonomy.** For catalogue-plane contributions: which CRCs does this serve? What goes in the schema vs what goes in `x-ion-crc-rules`?

3. **Apply the two-schema split.** Separate generic (network-agnostic) from ION-specific (Indonesia-regulatory). Name accordingly.

4. **Apply the context engineering test.** For each candidate structured field: does ONIX need to act on this structurally, or does it belong in `Descriptor`?

5. **Use beckn-agents.** Author names, descriptions, and vocabulary linkages with the `beckn-schema-builder` skill. Validate examples with `beckn-payload-builder`. Document curatorial decisions.

6. **Check NFH-012 compliance.** CON-012-18, CON-012-22, CON-012-27, CON-012-28, CON-012-29 are merge gates.

7. **Follow the contribution process.** Discussion → self-review checklist → PR. See `CONTRIBUTING.md`.
