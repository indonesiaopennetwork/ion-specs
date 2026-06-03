# Contributing to ION Network Specification

This guide is for anyone proposing changes to the ION Network Specification — schema packs, flow patterns, policies, errors, or core `ion.yaml`. Read it fully before opening a pull request. Reviewers use it as the acceptance checklist.

---

## Before you start: understand the two levels of guidance

ION schema design is governed at two levels. Both apply to every contribution.

| Level | Document | Scope |
|---|---|---|
| **Upstream (Beckn)** | NFH-012 Schema Design Guide | Governs all Beckn schema artifacts network-wide. Sets the three design principles: Semantic Invariance, Unification over Standardization, Agent-First Design. |
| **ION-specific** | `docs/ION_Schema_Design_Guide.md` | Translates NFH-012 into ION terms. Covers the three-plane model, the CRC taxonomy as a schema input, the two-schema split pattern, extension zones, and the ION-specific authoring workflow. |
| **Technical format** | `docs/ION_Schema_Style_Guide.md` | File-level rules: YAML structure, JSON-LD syntax, naming conventions, required fields per artifact. |

Read `docs/ION_Schema_Design_Guide.md` and `docs/ION_Schema_Style_Guide.md` before authoring. NFH-012 is the upstream reference for design principles; ION's design guide applies those principles in the ION context.

---

## Contribution types and where they go

| What you're changing | Where | Reviewer |
|---|---|---|
| New schema pack | `schema/extensions/{sector}/{concept}/v1/` | ION Schema Working Group |
| Extending an existing pack | Same directory, new `v2/` if breaking | ION Schema Working Group |
| New flow pattern or variant | `flows/{sector}/patterns/` or `flows/{sector}/variants/` | ION Sector Working Group |
| New policy term | `policies/{category}/v1/` | ION Council |
| New error code | `errors/{category}.yaml` | ION Schema Working Group |
| `ion.yaml` changes (L2/L3) | `schema/core/v2/api/v2.0.0/ion.yaml` | ION Council (L2), ION Schema Working Group (L3 endpoints) |
| Documentation fixes | Any `README.md` or `docs/` file | Any maintainer |

---

## Workflow

### Step 1 — Check if it already exists

Before proposing a new field or schema:

1. Search `schema/extensions/` for an existing pack that covers the use case
2. Check `ion.yaml → x-ion-field-requirements` to see if the field is already declared as always-required somewhere
3. Check whether the use case belongs in an existing pack as an optional field rather than a new pack

**New packs are the last resort.** Try: adding a field to an existing pack → extending an existing pack → then creating a new pack. This mirrors the NFH-012 order of precedence: abstraction → composition → extension → creation.

### Step 2 — Open a Discussion

For any non-trivial change (new pack, new flow pattern, new policy, L2/L3 `ion.yaml` change):

1. Open a GitHub Discussion explaining: the use case, which layer it belongs to, which existing artifacts you considered and why they were insufficient
2. Allow 14 days for community review before proceeding
3. Tag the relevant working group (ION Schema WG for schema packs, ION Sector WG for flow patterns)

Documentation fixes and error code additions may skip the Discussion step.

### Step 3 — Author using the beckn-agents AI toolchain

ION follows NFH-012 Principle 3: **Agent-First Design means AI is the primary authoring instrument.** The human role is curatorial — validating, refining, and enforcing ION-specific constraints on top of AI-generated drafts. The beckn-agents skills are the concrete implementation of this posture for ION.

**For schema pack authoring (new or extended packs):**

Use the `beckn-schema-builder` skill. It enforces:
- NFH-012 naming conventions (no generic suffixes, industry-standard terms)
- Correct two-schema split pattern (generic layer + ION-specific layer)
- Required artifact files and their structure
- `rdfs:subClassOf` / `skos:broader` vocabulary linkages
- No `required:` arrays on Attributes containers (mandatoriness in network policy)
- `@version: 1.1` and `@protected: true` in every `context.jsonld`

Workflow with `beckn-schema-builder`:
```
1. Describe the concept to the skill: what real-world thing does this schema model,
   who produces it, who consumes it, where in the transaction lifecycle does it appear
2. Let the skill propose names, descriptions, vocabulary linkages, and file stubs
3. Curate: validate names against ION conventions, confirm CRC alignment,
   check against the three-plane model (does this belong in L4 core or L5 sector?)
4. Validate descriptions satisfy the Agent-First test:
   can an AI agent understand what this schema models from the description alone,
   without reading any other document?
```

**For payload and example validation:**

Use the `beckn-payload-builder` skill to generate and validate the `examples/` JSON for your pack. It enforces:
- Correct `@context` as single string URL (not array) in `*Attributes` bags
- `resources[]` not `items[]` (Beckn v2 terminology)
- `performance[]` not `fulfillments[]`
- No `@context`/`@type` on core objects (only on `*Attributes` bags and top-level `Contract`)
- `on_confirm` returns `ACTIVE` contract status (not `CONFIRMED`)

**For ONIX configuration validation:**

Use the `beckn-onix-config` skill when your contribution touches `ion.yaml` profile blocks, conformance matrix entries, or conditional rules.

> **Why this matters.** A schema authored without AI tooling tends to reflect the individual author's vocabulary reach and produces descriptions that are developer notes rather than semantic prose. The beckn-agents skills expand that reach systematically and check constraints that are easy to miss manually. Reviewers will ask how you used the skills and what curatorial decisions you made on top of their output.

### Step 4 — Run the self-review checklist

Before raising a PR, complete this checklist. Reviewers will go through the same list.

#### Design checklist

