# RestaurantCommitment — ION Hospitality Restaurant Ordering Extension
> **Schema evolution note (v1.1):** This pack does not yet implement the generic/ION-specific two-schema split pattern (as established in `trade/` and `logistics/` packs). The split — separating a generic `Commitment` layer (inheriting from upstream Beckn) from an `IONCommitment` ION-specific layer — is planned for v1.1 of this pack. This pack is pre-production; the split will be applied before any production traffic is carried on the hospitality sector. Tracked in the ION spec issue register as ION-7.

**Pack:** `hospitality/commitment/v1`  
**Class:** `ion:RestaurantCommitment`  
**Attaches to:** `Commitment.commitmentAttributes`  
**Sector:** Hospitality — Restaurant & Food Ordering (HSC-restaurant-ordering)  
**Version:** v1  

## Purpose

RestaurantCommitment provides order line with customisations and dietary requests for online food ordering platforms
(Grab Food, Gojek GoFood, Zomato, Swiggy style applications).

## Attachment

This pack extends the `Commitment.commitmentAttributes` slot in the Beckn v2.0.0 object model.
Every message carrying this pack MUST set:

```json
{
  "@context": "https://schema.ion.id/hospitality/commitment/v1/context.jsonld",
  "@type": "ion:RestaurantCommitment"
}
```

## Conditional requirements

Fields marked `x-ion-condition:` are conditionally required.
ONIX enforces these at the API boundary via Rego policy.
See `docs/ION_ONIX_Conditional_Policy.md` in the repo root.

## Related packs

All HSC-restaurant-ordering packs work together:

| Pack | Beckn slot | Purpose |
|---|---|---|
| `delivery/v1` | Resource | Menu item definition, halal, allergens, customisations |
| `provider/v1` | Provider | Restaurant profile, hours, licensing, delivery zones |
| `offer/v1` | Offer | Pricing, delivery fees, promos, scheduling |
| `commitment/v1` | Commitment | Order line with customisation selections |
| `consideration/v1` | Consideration | Price breakdown, fees, tax, cashback |
| `contract/v1` | Contract | Confirmed order, delivery prefs, group order |
| `performance/v1` | Performance | Kitchen states, rider tracking, ETA, delivery proof |

## Examples

See `examples/` for complete payload examples.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |

## Network-required fields

For the full list of fields required by ION network policy for this pack, run:

```bash
python tools/ion_required_fields.py --sector hospitality --pattern delivery-order --crc HSC-delivery
```

See `tools/README.md` and `tools/samples/required-fields-hospitality-delivery-order-HSC-delivery.md` for a pre-generated checklist.


## Used in

`flows/hospitality/README.md` — `delivery-order` pattern

