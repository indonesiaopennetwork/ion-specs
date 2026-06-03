# Vendored Upstream Schema Files

This directory contains local vendored copies of upstream Beckn domain schemas
that ION generic layers inherit from via `allOf`. These are pinned at the versions
declared in `ion.yaml → x-ion-schema-dependencies`.

## How to fetch

Each `.yaml` file here corresponds to one upstream schema. Fetch using the remote
URL in that file's header comment, verify the content matches the pinned version,
and save as the filename listed.

## Upgrade process

1. ION Council decides to upgrade a pinned version
2. Fetch the new version from the remote URL
3. Diff against the current vendored file
4. Update the file and update `upstreamVersion` in `ion.yaml → x-ion-schema-dependencies`
5. Review inherited fields for any changes in `docs/ION_Upstream_Dependency_Map.md`

## Files

| File | Upstream schema | Version | Remote URL |
|---|---|---|---|
| `retail-resource-v2.1.yaml` | RetailResource | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailResource/v2.1/attributes.yaml |
| `retail-offer-v2.1.yaml` | RetailOffer | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailOffer/v2.1/attributes.yaml |
| `retail-commitment-v2.1.yaml` | RetailCommitment | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailCommitment/v2.1/attributes.yaml |
| `retail-consideration-v2.1.yaml` | RetailConsideration | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailConsideration/v2.1/attributes.yaml |
| `retail-contract-v2.1.yaml` | RetailContract | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailContract/v2.1/attributes.yaml |
| `retail-performance-v2.1.yaml` | RetailPerformance | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailPerformance/v2.1/attributes.yaml |
| `retail-settlement-v2.1.yaml` | RetailSettlement | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/RetailSettlement/v2.1/attributes.yaml |
| `food-and-beverage-offer-v2.1.yaml` | FoodAndBeverageOffer | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/FoodAndBeverageOffer/v2.1/attributes.yaml |
| `shipment-v2.0.yaml` | Shipment | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Shipment/v2.0/attributes.yaml |
| `logistics-v2.0.yaml` | Logistics | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Logistics/v2.0/attributes.yaml |
| `logistics-fare-v2.0.yaml` | LogisticsFare | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/LogisticsFare/v2.0/attributes.yaml |
| `logistics-operator-v2.0.yaml` | LogisticsOperator | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/LogisticsOperator/v2.0/attributes.yaml |
| `payment-v2.0.yaml` | Payment | v2.0 | https://raw.githubusercontent.com/beckn/schemas/main/schema/Payment/v2.0/attributes.yaml |
| `food-and-beverage-resource-v2.1.yaml` | FoodAndBeverageResource | v2.1 | https://raw.githubusercontent.com/beckn/local-retail/main/schema/FoodAndBeverageResource/v2.1/attributes.yaml |
