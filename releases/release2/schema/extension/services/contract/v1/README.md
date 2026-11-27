# ION Services Social Scheme Contract Extension (v1)

Contract-level attributes for a confirmed social-scheme application case
on ION (CRC SVC-social) — the record binding an applicant, a facilitation
Provider, and a scheme, from confirmation through case closure.

ION v2.0 placement:
  Placed in Contract.contractAttributes at /on_confirm and thereafter.
  Contract.contractAttributes["@context"] — context.jsonld URI
  Contract.contractAttributes["@type"]    — "ion:IONSocialSchemeContractAttributes"

## Attachment

- **Attaches to:** `Contract.contractAttributes`
- **Generic layer:** `SocialSchemeContract`
- **ION-specific layer:** `IONSocialSchemeContractAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `caseId` | ION network-wide unique case identifier for this application, assigned at confirm. |
| `applicantConsent` | applicantConsent field |
| `assignedProviderId` | Provider (facilitation partner or government agency) responsible for this case. |
| `caseStatus` | High-level case status, distinct from the finer-grained Performance.applicationStage. |
| `caseClosedAt` | caseClosedAt field |
| `reapplicationEligibleFrom` | Earliest date the applicant may reapply, when caseStatus is CLOSED_REJECTED and the scheme has a cooldown. |

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
