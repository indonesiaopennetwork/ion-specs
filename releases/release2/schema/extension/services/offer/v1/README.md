# ION Services Social Scheme Offer Extension (v1)

Offer-level attributes for a social-scheme facilitation service on ION
(CRC SVC-social). Government benefits themselves are never sold — the
offer models the facilitation *service* around a scheme: eligibility
checking, document assistance, application submission, and status
tracking. The underlying government benefit stays reflected on the
Resource; this schema governs what, if anything, the applicant is
charged for facilitation.

ION v2.0 placement:
  Placed in Offer.offerAttributes returned in on_discover / on_select.
  Offer.offerAttributes["@context"] — context.jsonld URI
  Offer.offerAttributes["@type"]    — "ion:IONSocialSchemeOfferAttributes"

## Attachment

- **Attaches to:** `Offer.offerAttributes`
- **Generic layer:** `SocialSchemeOffer`
- **ION-specific layer:** `IONSocialSchemeOfferAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `serviceType` | Which facilitation service this Offer represents for the linked scheme Resource. |
| `pricingModel` | Whether the applicant pays anything for this facilitation service. The underlying government benefit is always free to the beneficiary — pricingModel governs the facilitation service fee only, never the benefit itself. |
| `facilitationFee` | Present when pricingModel is FLAT_FACILITATION_FEE or SUCCESS_FEE_ON_APPROVAL. |
| `feeChargeTiming` | When the facilitation fee, if any, is collected. |
| `refundOnRejection` | Whether a collected fee is refunded if the government application is ultimately rejected. |
| `cancellationPolicy` | Policy IRI governing cancellation of the facilitation service before submission. |
| `grievanceSlaPolicy` | Policy IRI declaring the response and resolution SLA for applicant grievances on this offer. |

## Files in this pack

```
attributes.yaml    Primary source of truth (OpenAPI 3.1.1)
schema.json        JSON Schema mirror (generated)
context.jsonld     JSON-LD context (@protected:true)
vocab.jsonld       RDF vocabulary
profile.json       Attachment metadata
renderer.json      UI rendering hints
README.md          This file
```

Worked messages that use this pack are in the
[`scheme-facilitation/v1` examples](../../../../../flows/services/patterns/scheme-facilitation/v1/examples/).
