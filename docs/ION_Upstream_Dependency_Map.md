# ION Upstream Dependency Map
**Version:** 1.0 · 2026-06-03  
**Pinned at:** 2026-06-02  
**Governed by:** ION Council  
**Upgrade policy:** Explicit ION Council decision required. Beckn is trusted not to change content within a version — vendored copies in `schema/core/v2/api/v2.0.0/vendored/` are the safety net.

---

## How this works

Every ION schema pack follows a two-layer structure. The generic layer inherits from a pinned upstream via `allOf`. The ION layer inherits from the generic layer and adds Indonesian regulatory fields on top.

```
ION{Schema}   (x-ion-layer: ion)
  └── allOf → {GenericSchema}   (x-ion-layer: generic)
                 └── allOf → {Upstream}   ← declared in this document
```

Upstreams come from two places:

- **`beckn.yaml`** (local) — core protocol objects. Already vendored as a single file at `schema/core/v2/api/v2.0.0/beckn.yaml`.
- **`vendored/`** (local copies of schema.beckn.io domain schemas) — one file per schema at `schema/core/v2/api/v2.0.0/vendored/`. See `vendored/README.md` for fetch instructions.

## The `allOf` pattern

**For `beckn.yaml` upstreams** (core protocol objects — Participant, Resource, Offer etc.):
```yaml
allOf:
  - $ref: beckn.yaml#/components/schemas/Participant
  # - $ref: https://raw.githubusercontent.com/beckn/protocol-specifications-v2/main/api/v2.0.0/beckn.yaml#/components/schemas/Participant
```
`beckn.yaml` is kept locally as a vendored reference copy. The local ref is active.

**For `schema.beckn.io` upstreams** (domain schemas — RetailResource, Shipment etc.):
```yaml
allOf:
  # REMOTE upstream (active — used by ONIX at validation time):
  - $ref: https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailResource/v2.1/attributes.yaml#/components/schemas/RetailResource
  # LOCAL vendored reference copy (for offline review and version drift detection):
  # - $ref: ../../../core/v2/api/v2.0.0/vendored/retail-resource-v2.1.yaml#/components/schemas/RetailResource
```
The remote URL is **always active**. The local copy is commented out.
ONIX resolves the upstream schema at validation time via the remote URL.
The local vendored copy is for offline review and version drift detection only.

---

## Upstream dependency table