- [ ] I have read `docs/ION_Schema_Design_Guide.md` and can explain which design principle justifies this contribution
- [ ] The contribution follows the order of precedence: I considered extending an existing pack before proposing a new one, and my Discussion documents why extension was insufficient
- [ ] The schema belongs at the correct layer: L4 (cross-sector core) or L5 (sector-specific)
- [ ] If L5: the schema belongs to one sector only — it does not duplicate fields that exist or should exist in L4 core
- [ ] The schema follows the two-schema split: a generic layer inheriting from the upstream Beckn/ION parent, and an ION-specific layer on top
- [ ] The CRC taxonomy has been consulted: the schema's mandatory fields align with `ion.yaml → x-ion-crc-rules` for the CRC(s) this schema serves
- [ ] No `required:` arrays exist on Attributes container schemas — mandatoriness is declared in `ion.yaml → x-ion-field-requirements` or `x-ion-crc-rules`
- [ ] No deeply nested tree structures — descriptive facts live in `Descriptor.longDesc`; `Attributes` carries only facts that participate in arithmetic, filtering, or cross-resource reference

#### Naming checklist

- [ ] Schema name is a noun or noun form, `PascalCase`, 1–2 words
- [ ] No generic Beckn suffixes: not `*Attributes`, `*Resource`, `*Offer`, `*Item`
- [ ] Industry-standard terminology used where it exists — provenance documented in `README.md`
- [ ] `beckn-schema-builder` skill was used to generate and validate naming candidates
- [ ] All property names are `lowerCamelCase`; all enum values are `SCREAMING_SNAKE_CASE`

#### Description checklist

- [ ] Every schema description identifies: the real-world concept, which actor produces/consumes it, where in the value-exchange lifecycle it appears
- [ ] No structural restatements ("an object containing X and Y")
- [ ] No abbreviated developer notes ("masked proxy phone, never real number")
- [ ] Descriptions pass the Agent-First test: an AI agent can understand the concept from the description alone

#### Artifact checklist

- [ ] All 7 required files present: `attributes.yaml`, `schema.json`, `context.jsonld`, `vocab.jsonld`, `profile.json`, `renderer.json`, `README.md`
- [ ] `context.jsonld` has `@version: 1.1` and `@protected: true`
- [ ] `vocab.jsonld` has `rdfs:subClassOf` or `skos:broader` linkage for every ION-specific class
- [ ] `profile.json` has `minimalForDiscovery` array populated
- [ ] `examples/` has at least one complete, valid payload fragment
- [ ] Concept-level `README.md` (parent of `v1/`) updated with version table
- [ ] Versioned `README.md` has: Attaches to, Network-required fields, Used in (flow links), Common rejection reasons, Changelog

#### Beckn v2 terminology checklist

- [ ] `resources[]` used (not `items[]`)
- [ ] `performance[]` used (not `fulfillments[]`)
- [ ] `@context` inside every `*Attributes` bag is a single string URL (not an array)
- [ ] `@context`/`@type` appear only on `*Attributes` bags and top-level `Contract` — not on `Descriptor`, `Location`, `Resource`, `Offer`, `Commitment`, `Consideration`, or `Performance` envelopes
- [ ] All `$ref` to `beckn.yaml` use the local relative path (not the external GitHub raw URL)

#### Flow and policy checklist (if applicable)

- [ ] Pattern README has: API sequence, schema packs table (with links), always-active variants listed, pattern.yaml primary-reference callout
- [ ] Variant README has: "How variant fields layer" note (additive, not replacing)
- [ ] New policy IRI follows the grammar: `ion://policy/{category}.{sector-or-scope}.{variant-name}`
- [ ] `python3 policies/generate_registry.py` passes with no errors

### Step 5 — Raise the pull request

1. Fork the repo and create a feature branch: `git checkout -b feat/my-contribution`
2. Raise a PR against `main` with:
   - A clear title: `[schema] Add trade/bundle-composition/v1` or `[flow] Add logistics/patterns/charter/v1`
   - Link to the Discussion thread
   - A completed self-review checklist (paste it into the PR description and tick boxes)
   - A note on which beckn-agents skills were used and what curatorial decisions you made
3. Await review from the ION Schema Working Group or the relevant sector working group

---

## What reviewers check

Reviewers will verify the self-review checklist above and additionally check:

**Design gate.** Does the contribution follow the order of precedence? Is it at the right layer? Does the Discussion document why existing artifacts were insufficient?

**AI tooling gate.** Is there evidence that beckn-agents skills were used for naming, descriptions, and vocabulary linkages? Reviewers may ask for the prompts used and the curatorial decisions made on top.

**NFH-012 compliance gate.** Reviewers will check CON-012-18 (no mandatory fields in schema), CON-012-27 (rdfs:subClassOf linkages), CON-012-28 (thin Attributes, dense Descriptor), and CON-012-29 (context engineering posture). These are not optional — they are merge gates.

**ION structure gate.** Does the two-schema split follow the established pattern? Is the CRC alignment correct? Does the schema serve a real CRC in `ion.yaml → x-ion-crc-registry`?

**Backward compatibility gate.** If this modifies an existing pack: is the change non-breaking (new optional field → minor version bump) or breaking (field removal, type change, meaning change → major version bump with 90-day deprecation notice)?

---

## Validation commands

```bash
# Validate the ION spec files
spectral lint schema/core/v2/api/v2.0.0/ion.yaml

# Regenerate policy registry after adding a policy
python3 policies/generate_registry.py

# Regenerate error registry after adding an error
python3 errors/generate_registry.py

# Check required fields for your CRC (useful for validating examples/)
python tools/ion_required_fields.py --sector <sector> --pattern <pattern> --crc <crc>
```

All commands must pass before a PR will be merged.

---

## ION-specific constraints not in NFH-012

These are ION additions on top of NFH-012 that every contributor must know:

**The three-plane model.** Schema contributions must specify which plane they serve: business/policy compliance, catalogue, or protocol/technical. A schema that mixes concerns across planes will be rejected. See `docs/ION_Schema_Design_Guide.md`.

**The CRC taxonomy as a design input.** Every L5 (sector) schema that attaches to `Resource.resourceAttributes` must align with the CRC taxonomy in `ion.yaml → x-ion-crc-registry`. The CRC determines which fields are conditionally required. Schema fields that are only meaningful for a specific CRC belong in the `x-ion-crc-rules` block, not as top-level always-required fields.

