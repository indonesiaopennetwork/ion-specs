# Cross-Border Export (XB)

Indonesian seller exports to international buyer. Requires bilingual catalog, HS codes, and customs documentation.

## Applicable categories
Agritech (coffee, cocoa, palm oil, spices), Fashion (batik, garments), Handicraft, Electronics re-export


## Performance state machine
`performance-states/v1/states.yaml#standard`
Plus additional XB states: CUSTOMS_CLEARED_EXPORT, IN_TRANSIT_INTERNATIONAL, CUSTOMS_CLEARED_IMPORT.

## Key differences from B2C-SF
- `name.en` and `shortDesc.en` **mandatory** (unlike domestic where en is optional)
- `packaged.hsnCode` required for all items
- `countryOfOrigin` required (already in resource/v1)
- `logisticsServiceType`: INTERNATIONAL_AIR or INTERNATIONAL_OCEAN
- Incoterms declared at on_select: FOB, CIF, EXW, DAP, DDP
- `beaCukaiReference` in contractAttributes at on_confirm
- `peb_reference` (Pemberitahuan Ekspor Barang) — Bea Cukai export declaration
- Payment: SWIFT or Letter of Credit for international; IDR settlement for domestic leg
- Documents: Commercial Invoice, Packing List, PEB, Certificate of Origin, Phytosanitary Cert

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`schema/extensions/trade/resource/v1/README.md`](../../../../schema/extensions/trade/resource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`schema/extensions/trade/offer/v1/README.md`](../../../../schema/extensions/trade/offer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`schema/extensions/trade/commitment/v1/README.md`](../../../../schema/extensions/trade/commitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`schema/extensions/trade/consideration/v1/README.md`](../../../../schema/extensions/trade/consideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`schema/extensions/trade/performance/v1/README.md`](../../../../schema/extensions/trade/performance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`schema/extensions/trade/contract/v1/README.md`](../../../../schema/extensions/trade/contract/v1/README.md) |
| `core/tax/v1` | See pack README | [`schema/extensions/core/tax/v1/README.md`](../../../../schema/extensions/core/tax/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, returns` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

