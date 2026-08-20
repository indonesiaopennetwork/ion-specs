# ION Protocol Specification — Core API Layer

The two API contracts previously stored in this directory have moved into the
Release 1 draft:

```
releases/release1/vendored/beckn/protocol/v2.0.0/beckn.yaml
releases/release1/core/api/v2.0.0/ion.yaml
```

This legacy directory contains no normative API contract.

> **You do not need to read `beckn.yaml` to build an integration.** `ion.yaml` is your implementation target. `beckn.yaml` is only touched when upgrading the vendored Beckn version or debugging a protocol-level issue.

## How they relate

The Release 1 `beckn.yaml` is the upstream Beckn Protocol specification. It defines:
- 30 API endpoints (`/discover`, `/select`, `/init`, `/confirm`, `/status`, etc.)
- All core data model schemas (`Contract`, `Resource`, `Offer`, `Commitment`, `Consideration`, `Performance`, `Settlement`, `Provider`, `Participant`, `Tracking`, `Attributes`, …)

The Release 1 `ion.yaml` extends `beckn.yaml` without copying it. It defines:
- **L2** — ION network profile: Indonesian regulatory rules, signing requirements, allowed payment rails, conformance matrix (`x-ion-profile` block)
- **L3** — 8 additional ION endpoints: `/raise` family (6) + `/reconcile` + `/on_reconcile`. Every path `$ref`s Beckn types from `beckn.yaml`
- **L4** — 11 cross-sector attribute packs that mount on Beckn's `*Attributes` slots
- **L5** — Trade (8) and Logistics (10) sector attribute packs, same mounting pattern
- **Cross-schema rules** — 5 conditional requirements that ONIX enforces at runtime (`x-ion-conditional-rules` block)

## How to find your required fields

`ion.yaml` is a 10,000+ line file. You should not read it top-to-bottom. The parts that matter for your integration are:

| What to check | Location in ion.yaml | When to check it |
|---|---|---|
| Always-required fields | `x-ion-field-requirements.alwaysRequired` | When setting up your integration for the first time |
| Category-conditional fields | `x-ion-crc-rules` | When you know which CRC (product category) you are using |
| Cross-schema conditional fields | `x-ion-conditional-rules` | When implementing COD, logistics driver flows, or PKP billing |

For most developers the fastest path is to read the flow pattern's `pattern.yaml` first — it gives you the per-step required fields for your specific commerce pattern, assembled in one place.


## Quick start: run the required-fields tool

Rather than reading the four sources above manually, run:

```bash
python tools/ion_required_fields.py --sector <sector> --pattern <pattern> --crc <your-crc>
```

This assembles the complete field checklist for your integration in one command. See `tools/README.md` for usage.

## To validate

Run both files together through any OpenAPI 3.1.1 validator:
```
spectral lint releases/release1/core/api/v2.0.0/ion.yaml --ruleset beckn-ruleset.yaml
```

## Upstream tracking

Vendored Beckn upgrades are performed by release tooling and recorded in the
release manifest and notices. Published releases are never modified in place.

Current Beckn target: **v2.0.0** (LTS `main` branch)