**The two-schema split.** Every sector schema must follow the generic-layer + ION-specific-layer pattern established in trade and logistics. The generic layer inherits from its upstream Beckn/schema.beckn.io parent. The ION-specific layer adds Indonesia-specific fields via `allOf`. Monolithic schemas that mix generic and Indonesia-specific fields in one object will be rejected.

**Extension zones.** ION defines four zones inside any Attributes bag: `beckn_defined` (`@context`, `@type`), `ion_mandated` (ION core + sector fields), `participant_extensions` (NP-declared fields, max 10, own IRI prefix), `experimental` (SWG pilot fields, must carry `x-ion-experimental: true`). Contributions must respect zone boundaries. See `ion.yaml → x-ion-extension-zones`.

**Data residency.** All ION schemas must include `x-ion-data-residency: ID` annotation on any field that will store personal data about Indonesian individuals. This is a UU 27/2022 PDP Law requirement. The `beckn-schema-builder` skill will prompt for this.

---

## Getting help

- **Schema design questions:** open a Discussion with label `schema-design`
- **Beckn-agents skill issues:** open an Issue with label `ai-tooling`
- **ION Council decisions needed:** open an Issue with label `council-review`
- **NFH-012 interpretation:** the upstream document is at the beckn/protocol-specifications-v2 repo; for ION-specific interpretation, open a Discussion here

---

## Extending an existing sector

This section covers the case where a sector already exists on ION — trade, logistics, hospitality, finance — and you want to add, extend, or correct something within it. The scope of a sector contribution can be as small as adding an optional field to one pack or as large as adding a new CRC with its own schema pack, CRC rule, error codes, and flow pattern.

The distinction from adding a new sector is significant. An existing sector has ratified CRCs, active patterns, and schema packs already in place. Your contribution must fit into that established structure without breaking what is already deployed.

---

### E1. Understand what already exists before proposing anything

Before opening a Discussion, read — in this order:

1. **`schema/extensions/{sector}/README.md`** — sector overview, active packs, and their status.
2. **`flows/{sector}/README.md`** — active patterns, variants, and their windows.
3. **`ion.yaml → x-ion-crc-registry`** — every CRC registered for this sector, its status (ACTIVE/INACTIVE), and which attribute pack it currently points to.
4. **`ion.yaml → x-ion-crc-rules`** — the mandatory field rules per CRC. The fields listed here are enforced by ONIX at `catalog/publish` time even if they are not in the schema's `required:` array.
5. **`ion.yaml → x-ion-field-requirements.alwaysRequired`** — the network-wide mandatory fields that apply to every sector. Do not re-declare these in your sector schema.
6. **`tools/ion_required_fields.py --sector {sector} --pattern {pattern} --crc {crc}`** — run this before proposing new fields. If a field you need is already being enforced by network policy, you do not need to add it to the schema.

If your use case can be addressed by any of the following without authoring a new schema, do that instead:

- Adding an **optional field** to an existing pack (minor version bump, no Discussion required beyond a brief Issue)
- Adding an entry to **`x-ion-crc-rules`** (the field already exists on the schema but is not yet conditionally required for your CRC)
- Adding a **policy IRI** to `policies/{category}/v1/` (your use case is a policy variant, not a data model gap)
- Adding an **error code** to `errors/{sector}.yaml` (a known ONIX rejection case needs a registered code)

Only propose a new pack, a new CRC, or a new pattern when none of the above fits.

---

### E2. Adding an optional field to an existing pack

This is the most common and lowest-friction extension. No new pack, no new CRC, no Discussion required.

**Checklist:**

- [ ] Read the existing `attributes.yaml` for the pack. Confirm the field does not already exist under a different name.
- [ ] Apply the structured-field test (ION\_Schema\_Design\_Guide.md §7): would ONIX need to filter, sort, or arithmetic-operate on this field? If no — move it to `Descriptor.longDesc`.
- [ ] Determine which layer the field belongs on: generic layer (meaningful outside Indonesia) or ION-specific layer (Indonesia-regulatory). See ION\_Schema\_Design\_Guide.md §5.
- [ ] Add the field as optional (no `required:` entry on the schema). If ONIX should enforce it for specific CRCs, add an entry to `x-ion-crc-rules` in `ion.yaml` instead.
- [ ] If the field is Indonesia-specific, add `x-ion-regulatory: {law reference}` as a sibling annotation.
- [ ] If the field stores personal data about Indonesian individuals, add `x-ion-data-residency: ID`.
- [ ] Add the field to `vocab.jsonld` with `rdfs:comment` and either `rdfs:subClassOf` or `skos:broader`.
- [ ] Update `context.jsonld` to map the new field name to its `ion:` IRI.
- [ ] Update the `attributes.yaml` and regenerate or manually update `schema.json` to match.
- [ ] Add or update an example in `examples/` demonstrating the field in use.
- [ ] Update `README.md` — property table and changelog entry.
- [ ] Run `python tools/ion_required_fields.py` and confirm the field appears in the output for its intended CRC or step.
- [ ] Bump the version: `PATCH` for description clarification; `MINOR` for a new optional field.

**Version bump rule:** Never edit a published version directory in place. Create a new versioned directory (`v1.1.0/` alongside `v1.0.0/`) with the updated files.

---

### E3. Adding a new CRC to an existing sector

A new CRC is needed when a product category exists on ION (there is a sector and a category code for it in `x-ion-category-registry`) but has no registered `attributePack` entry in `x-ion-crc-registry`, or the existing pack does not carry the field block the new category needs.

Adding a CRC touches four places atomically. All four must be consistent when the PR is raised:

**Step 1 — Confirm the CRC code exists.**

Look up the CRC code in `ion.yaml → x-ion-crc-registry`. If it is there with `status: ACTIVE` but `attributePack: null`, the CRC exists and needs a pack. If the code is not there at all, you must first register it — this requires an `ion.yaml` L2 change (ION Council approval). Open a Discussion before proceeding.

