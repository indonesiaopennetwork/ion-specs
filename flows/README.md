# ION Flow Specifications

This directory contains the transaction flow specifications for every commerce pattern on ION.

## What a flow is

A **flow** defines the complete API sequence for a commerce scenario — from catalog publication through order confirmation, fulfilment, and post-order settlement. Flows reference the schema packs in `schema/extensions/` for the specific fields required at each step.

Flows are the most actionable starting point for a developer building an integration. The `pattern.yaml` for your pattern **lists every field ONIX validates at each API step** — it is your implementation checklist, not just a machine-readable spec.

## Patterns vs. variants

**Patterns** define the full API sequence for a commerce scenario (e.g. storefront purchase, parcel delivery). Each sector has a reference pattern; all others are defined as deltas from it.

**Variants** modify specific steps within a pattern when a condition is met (e.g. COD payment, cancellation, cross-cutting support). A transaction can have multiple variants active simultaneously. Variant field requirements are **additive** — they add to the base pattern's required fields for the same API step; they do not replace them. Always check both your pattern's `pattern.yaml` and each active variant's `variant.yaml` for the complete required field list at any given step.

## Always-active variants

The `cross-cutting` variant is always active on every pattern after `on_confirm`. It adds tracking, support, rating, reconciliation, and raise escalation to every transaction — you must implement it regardless of which base pattern you use.

## Active sectors

| Sector | Reference pattern | Flows | Schema packs |
|---|---|---|---|
| **Trade** | `storefront` | `flows/trade/` | `schema/extensions/trade/` |
| **Logistics** | `parcel` | `flows/logistics/` | `schema/extensions/logistics/` |
| **Hospitality** | `delivery-order` | `flows/hospitality/` | `schema/extensions/hospitality/` |

Start with the reference pattern for your sector: `storefront` for trade, `parcel` for logistics, `delivery-order` for hospitality.

## Reserved sectors

| Sector | Status |
|---|---|
| `flows/mobility/` | Planned — flow design pending sector working group decisions |
| `flows/tourism/` | Planned — flow design pending sector working group decisions |
| `flows/healthcare/` | Planned — flow design pending sector working group decisions |
| `flows/finance/` | Active for FIN-02 (lending) only |

If your use case falls in a reserved sector, contact the ION Council for interim guidance. In the meantime, you may use `schema/extensions/core/` packs with a custom overlay for the fields your use case requires.
