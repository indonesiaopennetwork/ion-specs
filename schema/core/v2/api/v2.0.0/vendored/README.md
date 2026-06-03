# Vendored Upstream Schema Reference Copies

This directory contains **local reference copies** of upstream Beckn domain schemas
that ION generic layers inherit from. These are **reference copies only** — the
active `allOf` in each `attributes.yaml` points to the live remote URL.

## How the allOf pattern works

```yaml
allOf:
  # REMOTE upstream (active — used by ONIX at validation time):
  - $ref: https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailResource/v2.1/attributes.yaml#/components/schemas/RetailResource
  # LOCAL vendored reference copy (for offline review and version drift detection):
  # - $ref: ../../../core/v2/api/v2.0.0/vendored/retail-resource-v2.1.yaml#/components/schemas/RetailResource
```

The remote URL is always active. The local copy is commented out.
To validate offline or check version drift, swap the comments.

## Version drift detection

When a new Beckn release is announced:
1. Fetch the remote URL: `curl -o <filename> "<remote_url>"`
2. Diff against the local copy: `diff <filename> vendored/<filename>`
3. If content changed within the same version — raise with ION Council (Beckn governance violation)
4. If a new version is released — keep the local copy at the current pinned version until Council upgrades

## Upgrade process

1. ION Council decides to upgrade a pinned version
2. Fetch the new version from the remote URL
3. Replace the vendored file content
4. Update `upstreamVersion` in `ion.yaml → x-ion-schema-dependencies`
5. Update `docs/ION_Upstream_Dependency_Map.md`

## Files

| File | Upstream schema | Pinned version | Remote URL |
|---|---|---|---|
| `retail-resource-v2.1.yaml` | RetailResource | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailResource/v2.1/attributes.yaml |
| `retail-offer-v2.1.yaml` | RetailOffer | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailOffer/v2.1/attributes.yaml |
| `retail-commitment-v2.1.yaml` | RetailCommitment | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailCommitment/v2.1/attributes.yaml |
| `retail-consideration-v2.1.yaml` | RetailConsideration | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailConsideration/v2.1/attributes.yaml |
| `retail-contract-v2.1.yaml` | RetailContract | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailContract/v2.1/attributes.yaml |
| `retail-performance-v2.1.yaml` | RetailPerformance | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailPerformance/v2.1/attributes.yaml |
| `retail-settlement-v2.1.yaml` | RetailSettlement | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailSettlement/v2.1/attributes.yaml |
| `food-and-beverage-offer-v2.1.yaml` | FoodAndBeverageOffer | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/FoodAndBeverageOffer/v2.1/attributes.yaml |
| `food-and-beverage-resource-v2.1.yaml` | FoodAndBeverageResource | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/FoodAndBeverageResource/v2.1/attributes.yaml |
| `shipment-v2.0.yaml` | Shipment | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Shipment/v2.0/attributes.yaml |
| `logistics-v2.0.yaml` | Logistics | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Logistics/v2.0/attributes.yaml |
| `logistics-fare-v2.0.yaml` | LogisticsFare | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/LogisticsFare/v2.0/attributes.yaml |
| `logistics-operator-v2.0.yaml` | LogisticsOperator | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/LogisticsOperator/v2.0/attributes.yaml |
| `payment-v2.0.yaml` | Payment | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Payment/v2.0/attributes.yaml |