**Step 2 — Author the schema pack (or extend an existing one).**

If the new CRC can be served by an existing pack with an additional field block (e.g. adding a `mobility` sub-object to `TradeResource` for mobility-adjacent trade), extend the existing pack with a new sub-object. Name the sub-object after the CRC's domain noun, not the CRC code (`mobility` not `MOC-ride`).

If no existing pack can serve the CRC, author a new pack following the full pack authoring process in E4 below.

**Step 3 — Add the `x-ion-crc-rules` entry.**

In `ion.yaml`, add an entry under `x-ion-crc-rules.rules`:

```yaml
- crc: {CRC-code}
  requiredBlocks: [{block-name}]        # sub-objects that must be present
  requiredFields:
    {block-name}: [{field1}, {field2}]  # fields within the block that must be non-null
    root: [{field3}]                    # top-level fields on the resource (if any)
```

Fields listed here are enforced by ONIX at `catalog/publish` time. Do not add them to `required:` on the schema. Test this by running `python tools/ion_required_fields.py --crc {CRC-code}` after the change.

**Step 4 — Update the CRC registry entry.**

In `ion.yaml → x-ion-crc-registry`, update the CRC entry to point to the pack:

```yaml
- code: {CRC-code}
  name: {CRC name}
  sector: {sector}
  status: ACTIVE
  attributePack: schema/extensions/{sector}/{pack}/v1
  requiredSubObject: {block-name-or-null}
```

**Step 5 — Update `profile.json → minimalForDiscovery`.**

If the new CRC requires specific fields for a resource to be indexed and discoverable (not just accepted), add them to `minimalForDiscovery` in the pack's `profile.json`. A resource missing these fields will be accepted by ONIX but will not appear in discovery results — a silent failure that is easy to miss and hard for implementers to debug.

---

### E4. Authoring a new schema pack for an existing sector

When a new pack is genuinely needed (a new CRC with no existing pack, or a new Beckn attachment point not yet covered in the sector), follow this sequence. Every step is a gate — do not move to the next until the current one is complete.

**Phase 1 — Design (before opening a Discussion)**

Use `beckn-schema-builder` (from the `beckn-agents` repo — see Getting help) to:

1. Locate the concept in the three-plane model. Which plane? Which layer (L4 core or L5 sector)?
2. Identify the upstream parent schema at `schema.beckn.io`. The skill will suggest candidates.
3. Determine the two-schema split. What goes in the generic layer (non-Indonesian)? What goes in the ION-specific layer (Indonesian regulation)?
4. Identify which Beckn attachment slot this pack uses (`resourceAttributes`, `offerAttributes`, etc.).

Record all of this reasoning. It goes into your Discussion thread.

**Phase 2 — Discussion (14-day minimum)**

Open a GitHub Discussion that covers:
- The real-world concept the schema models
- Which plane and layer it belongs to
- Which existing packs were considered and why they are insufficient
- The proposed generic/ION-specific split
- Which CRC(s) this pack serves
- The proposed `x-ion-crc-rules` entry

Tag `ION Schema WG` for schema packs; tag `ION Sector WG` for the relevant sector.

**Phase 3 — Authoring the artifact files**

Author all seven required files. Use `beckn-schema-builder` for naming, descriptions, and vocabulary linkages. Use `beckn-payload-builder` to validate `examples/` JSON.

| File | What goes in it | Common mistakes |
|---|---|---|
| `attributes.yaml` | Schema definition. Generic layer first, ION layer via `allOf`. No `required:` on the top-level Attributes container — use `if/then` for intra-schema conditionals. | Forgetting `additionalProperties: true` on the extension container. Putting Indonesia-specific fields in the generic layer. |
| `schema.json` | JSON Schema 2020-12 mirror of `attributes.yaml`. Internal `$ref` paths use `#/$defs/` not `#/components/schemas/`. Root `$ref` resolves to the ION-specific schema. | Saving with a UTF-8 BOM (most JSON editors are safe; check with `python3 -c "open(f,'rb').read(3)==b'\\xef\\xbb\\xbf'"`) |
| `context.jsonld` | Maps every field name to its `ion:` IRI. Must have `@version: 1.1` and `@protected: true`. All four standard prefixes (`rdf`, `rdfs`, `xsd`, `schema`) must be declared. | Missing `@protected: true`. Missing prefixes. |
| `vocab.jsonld` | RDF vocabulary. Every class needs `rdfs:subClassOf` or `skos:broader` linking it to `beckn:{parent}`. Every property needs `rdfs:comment`. | Missing linkage on enumeration type classes. Missing comments on properties. |
| `profile.json` | Attachment metadata. `attachmentPoints` maps the slot name to the ION schema class name. `minimalForDiscovery` lists fields ONIX checks for indexing. | Wrong format for `attachmentPoints` (must be `{"slotName": ["SchemaClassName"]}`). Empty `minimalForDiscovery`. |
| `renderer.json` | UI rendering hints: `fieldGroups`, `badges`, display order. Required in every pack even when minimal. See `docs/ION_Schema_Style_Guide.md` §7 for the three-tier format and which tier to use for each pack type. | Omitting entirely — the validator expects the file even when content is sparse. Using Tier 3 when Tier 1 suffices, or vice versa. |
| `README.md` | Attaches-to, network-required fields, flow links, common rejection reasons, changelog. | Missing "Used in" links to `flows/`. Missing changelog entry. |

Also required:
- `examples/` — at least one complete, valid payload fragment showing the schema in context (not just the attributes bag in isolation — show it inside a `Resource` or `Offer`).
- Concept-level `README.md` (the parent folder above `v1/`) — version index table.

**Phase 4 — ion.yaml additions**

After the pack files are authored, update `ion.yaml`:

