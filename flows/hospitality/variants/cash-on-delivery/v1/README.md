# cash-on-delivery — ION Hospitality Variant v1

**Applies to:** delivery-order  
**Activation:** `RestaurantOffer.availableOnCod = true`  

Consumer pays cash to rider at doorstep. OTP verification available for
high-value orders. Rider reconciles with platform end of day.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
