# ION Schema Style Guide

Authoritative conventions for pack authors. All contributions must follow this guide.

## 1. Layer model reminder

| Layer | Location | What goes here |
|---|---|---|
| L1 | `beckn.yaml` (external) | Beckn core — never modified |
| L2 | `releases/release1/core/api/v2.0.0/ion.yaml` | ION network profile overlay |
| L3 | `releases/release1/core/api/v2.0.0/ion.yaml` → `paths:` block | `/raise` family (6 endpoints) + `/reconcile` + `/on_reconcile` |
| L4 | `schema/extensions/core/*/v1/` | Cross-sector attribute packs |
| L5 | `schema/extensions/{trade,logistics}/*/v1/` | Sector-specific attribute packs |

## 2. Required files per pack version

Every `vN/` folder must contain all of these:

```
attributes.yaml    ← Primary source of truth (OpenAPI 3.1.1)
schema.json        ← JSON Schema mirror (generated)
context.jsonld     ← JSON-LD context (@protected:true required)
vocab.jsonld       ← RDF vocabulary
profile.json       ← Attachment metadata
renderer.json      ← UI rendering hints
README.md          ← Property table
```

The parent concept folder (above `vN/`) must also have a `README.md` version-index table.

## 3. attributes.yaml rules

### info block (required)
```yaml
info:
  title: "ION {Domain} {Concept} Extension (v{N})"
  description: "..."
  version: 1.0.0
  license:
    name: Apache-2.0
    url: https://www.apache.org/licenses/LICENSE-2.0
  contact:
    name: ION Network
    url: https://schema.ion.id
```

### Schema object annotation (required)
Every main schema object must carry:
```yaml
x-jsonld:
  '@context': ./context.jsonld
  '@type': ion:SchemaName
x-beckn-attaches-to: BecknObject.attributesSlot
```

### Legal x-beckn-attaches-to values
- `Resource.resourceAttributes`
- `Offer.offerAttributes`
- `Contract.contractAttributes`
- `Commitment.commitmentAttributes`
- `Consideration.considerationAttributes`
- `Performance.performanceAttributes`
- `Settlement.settlementAttributes`
- `Provider.providerAttributes`
- `Participant (direct properties)` — **Exception:** Beckn v2.0 `Participant` has no `participantAttributes` wrapper. Participant fields attach as direct properties on the `Participant` object. Use `x-beckn-attaches-to: Participant (direct properties — no participantAttributes wrapper)`.
- `Tracking.trackingAttributes`
- `RatingInput.target.targetAttributes`
- `Support.channels[*]` (array slot — use @type discriminator)

### allOf with Beckn Attributes base (required)
```yaml
allOf:
  - $ref: https://schema.ion.id/releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml#/components/schemas/Attributes
```

**Never use the external GitHub URL.** Always use the local relative path.

### additionalProperties
Set `additionalProperties: true` on all extension bags (allows NPOS overlay schemas).
Add `x-ion-closed-extensions: false` to document this is intentional.

### Conditional requirements
For conditions within the same schema, use JSON Schema `if/then/else`:
```yaml
- if:
    properties:
      ageRestricted:
        const: true
    required: [ageRestricted]
  then:
    required: [minAge]
```

For cross-schema conditions (trigger field in a different schema bag), add a rule to the `x-ion-conditional-rules:` block in `ion.yaml`. ONIX reads this block and enforces the rule at every API boundary.

## 4. context.jsonld rules

```json
{
  "@context": {
    "@version": 1.1,
    "@protected": true,
    "ion": "https://schema.ion.id/{domain}/{concept}/v{N}#",
    "beckn": "https://spec.beckn.io/vocab/v2.0.0#",
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "schema": "https://schema.org/",
    "SchemaName": "ion:SchemaName",
    "fieldName": "ion:fieldName"
  }
}
```

`@protected: true` is mandatory. All four standard prefixes (`rdf`, `rdfs`, `xsd`, `schema`) must be present.

## 5. vocab.jsonld rules

Every class and property needs a full `rdfs:comment` (not truncated):

```json
{
  "@graph": [
    {
      "@id": "ion:SchemaName",
      "@type": "rdfs:Class",
      "rdfs:label": "Schema Name",
      "rdfs:comment": "Full description from attributes.yaml"
    },
    {
      "@id": "ion:fieldName",
      "@type": "rdf:Property",
      "rdfs:label": "fieldName",
      "rdfs:comment": "Full field description"
    }
  ]
}
```

## 6. profile.json rules

Required fields:
```json
{
  "id": "ion-{domain}-{concept}-v{N}",
  "version": "1.0.0",
  "domain": "{domain}",
  "type": "AttributePack",
  "name": "ION {Domain} {Concept} Extension (v{N})",
  "packSchema": "./schema.json",
  "jsonldContext": "./context.jsonld",
  "extends": "beckn:{BecknObject}",
  "attachmentPoints": { "slotName": ["SchemaName"] },
  "indexing": {
    "indexable": [{"path": "$.fieldName"}],
    "filterable": [{"path": "$.fieldName"}],
    "sortable": []
  },
  "minimalForDiscovery": ["fieldName"]
}
```