1. **`x-ion-schema-dependencies`** — add an entry for each new schema declaring its upstream parent, version, and pin date:
   ```yaml
   - ionSchema: {YourSchema}
     upstreamSchema: {BecknParentSchema}
     upstreamVersion: v2.0
     ionNative: false
   ```
   If the schema has no upstream parent (ION-native), set `ionNative: true`.

2. **`x-ion-crc-rules`** — add the CRC entry (see E3, Step 3 above).

3. **`x-ion-crc-registry`** — update the CRC entry with the `attributePack` path.

4. **`x-ion-field-requirements.alwaysRequired`** — add entries only if fields are mandatory on every ION transaction regardless of sector or pattern. This is rare. Most fields belong in `x-ion-crc-rules` instead.

5. **`x-ion-conditional-rules`** — if any field in the new pack is triggered by a field in a different schema bag (e.g. a field on `TradeContract` becomes required when a field on `IONParticipant` has a specific value), declare the rule here. ONIX reads this block at every API boundary.

**Phase 5 — Supporting artifacts**

Add error codes for the new pack's known rejection cases. In `errors/{sector}.yaml`, add entries following the existing format:

```yaml
- code: ION-{SectorPrefix}{Range}
  http_status: 400
  category: {catalog|transaction|fulfillment|settlement|schema}
  title:
    id: {Bahasa Indonesia title}
    en: {English title}
  description:
    en: {Full description of when this error occurs}
  affected_field: {schema path, e.g. resourceAttributes.someField}
  affected_apis: [{api names}]
  schema_ref: schema/extensions/{sector}/{pack}/v1
  flow_ref: {flow path or null}
  resolution:
    en: {Plain English: what the implementer must do to fix it}
```

Sector prefix codes: `A` = trade, `B` = logistics, `C` = mobility (reserved), `D` = hospitality, `E` = services (reserved), `F` = finance. Use the next available code in the sector's assigned range (see the comments at the top of each `errors/{sector}.yaml` for the range breakdown).

Run `python3 errors/generate_registry.py` after adding entries. It validates all codes and exits non-zero on duplicates or malformed entries.

Add policy terms if the new pack introduces new offer-level commitments (cancellation rules, warranty types, evidence requirements). In `policies/{category}/v1/`, follow the existing YAML format and run `python3 policies/generate_registry.py` to validate.

**Phase 6 — Validation and PR**

Run all validation commands before raising the PR:

```bash
# Validate ion.yaml schema
spectral lint schema/core/v2/api/v2.0.0/ion.yaml

# Regenerate and validate error registry
python3 errors/generate_registry.py

# Regenerate and validate policy registry
python3 policies/generate_registry.py

# Confirm required fields are correctly wired
python tools/ion_required_fields.py --sector {sector} --pattern {pattern} --crc {crc}

# Confirm the new pack appears correctly in tool output
python tools/ion_setup.py --role BPP --sector {sector} --pattern {pattern} \
  --crcs {crc} --variants cross-cutting --payment QRIS --output /tmp/test-setup/
```

Raise the PR against `main` with: the completed self-review checklist, the Discussion link, notes on which beckn-agents skills were used, and the curatorial decisions you made on top of their output.

---

### E5. Adding a new flow pattern or variant to an existing sector

Patterns and variants live in `flows/{sector}/patterns/{pattern-name}/v1/pattern.yaml` and `flows/{sector}/variants/{variant-name}/v1/variant.yaml`. Adding one does not require a new schema pack unless the pattern introduces fields that no existing pack covers.

**Pattern authoring checklist:**

- [ ] `pattern.yaml` has: `id`, `version`, `patternName`, `sector`, `status`, `description`, `participants`, `phases`, `variantWindows`
- [ ] Every phase step has: `step`, `from`, `to`, `direction`, `requiredFields[]`, `conditionalFields[]`, `schemaPacks{}`
- [ ] `schemaPacks` references only packs that exist in `schema/extensions/`. No fabricated pack names.
- [ ] `variantWindows` declares `earliest` and `latest` for every variant the pattern supports
- [ ] Pattern `README.md` has: commerce scenario description, API sequence numbered list, schema packs table, always-active variants listed, callout reframing `pattern.yaml` as the primary implementation checklist
- [ ] `python tools/ion_required_fields.py --sector {sector} --pattern {pattern-name}` runs successfully

**Variant authoring checklist:**

- [ ] `variant.yaml` has: `id`, `version`, `variantType`, `sector`, `status`, `description`, `subFlows`
- [ ] Each subFlow has: `apis[]`, `window`, `description`, `steps[]`
- [ ] Each step has `requiredFields[]` and, where relevant, `businessRules[]` and `errors[]`
- [ ] Variant `README.md` includes a "How variant fields layer" note: variant fields are *additive* — they do not replace the base pattern's required fields for the same step
- [ ] `variantType` value matches the folder name exactly

---

## Adding a new sector

This section covers the case where you are proposing a sector that does not yet have active schema packs or flow patterns on ION — currently mobility and services. Finance and hospitality existed in earlier stages and their path from reserved to active is the reference.

Adding a new sector is a multi-deliverable project, not a single PR. The work falls into four phases. Each phase produces a set of artifacts and ends with a review gate. Do not proceed to the next phase until the current one has ION Council or working group sign-off.

---

### N1. Check the sector's current status and get activation approved

The six ION sectors are declared in `ion.yaml → x-ion-sector-registry`. Check the entry for your sector:

```bash
grep -A6 "id: {sector}" schema/core/v2/api/v2.0.0/ion.yaml
```

If `active: false`, the sector is reserved. You cannot publish schema packs or patterns for a reserved sector without ION Council approval to activate it. The `domain` value (`ion:mobility`, `ion:services`) is already registered in the `context.domain` enum — what is missing is everything else.

**To get activation approved:**