| ION Generic Schema | ION Layer | Upstream Schema | Version | Source | Vendored file | Inherited objects |
|---|---|---|---|---|---|---|
| `Address` | `IONAddress` | `Address` | v2.0 | `beckn.yaml` | — | `Address` |
| `BusinessRegistration` | `IONBusinessRegistration` | `Participant` | v2.0 | `beckn.yaml` | — | `Participant`, `Descriptor` |
| `Participant` | `IONParticipant` | `Participant` | v2.0 | `beckn.yaml` | — | `Participant`, `Descriptor` |
| `ProductCompliance` | `IONProductCompliance` | `Resource` | v2.0 | `beckn.yaml` | — | `Resource`, `Descriptor`, `Attributes` |
| `Rating` | `IONRating` | `RatingInput` | v2.1 | `beckn.yaml` | — | `RatingInput`, `RatingForm` |
| `Reconciliation` | `IONReconcile` | `Settlement` | v2.0 | `beckn.yaml` | — | `Settlement`, `Attributes` |
| `Support` | `IONSupportTicket` | `Support` | v2.0 | `beckn.yaml` | — | `Support` |
| `TradeProvider` | `IONTradeProvider` | `Provider` | v2.1 | `beckn.yaml` | — | `Provider`, `Descriptor`, `Location`, `Attributes` |
| `TradeSettlement` | `IONTradeSettlement` | `RetailSettlement` | v2.1 | `vendored/` | `retail-settlement-v2.1.yaml` | TBC — populate after fetch |
| `LogisticsAgent` | `IONLogisticsAgent` | `Participant` | v2.0 | `beckn.yaml` | — | `Participant`, `Descriptor` |
| `LogisticsCommitment` | `IONLogisticsCommitment` | `Commitment` | v2.0 | `beckn.yaml` | — | `Commitment`, `Attributes` |
| `LogisticsContract` | `IONLogisticsContract` | `Contract` | v2.0 | `beckn.yaml` | — | `Contract`, `Descriptor`, `Attributes` |
| `LogisticsPerformance` | `IONLogisticsPerformance` | `Performance` | v2.0 | `beckn.yaml` | — | `Performance`, `Attributes` |
| `LogisticsTracking` | `IONLogisticsTracking` | `Tracking` | v2.1 | `beckn.yaml` | — | `Tracking`, `Attributes` |
| `Payment` | `IONPayment` | `Payment` | v2.0 | `vendored/` | `payment-v2.0.yaml` | TBC — populate after fetch |
| `TradeResource` | `IONTradeResource` | `RetailResource` | v2.1 | `vendored/` | `retail-resource-v2.1.yaml` | TBC — populate after fetch |
| `TradeOffer` | `IONTradeOffer` | `RetailOffer` | v2.1 | `vendored/` | `retail-offer-v2.1.yaml` | TBC — populate after fetch |
| `TradeCommitment` | `IONTradeCommitment` | `RetailCommitment` | v2.1 | `vendored/` | `retail-commitment-v2.1.yaml` | TBC — populate after fetch |
| `TradeConsideration` | `IONTradeConsideration` | `RetailConsideration` | v2.1 | `vendored/` | `retail-consideration-v2.1.yaml` | `paymentMethods`, `currency`, `breakup`, `totalAmount`, `codAmount`, `appliedVouchers`, `loyaltyPointsApplied` |
| `RetailConsideration taxDetail` | `IONTaxDetail` | `RetailConsideration.breakup[].taxDetail` | v2.1 | `vendored/` | `retail-consideration-v2.1.yaml` | `rate`, `included`, `taxableBase` |
| `TradeContract` | `IONTradeContract` | `RetailContract` | v2.1 | `vendored/` | `retail-contract-v2.1.yaml` | TBC — populate after fetch |
| `TradePerformance` | `IONTradePerformance` | `RetailPerformance` | v2.1 | `vendored/` | `retail-performance-v2.1.yaml` | TBC — populate after fetch |
| `LogisticsResource` | `IONLogisticsResource` | `Shipment` | v2.0 | `vendored/` | `shipment-v2.0.yaml` | TBC — populate after fetch |
| `LogisticsOffer` | `IONLogisticsOffer` | `Logistics` | v2.0 | `vendored/` | `logistics-v2.0.yaml` | TBC — populate after fetch |
| `LogisticsConsideration` | `IONLogisticsConsideration` | `LogisticsFare` | v2.0 | `vendored/` | `logistics-fare-v2.0.yaml` | TBC — populate after fetch |
| `LogisticsProvider` | `IONLogisticsProvider` | `LogisticsOperator` | v2.0 | `vendored/` | `logistics-operator-v2.0.yaml` | TBC — populate after fetch |
| `RestaurantOffer` | `IONRestaurantOffer` | `FoodAndBeverageOffer` | v2.1 | `vendored/` | `food-and-beverage-offer-v2.1.yaml` | TBC — populate after fetch |
| `RestaurantProvider` | `IONRestaurantProvider` | `Provider` | v2.1 | `beckn.yaml` | — | `Provider`, `Descriptor`, `Location`, `Attributes` |
| `MenuItem` | `IONMenuItem` | `FoodAndBeverageResource` | v2.1 | `vendored/` | `food-and-beverage-resource-v2.1.yaml` | TBC — populate after fetch |

---

## ION-native schemas (no upstream)

These have no Beckn parent. No `allOf` to an upstream. No vendored file. Governed exclusively by ION Council.

| Schema | Pack |
|---|---|
| `IONTicket` | `core/raise` |
| `IONSupportTicket` | `core/support` |
| `IonLocalization` | `core/localization` |
| `IONCatalogLocalization` | `core/localization` |
| `TradePerformanceStates` | `trade/performance-states` |
| `LogisticsPerformanceStates` | `logistics/performance-states` |

---

## Completing the TBC cells

For each `TBC` entry in the table above:

1. Fetch the vendored file from the remote URL in `vendored/README.md`
2. Read the schema's top-level properties and nested schema names
3. Replace `TBC — populate after fetch` with the list of schema/object names inherited (e.g. `RetailResource`, `Descriptor`, `Attributes`)
4. Commit both the vendored file and the updated table together
