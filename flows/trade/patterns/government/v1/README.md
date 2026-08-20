# B2G Government Procurement (B2G)

Seller to government entity (K/L/D/I). Governed by Perpres 16/2018. LKPP e-Katalog compatible.

## Applicable categories
All — government procures from all Trade categories


## Performance state machine
`performance-states/v1/states.yaml#standard`
Plus BAST signing step before SP2D payment is triggered.

## Key differences from B2B-PP
- Government identity: `kldi_code` (Kementerian/Lembaga/Daerah/Institusi code)
- `sp_reference` (Surat Pesanan) or `spk_reference` (Surat Perintah Kerja)
- `dipa_reference` — budget line (Daftar Isian Pelaksanaan Anggaran)
- `tkdn_percentage` — Tingkat Komponen Dalam Negeri (local content %)
- `lkpp_catalog_id` — links product to LKPP e-Katalog listing
- Payment via SP2D (Surat Perintah Pencairan Dana) through KPPN — POST_FULFILLMENT
- BAST required before payment: Berita Acara Serah Terima signed by government official
- `bast_reference`, `bast_signed_by`, `bast_signed_at` in on_update after delivery
- PPh22 withheld by government: 1.5% deducted from payment; `pph22_withheld` declared
- `bukti_potong_reference` — PPh22 withholding certificate issued by government buyer
- Regulatory: Perpres 16/2018, Perpres 12/2021, PMK 190/PMK.05/2012

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`releases/release1/extension/trade/TradeResource/v1/README.md`](../../../../releases/release1/extension/trade/TradeResource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`releases/release1/extension/trade/TradeOffer/v1/README.md`](../../../../releases/release1/extension/trade/TradeOffer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`releases/release1/extension/trade/TradeCommitment/v1/README.md`](../../../../releases/release1/extension/trade/TradeCommitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`releases/release1/extension/trade/TradeConsideration/v1/README.md`](../../../../releases/release1/extension/trade/TradeConsideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`releases/release1/extension/trade/TradePerformance/v1/README.md`](../../../../releases/release1/extension/trade/TradePerformance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`releases/release1/extension/trade/TradeContract/v1/README.md`](../../../../releases/release1/extension/trade/TradeContract/v1/README.md) |
| `core/business-registration/v1` | See pack README | [`releases/release1/common/BusinessRegistration/v1/README.md`](../../../../releases/release1/common/BusinessRegistration/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