1. Open a GitHub Discussion titled `[sector-activation] {Sector name} — activation proposal` and include:
   - The real-world use cases this sector covers on ION (with reference to `docs/ION_Entity_Hierarchy_Model.md` to confirm the sector, categories, and CRCs are correctly scoped)
   - Which organisations have expressed intent to participate as Seller Apps, Buyer Apps, or Sellers in this sector
   - The minimum viable scope — which CRCs and patterns you are proposing for the initial activation (not everything in the CRC registry; just what is needed for the first cohort of participants)
   - The sector's Indonesian regulatory framework (which laws, licences, and regulatory bodies govern participants in this sector)
   - Proposed KBLI codes for the sector's categories

2. Tag `ION Council` and wait for a formal decision. Activation decisions are not made by the Schema WG alone.

3. Once approved, the ION Council will update `ion.yaml → x-ion-sector-registry` to set `active: true` for the sector. This is the gate that allows everything below.

**Minimum viable sector spec for activation:**

A sector can be activated with as few as one CRC, one schema pack, one flow pattern, and a cross-cutting variant. You do not need to build everything simultaneously. The reference minimum (based on how hospitality was activated) is:

| Deliverable | Minimum for activation |
|---|---|
| Schema packs | Resource pack (L5) + at minimum Offer and Performance packs |
| CRCs | At least one ACTIVE CRC with a fully wired `attributePack` |
| Flow patterns | At least one ratified pattern with a `pattern.yaml` |
| Variants | `cross-cutting` variant (mandatory for all sectors) |
| Error codes | At least the catalog and transaction error ranges |
| Sector README | `flows/{sector}/README.md` and `schema/extensions/{sector}/README.md` |

Additional CRCs, patterns, and packs can be added in subsequent minor versions after activation.

---

### N2. Phase 1 — Sector foundation (ion.yaml and registries)

This phase produces the structural entries that all subsequent phases depend on. It is a single PR that touches only `ion.yaml` (no schema pack files yet). It requires ION Council review.

**What to author in this PR:**

**1. Sector registry update** (already done by ION Council at activation — confirm it is correct):

```yaml
# ion.yaml → x-ion-sector-registry
- id: {sector}
  domain: ion:{sector}
  description: {One-sentence description}
  active: true
```

**2. Category registry entries.** For each category in your sector (from `docs/ION_Entity_Hierarchy_Model.md`), confirm or add the entry in `x-ion-category-registry`. Each entry needs: `code`, `name`, `sector`, `kbliCodes[]`.

**3. CRC registry entries.** For each CRC you are activating in the first release, add an entry in `x-ion-crc-registry`. At this phase, `attributePack` will be `null` — it is filled in Phase 2 once the packs exist:

```yaml
- code: {CRC-code}
  name: {CRC name}
  sector: {sector}
  status: ACTIVE
  attributePack: null          # filled in Phase 2
  requiredSubObject: null      # filled in Phase 2
```

For CRCs you are not activating in this release, set `status: INACTIVE`.

**4. CRC rules entries.** Add placeholder entries to `x-ion-crc-rules` for each ACTIVE CRC. These will be completed in Phase 2 but the block must be non-empty to be valid:

```yaml
# x-ion-crc-rules
- crc: {CRC-code}
  requiredBlocks: []
  requiredFields: {}
```

**5. Schema dependencies placeholder.** For each schema pack you are planning (see Phase 2), add an entry to `x-ion-schema-dependencies` with `ionNative: false` and the intended upstream parent. If the upstream parent is not yet confirmed, mark it with a `note: pending-upstream-confirmation` flag.

**PR title format:** `[ion.yaml] Sector foundation — {sector} activation (Phase 1)`

---

### N3. Phase 2 — Schema packs

This phase produces the schema pack files. It is one or more PRs against `schema/extensions/{sector}/`. Each pack is a separate PR unless the packs are tightly coupled (e.g. the resource pack and its CRC-specific sub-object). Schema WG review is sufficient for individual packs; ION Council review is not required unless the pack introduces a new L4 core field.

**The standard sector pack set.** Every active ION sector has packs for the following Beckn attachment points. Author them in this order — each pack may reference types defined in the preceding ones:

| Pack | Attachment point | What it carries | Author order |
|---|---|---|---|
| `{sector}/resource/v1` | `Resource.resourceAttributes` | The sector's catalogue item (what is being offered) | 1st |
| `{sector}/offer/v1` | `Offer.offerAttributes` | Policy and commercial terms for the offer | 2nd |
| `{sector}/provider/v1` | `Provider.providerAttributes` | Provider-level catalogue metadata | 3rd |
| `{sector}/commitment/v1` | `Commitment.commitmentAttributes` | Per-line-item order details | 4th |
| `{sector}/consideration/v1` | `Consideration.considerationAttributes` | Price breakdown and totals | 5th |
| `{sector}/performance/v1` | `Performance.performanceAttributes` | Fulfilment state, tracking, and delivery details | 6th |
| `{sector}/contract/v1` | `Contract.contractAttributes` | Post-confirm order-level attributes (invoice, preferences) | 7th |

Not every sector needs all seven. Mobility, for example, may not need a `commitment` pack if journey bookings do not have per-line commitments. Use the ION\_Schema\_Design\_Guide.md three-plane model to decide what belongs at each attachment point.

**Two-schema split for every L5 pack.** Every pack must follow the pattern established in trade and logistics:

```yaml
# Generic layer — inherits from upstream Beckn/schema.beckn.io parent
{SectorConcept}:
  type: object
  x-ion-layer: generic
  x-recommended-parent: Resource.resourceAttributes
  additionalProperties: true
  allOf:
    - $ref: ../../../../core/v2/api/v2.0.0/beckn.yaml#/components/schemas/Attributes

# ION-specific layer — inherits from generic via allOf
ION{SectorConcept}:
  type: object
  x-ion-layer: ion
  allOf:
    - $ref: '#/components/schemas/{SectorConcept}'
  x-jsonld:
    '@context': ./context.jsonld
    '@type': ion:ION{SectorConcept}
  x-beckn-attaches-to: Resource.resourceAttributes
  additionalProperties: true
  # required: removed — mandatoriness declared in x-ion-field-requirements network policy
  properties:
    # Indonesia-specific fields here
```

