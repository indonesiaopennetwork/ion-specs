# B2B Wholesale Prepaid (B2B-PP)

Business buyer purchases wholesale from distributor or brand. Payment upfront.

## Applicable categories
FMCG distribution, electronics wholesale, agritech bulk, fashion wholesale, B2B pharmaceutical

## Key differences from B2C-SF
- MOQ enforced: `offer.offerAttributes.minOrderQuantity` required; select rejects below MOQ
- Bulk pricing tiers in on_select breakup
- `purchaseOrderReference` required at init (SP / SPK / PO number)
- `invoicePreferences.invoiceType = TAX_INVOICE` standard; requires PKP seller + NPWP buyer
- `breakup[].taxDetail.eFakturRef` assigned by BPP when a Faktur Pajak is issued
- Payment rails: RTGS / BI_FAST preferred over QRIS
- Partial cancellation is governed by the selected Offer policy and identifies affected `cancellation.commitmentIds`
- Delivery receipt: Surat Jalan / Delivery Order reference at DELIVERED

## State machine
`performance-states/v1/states.yaml#standard`

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
| `core/tax/v1` | See pack README | [`releases/release1/common/Tax/v1/README.md`](../../../../releases/release1/common/Tax/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation, returns` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.