## 7. renderer.json rules

`renderer.json` gives BAP UI frameworks hints about how to display a schema pack's fields. It is **required in every pack version directory** even when its content is minimal. The validator expects the file to exist; omitting it causes a pack structure failure independent of field content.

Three tiers of detail are recognised, ordered from simplest to most complete:

**Tier 1 — Minimal (use for non-resource packs: offer, commitment, consideration, performance, contract, provider)**

Provides a display label and accent colour for tooling and registry surfaces. All non-resource packs that don't need field-group layouts use this form.

```json
{
  "displayLabel": "{Domain} {Concept}",
  "accentColor": "#RRGGBB",
  "version": "1.0.0"
}
```

- `displayLabel` — human-readable name shown in the ION schema registry and developer tooling. Two words, title case, no "ION" prefix.
- `accentColor` — hex colour used for pack badges in UI. Choose any colour distinct from other packs in the sector. No validation is applied.
- `version` — always `"1.0.0"` for a new pack.

**Tier 2 — Reference (use when no UI field grouping is needed but pack should be schema-discoverable)**

Adds relative references to the pack's other artifacts. Used by packs that expose structured data consumed by tooling rather than rendered directly to end users.

```json
{
  "type": "application/json",
  "schema": "./attributes.yaml",
  "context": "./context.jsonld",
  "vocab": "./vocab.jsonld"
}
```

**Tier 3 — Full (use for resource packs that render directly in BAP catalogue and product-detail UIs)**

Declares `fieldGroups` for UI layout, `badges` for visual indicators, and optionally `displayPreferences` for field formatting. Use this for the sector's primary resource pack — the schema that a BAP renders to consumers in discovery and product-detail views.

```json
{
  "version": "1.0.0",
  "fieldGroups": [
    {
      "id": "basics",
      "label": { "id": "{Bahasa label}", "en": "{English label}" },
      "fields": ["fieldName1", "fieldName2"]
    },
    {
      "id": "optional-group",
      "label": { "id": "{Bahasa label}", "en": "{English label}" },
      "conditional": "{fieldName} != null",
      "fields": ["fieldName3"]
    }
  ],
  "badges": [
    {
      "condition": "{fieldName} == '{VALUE}'",
      "label": { "id": "{Bahasa label}", "en": "{English label}" },
      "color": "#RRGGBB"
    }
  ],
  "displayPreferences": {
    "primaryFields": ["fieldName1"],
    "cardSummaryFields": ["fieldName2"],
    "currencyFields": ["amountField"],
    "percentageFields": ["rateField"],
    "locale": "id-ID",
    "currency": "IDR"
  }
}
```

**Rules:**
- `fieldGroups[].id` — unique within the file, `camelCase`.
- `fieldGroups[].fields` — list of field names as they appear in `attributes.yaml`. For nested fields, use dot notation: `"physical.weight"`. Order determines display order in the UI.
- `fieldGroups[].conditional` — optional. A simple expression evaluated at render time; the group is hidden when false. Use field names from `attributes.yaml` directly.
- `badges[].condition` — simple equality or boolean expression. Do not use complex logic; badge conditions are evaluated client-side by BAP frameworks, not by ONIX.
- `displayPreferences` — optional. Omit entirely if not needed rather than including it with empty arrays.
- All label objects must have at minimum an `"id"` key (Bahasa Indonesia). `"en"` is required for cross-border-pattern packs.

**Which tier to use:**

| Pack type | Recommended tier |
|---|---|
| Sector resource pack (rendered in catalogue / product-detail UI) | Tier 3 |
| Sector offer pack | Tier 1 |
| Sector provider pack | Tier 1 |
| Sector commitment, consideration, performance, contract packs | Tier 1 |
| Core packs (address, payment, participant, tax, etc.) | Tier 1 |
| Any pack where fields are consumed by tooling, not rendered to users | Tier 2 |

A Tier 1 `renderer.json` is always acceptable in place of Tier 3 when the sector is new and UI groupings have not yet been defined. Update to Tier 3 once the sector's first BAP implementation clarifies which groupings are needed.

## 8. Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Concept folder name | `kebab-case` | `participant-logistics` |
| Schema object name | `PascalCase` with domain prefix | `TradeResource` |
| JSON-LD term IRI | `ion:PascalCase` or `ion:camelCase` | `ion:TradeResource` |
| Field names | `camelCase` | `resourceStructure` |
| Policy IRIs | `ion://policy/{cat}.{sub}.{spec}` | `ion://policy/cancel.standard.until-dispatched` |

## 9. context.schemaContext usage

Every API call should populate `context.schemaContext` with the ION extension context URIs relevant to the message:

```yaml
context:
  schemaContext:
    - https://schema.ion.id/releases/release1/extension/trade/TradeResource/v1/context.jsonld
    - https://schema.ion.id/releases/release1/extension/trade/TradeOffer/v1/context.jsonld
    - https://schema.ion.id/releases/release1/common/Payment/v1/context.jsonld
```

This makes every message self-describing and enables deterministic validation at ION Central.
