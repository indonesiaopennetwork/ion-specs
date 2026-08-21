# Schema Extensions

This directory contains ION's attribute pack extensions — the field definitions that populate Beckn's `*Attributes` slots.

## The core idea

Beckn v2.0 defines a data model with extension points built in. Every core object has an `*Attributes` slot that accepts a JSON-LD typed object. ION uses these slots to add Indonesia-specific fields without touching Beckn itself.

```
Beckn core object        ION extension pack          What it adds
─────────────────────    ──────────────────────────  ────────────────────────────────
Resource                 trade/resource/v1           Product structure, availability,
  └─ resourceAttributes  ◄── TradeResource           food/fashion/electronics fields

Offer                    trade/offer/v1              Return policy, cancellation policy,
  └─ offerAttributes     ◄── TradeOffer              COD availability, proof of delivery

Settlement               core/payment/v1             Payment method details (QRIS,
  └─ settlementAttributes ◄── PaymentDeclaration     VirtualAccount, EWallet, COD...)

Participant              core/participant/v1          Role taxonomy, NPWP/NIB/NIK,
  (direct properties)    ◄── IONParticipant          address hierarchy with RT/RW
```

> **Participant is the exception to the `*Attributes` pattern.** `Participant` in Beckn v2.0 does not have a `participantAttributes` extension bag. ION participant fields attach as **direct properties on the `Participant` object**, not inside a nested bag. There is no `participantAttributes` wrapper.

Multiple packs can attach to the same slot simultaneously. A `Settlement` record in a reconciliation step carries both `PaymentDeclaration` (from `core/payment/v1`) and `IONReconciliation` (from `core/reconcile/v1`). They are distinguished by their `@type` field.

## Directory structure

```
extensions/
  core/              ← L4: cross-sector packs — apply to every ION sector
  trade/             ← L5: Trade sector packs (active)
  logistics/         ← L5: Logistics sector packs (active)
  mobility/          ← L5: reserved
  finance/           ← L5: reserved
  tourism/           ← L5: reserved
  healthcare/        ← L5: reserved
```

## What each pack contains

Every versioned pack folder (`v1/`) holds exactly these files:

| File | What it is | Who uses it |
|---|---|---|
| `attributes.yaml` | OpenAPI 3.1.1 schema — the authoritative definition of every field | BPP/BAP developer |
| `schema.json` | JSON Schema mirror of attributes.yaml — for validators that don't parse OAS | Validators |
| `context.jsonld` | JSON-LD context — maps field names to `ion:` namespace IRIs | JSON-LD processors |
| `vocab.jsonld` | RDF vocabulary — defines each field as an `rdf:Property` with labels and comments | Semantic tools and registry |
| `profile.json` | Attachment metadata — which Beckn object this pack extends, indexing hints | ONIX |
| `renderer.json` | UI rendering hints — labels, display order, field groupings for BAP UIs | BAP UI frameworks |
| `README.md` | Property table — every field, its type, whether required, and a plain-English description | Everyone |
| `docs/` | Narrative documentation — design rationale, worked examples, field-level guidance | Everyone |
| `examples/` | Concrete JSON examples — complete valid payload fragments | Everyone |

**As a BPP or BAP developer** building your first integration, you primarily need `attributes.yaml` and `README.md`. You open `attributes.yaml` only when you need to understand a specific field in depth.

The concept folder above `v1/` also has a `README.md` that shows all available versions in a table.

## How a pack declares its attachment point

Every pack's main schema object carries an `x-beckn-attaches-to` annotation:

```yaml
# releases/release1/schema/extension/trade/TradeResource/v1/attributes.yaml

TradeResource:
  type: object
  x-beckn-attaches-to: Resource.resourceAttributes
  x-jsonld:
    '@context': ./context.jsonld
    '@type': ion:TradeResource
  allOf:
    - $ref: https://schema.ion.id/releases/release1/schema/vendored/beckn/protocol/v2.0.0/beckn.yaml#/components/schemas/Attributes
  properties:
    resourceStructure:
      type: string
      enum: [PLAIN, VARIANT, WITH_EXTRAS, COMPOSED, BUNDLE]
    availability:
      # ...
```

The `allOf` with `beckn.yaml#/.../Attributes` means this schema inherits Beckn's requirement that every `*Attributes` object must have `@context` and `@type`. Both fields are automatically required.

## `@context` on the wire: always a single string URL

The `@context` field inside any `*Attributes` bag **must be a single string URL** on the wire — not an array. When a network or participant needs to compose multiple vocabularies, that composition happens inside the published context document at the URL, not in the payload itself.

```json
{
  "resourceAttributes": {
    "@context": "https://schema.ion.id/releases/release1/schema/extension/trade/TradeResource/v1/context.jsonld",
    "@type": "ion:TradeResource",
    "resourceStructure": "PLAIN",
    "availability": { "status": "IN_STOCK" }
  }
}
```

## Composition example: two packs on one slot

When multiple packs attach to the same Beckn object, all their fields coexist in the same `*Attributes` JSON object — distinguished by `@type`. Here is how `PaymentDeclaration` and `IONReconciliation` coexist in a single `settlementAttributes` object:

```json
{
  "settlementAttributes": {
    "@context": "https://schema.ion.id/releases/release1/schema/common/Payment/v1/context.jsonld",
    "@type": "ion:PaymentDeclaration",
    "method": "QRIS",
    "paymentRail": "QRIS",
    "reconId": "RECON-20260601-001",
    "baseContractAmount": 150000,
    "finderFee": 3000,
    "netSettlementAmount": 147000,
    "reconStatus": "AGREED"
  }
}
```

Both packs contribute fields to the same object. The single `@context` URL points to a composed context document that internally references both packs' vocabularies.

## Adding a new sector

1. Create `extensions/{sector}/README.md` — describe the sector and list which core packs it uses
2. Create pack folders following the same structure as an existing sector
3. Add the sector to `releases/release1/schema/core/api/v2.0.0/ion.yaml` under `x-ion-conformance.schemaPackMatrix`
4. Opening a new sector requires ION Council ratification — see `GOVERNANCE.md`

## Pack versioning

Packs version independently using integer versions (`v1`, `v2`). When a pack needs a breaking change, a new version folder is created alongside the old one. Old versions are never deleted — implementations pinned to `v1` continue to work. The `profile.json` in each version declares its own identifier. The concept-level `README.md` shows the version index.
