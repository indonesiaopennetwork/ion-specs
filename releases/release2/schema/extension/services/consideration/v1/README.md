# ION Services Social Scheme Consideration Extension (v1)

Consideration-level (price breakup) attributes for a social-scheme
facilitation service on ION (CRC SVC-social). Government benefit amounts
are never a Consideration line — Consideration here covers only what the
applicant, if anything, pays the facilitation partner.

ION v2.0 placement:
  Placed in Consideration.considerationAttributes at /on_select, /on_init.
  Consideration.considerationAttributes["@context"] — context.jsonld URI
  Consideration.considerationAttributes["@type"]    — "ion:IONSocialSchemeConsiderationAttributes"

## Attachment

- **Attaches to:** `Consideration.considerationAttributes`
- **Generic layer:** `SocialSchemeConsideration`
- **ION-specific layer:** `IONSocialSchemeConsiderationAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `breakupLineType` | What this price line represents. |
| `totalAmount` | totalAmount field |
| `currency` | currency field |
| `governmentFeeReceipt` | When breakupLineType is GOVERNMENT_FEE_PASSTHROUGH (e.g. a statutory document-issuance fee the scheme itself charges), reference number for the official government receipt this line passes through. Absent for facilitation-only lines. |

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
