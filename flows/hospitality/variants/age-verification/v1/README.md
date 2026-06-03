# age-verification — ION Hospitality Variant v1

**Applies to:** delivery-order  
**Activation:** Any order line has `ageRestricted = true` (alcohol)  
**Regulatory:** Permendag 20/M-DAG/PER/4/2014 — minimum age 21  

Rider verifies consumer age at doorstep using KTP/SIM/Passport before
handing over orders containing alcoholic beverages.

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