The generic layer carries fields that any Beckn network would find meaningful. The ION-specific layer carries Indonesian regulatory fields (`x-ion-regulatory` annotation citing the law), market-convention fields, and CRC-conditional field blocks.

**Participant schema exception.** If your sector needs participant-level attributes (e.g. driver licence for mobility, pilot certification for aviation), note that `Participant` in Beckn v2.0 has **no `participantAttributes` wrapper**. Participant fields attach as direct properties on the `Participant` object. Use `x-beckn-attaches-to: Participant (direct properties — no participantAttributes wrapper)`. Do not use `x-beckn-attaches-to: Participant.participantAttributes` — this is incorrect and will be rejected at review.

**Completing the ion.yaml wiring.** After each pack PR is merged, update `ion.yaml` in a follow-up PR:
- Set `attributePack` in `x-ion-crc-registry` for every CRC the pack serves
- Complete the `x-ion-crc-rules` entry with actual `requiredBlocks` and `requiredFields`
- Add `requiredSubObject` to the CRC registry entry if the CRC requires a specific sub-object block

**Validation after each pack:**

```bash
python tools/ion_required_fields.py --sector {sector} --pattern {pattern} --crc {crc}
```

The output should show the new CRC's required fields under `[crc:{CRC-code}]` labels. If they do not appear, check that the `x-ion-crc-rules` entry is correct and that `ion.yaml` has been updated.

---

### N4. Phase 3 — Flow patterns and variants

This phase produces the `flows/{sector}/` directory. It is reviewed by the ION Sector Working Group. Patterns cannot be ratified before the schema packs they reference in `schemaPacks{}` are merged.

**What to author:**

**Sector-level README** at `flows/{sector}/README.md`. Model it on `flows/trade/README.md`. It must include:
- Sector description and the principle that defines what belongs in this sector (from `docs/ION_Entity_Hierarchy_Model.md`)
- Table of active patterns with links
- Table of available variants with their windows
- "Start with" callout identifying the reference pattern for a first-time builder in this sector
- "Schema packs" section listing which packs are mandatory for this sector

**`cross-cutting` variant** at `flows/{sector}/variants/cross-cutting/v1/variant.yaml`. This is mandatory for every sector. It carries the sub-flows that run concurrently with the main spine after `on_confirm`: `track`, `support`, `rate`, `reconcile`, and `raise` (if applicable). Adapt the sub-flow windows and required fields to your sector's semantics — for mobility, `track` covers real-time GPS of the vehicle; for services, it may not apply.

**Reference pattern** — the primary pattern that the first cohort of participants in your sector will implement. For mobility this is likely `on-demand-ride`. Author `flows/{sector}/patterns/{pattern-name}/v1/pattern.yaml` following the structure of `flows/trade/patterns/storefront/v1/pattern.yaml` exactly:

```yaml
id: ion-{sector}-pattern-{pattern-name}-v1
version: "1.0.0"
patternName: {pattern-name}
sector: ion:{sector}
status: ready          # or: draft
description: >
  {One paragraph: what commerce scenario this covers, what buyer ends up with}

participants:
  BAP: {Buyer App description}
  BPP: {Seller App / Provider App description}

phases:
  phase1:
    name: Catalog
    steps:
      - step: publish_catalog
        from: BPP
        to: ION_CATALOG
        direction: publish
        requiredFields:
          - {list all fields ONIX checks at this step}
        schemaPacks:
          core: [localization/v1, business-registration/v1, address/v1]
          {sector}: [resource/v1, offer/v1, provider/v1]
  # ... phases 2 (Transaction) and 3 (Fulfilment)

variantWindows:
  cross-cutting:
    earliest: on_confirm
    latest: contract_COMPLETE
  cancellation:
    earliest: on_confirm
    latest: {step after which cancellation is no longer possible}
```

**`schemaPacks` in pattern steps must only reference packs that exist.** Do not reference `{sector}/performance/v1` in a pattern step if the pack is not yet merged. Reference only what is present in `schema/extensions/` at the time the pattern PR is raised.

**Pattern README** at `flows/{sector}/patterns/{pattern-name}/v1/README.md`. Must include:
- Two-sentence commerce scenario description
- API sequence as a numbered list (step, direction, what is exchanged)
- Schema packs table with links to `schema/extensions/`
- Always-active variants list (always includes `cross-cutting`)
- Callout: "The `pattern.yaml` lists every field ONIX validates at each step — use it as your implementation checklist."

---

### N5. Phase 4 — Supporting artifacts (errors, policies, tools)

This phase makes the sector usable for real implementers. It can be done in parallel with Phase 3 or as a follow-on.

**Error codes for the new sector.**

Add a new file `errors/{sector}.yaml` following the format of `errors/trade.yaml`. Assign a sector prefix letter — the currently used prefixes are: `A` (trade), `B` (logistics), `D` (hospitality), `F` (finance). Choose the next available letter for your sector (e.g. `C` for mobility, `E` for services). Document the prefix in the file header comment.

Define code ranges for each error category:
```
ION-{Prefix}2xxx: Catalog errors
ION-{Prefix}3xxx: Transaction errors (select → confirm)
ION-{Prefix}4xxx: Fulfilment errors
ION-{Prefix}5xxx: Post-order errors
ION-{Prefix}6xxx: Settlement errors
ION-{Prefix}8xxx: Schema validation errors
```

Add the new file to the `SECTOR_FILES` list in `errors/generate_registry.py`, and update the file's docstring to document the new sector prefix. Run `python3 errors/generate_registry.py` to validate.

**Policy terms for the new sector.**

If your sector introduces offer-level policy types that do not exist in the current `policies/` categories (e.g. a ride-hailing cancellation policy is structured differently from a trade cancellation policy), add a new category folder: `policies/{category}/v1/{sector}/`. Follow the existing YAML format. Add the category to `CATEGORIES` in `policies/generate_registry.py` and run `python3 policies/generate_registry.py` to validate.

