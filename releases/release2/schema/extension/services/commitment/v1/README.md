# ION Services Social Scheme Commitment Extension (v1)

Commitment-level attributes capturing an applicant's selection of a
scheme and a facilitation service at /select and /init, under the
Services sector (CRC SVC-social).

ION v2.0 placement:
  Placed in Commitment.commitmentAttributes at /select, /init, /confirm.
  Commitment.commitmentAttributes["@context"] — context.jsonld URI
  Commitment.commitmentAttributes["@type"]    — "ion:IONSocialSchemeCommitmentAttributes"

## Attachment

- **Attaches to:** `Commitment.commitmentAttributes`
- **Generic layer:** `SocialSchemeCommitment`
- **ION-specific layer:** `IONSocialSchemeCommitmentAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `lineId` | lineId field |
| `resourceId` | ID of the SVC-social scheme Resource being applied for. |
| `offerId` | ID of the facilitation Offer selected. |
| `applicantProfile` | applicantProfile field |
| `eligibilityPreCheck` | eligibilityPreCheck field |

## Files in this pack

```
attributes.yaml    Primary source of truth (OpenAPI 3.1.1)
schema.json        JSON Schema mirror (generated)
context.jsonld     JSON-LD context (@protected:true)
vocab.jsonld       RDF vocabulary
profile.json       Attachment metadata
renderer.json      UI rendering hints
README.md          This file
examples/          Sample payloads
```