If your sector's policy types can be expressed as variants of existing cross-sector categories (e.g. cancellation, dispute, sla), add sector-specific terms to the existing category's sector subfolder (`policies/cancellation/v1/{sector}/`) rather than creating a new category.

**Sector README** at `schema/extensions/{sector}/README.md`. Must include:
- Sector description
- Table of active packs with status and attachment point
- "Minimum for your first integration" — the 2–3 packs a builder must implement to pass ONIX validation for the reference pattern
- Links to the sector's flow README and the ION Entity Hierarchy Model entry

**Update `tools/ion_setup.py`** — the setup generator reads `x-ion-crc-rules` and `flows/{sector}/` automatically; no code changes are needed unless the sector uses a non-standard flow structure. Verify it works:

```bash
python tools/ion_setup.py --role BPP --sector {sector} --pattern {pattern-name} \
  --crcs {CRC-code} --variants cross-cutting --payment QRIS \
  --output /tmp/{sector}-test/
```

---

### N6. Sector activation checklist — the go/no-go gate

Before raising the final PR that moves a sector from `active: false` to `active: true` in `ion.yaml`, confirm every item below. This checklist is the ION Council's sign-off gate.

**Registry completeness**
- [ ] `x-ion-sector-registry` entry has `active: true`
- [ ] All ACTIVE CRCs have a non-null `attributePack` entry in `x-ion-crc-registry`
- [ ] All ACTIVE CRCs have a corresponding entry in `x-ion-crc-rules` with at least one `requiredField`
- [ ] All planned packs are registered in `x-ion-schema-dependencies`

**Schema pack completeness**
- [ ] Resource pack exists and has been reviewed by the ION Schema WG
- [ ] Offer pack exists
- [ ] Performance pack exists (or a documented exception justifying its absence)
- [ ] All pack files are present: `attributes.yaml`, `schema.json`, `context.jsonld`, `vocab.jsonld`, `profile.json`, `renderer.json`, `README.md`, at least one example
- [ ] All packs pass `spectral lint`
- [ ] All JSON files have no BOM encoding
- [ ] All `context.jsonld` files have `@version: 1.1` and `@protected: true`
- [ ] All `vocab.jsonld` files have `rdfs:subClassOf` or `skos:broader` on every ION-specific class

**Flow completeness**
- [ ] At least one ratified flow pattern exists in `flows/{sector}/patterns/`
- [ ] `cross-cutting` variant exists in `flows/{sector}/variants/`
- [ ] `flows/{sector}/README.md` is populated (not "Planned — pending")
- [ ] `schema/extensions/{sector}/README.md` is populated

**Supporting artifacts**
- [ ] `errors/{sector}.yaml` exists with at least catalog and transaction error ranges
- [ ] `python3 errors/generate_registry.py` exits 0
- [ ] `python3 policies/generate_registry.py` exits 0
- [ ] `python tools/ion_required_fields.py --sector {sector} --pattern {pattern} --crc {crc}` produces output with no errors

**Tool verification**
- [ ] `python tools/ion_setup.py --role BPP --sector {sector} --pattern {pattern} --crcs {crc} --variants cross-cutting --payment QRIS --output /tmp/test/` generates a complete output folder successfully

**Documentation**
- [ ] `docs/ION_Entity_Hierarchy_Model.md` entry for the sector is accurate and up to date
- [ ] Each schema pack README has: Attaches-to, Network-required fields, Used-in flow links, Common rejection reasons, Changelog

When all items are checked, raise the final `ion.yaml` PR to set `active: true`. Tag `ION Council` for the final review.

---

### N7. Quick reference: full deliverable list for a new sector

The table below is the canonical list of everything a new sector contribution must produce. Use it as a project tracker from the start — it prevents the most common failure mode, which is discovering late that an artifact is missing.

| Deliverable | Location | Phase | Reviewer |
|---|---|---|---|
| Sector foundation PR (ion.yaml: sector registry, category registry, CRC registry placeholders, CRC rules placeholders, schema dependencies) | `schema/core/v2/api/v2.0.0/ion.yaml` | 1 | ION Council |
| Resource schema pack | `schema/extensions/{sector}/resource/v1/` | 2 | ION Schema WG |
| Offer schema pack | `schema/extensions/{sector}/offer/v1/` | 2 | ION Schema WG |
| Provider schema pack | `schema/extensions/{sector}/provider/v1/` | 2 | ION Schema WG |
| Commitment schema pack | `schema/extensions/{sector}/commitment/v1/` | 2 | ION Schema WG |
| Consideration schema pack | `schema/extensions/{sector}/consideration/v1/` | 2 | ION Schema WG |
| Performance schema pack | `schema/extensions/{sector}/performance/v1/` | 2 | ION Schema WG |
| Contract schema pack | `schema/extensions/{sector}/contract/v1/` | 2 | ION Schema WG |
| ion.yaml CRC wiring update (fill in attributePack, requiredSubObject, complete crc-rules) | `schema/core/v2/api/v2.0.0/ion.yaml` | 2 (follow-on) | ION Schema WG |
| Sector schema extensions README | `schema/extensions/{sector}/README.md` | 2 | ION Schema WG |
| Cross-cutting variant | `flows/{sector}/variants/cross-cutting/v1/` | 3 | ION Sector WG |
| Reference pattern (at least one) | `flows/{sector}/patterns/{name}/v1/` | 3 | ION Sector WG |
| Sector flows README | `flows/{sector}/README.md` | 3 | ION Sector WG |
| Sector error codes | `errors/{sector}.yaml` + `generate_registry.py` update | 4 | ION Schema WG |
| Sector policy terms (if new categories needed) | `policies/{category}/v1/{sector}/` | 4 | ION Council |
| Activation PR (ion.yaml: active: true) | `schema/core/v2/api/v2.0.0/ion.yaml` | 4 | ION Council |

