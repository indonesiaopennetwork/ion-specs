# ION Services Social Scheme Provider Extension (v1)

Provider-level attributes for a Network Participant offering social welfare
/ government scheme discovery and application facilitation on ION under
the Services sector (CRC SVC-social). Covers both the case where the
Provider is a government agency publishing its own schemes directly, and
the more common case where the Provider is an ION-empanelled facilitation
partner (a Seller App-operated organisation, analogous to Haqdarshak-style
scheme-facilitation businesses) authorised to receive and process
applications on behalf of one or more government schemes.

ION v2.0 placement:
  Placed in Provider.providerAttributes returned in on_discover.
  Provider.providerAttributes["@context"] — context.jsonld URI
  Provider.providerAttributes["@type"]    — "ion:IONSocialSchemeProviderAttributes"

Regulatory anchors (Indonesia):
  - UU 11/2009 tentang Kesejahteraan Sosial
  - Permensos 3/2021 — SLRT empanelment and referral network
  - OSS / NIB — business registration for private facilitation partners

## Attachment

- **Attaches to:** `Provider.providerAttributes`
- **Generic layer:** `SocialSchemeProvider`
- **ION-specific layer:** `IONSocialSchemeProviderAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `providerType` | Nature of this Provider's relationship to the schemes it publishes. |
| `empanelment` | empanelment field |
| `operatingRegions` | BPS province codes where this Provider actively offers application assistance. |
| `caseworkerNetwork` | caseworkerNetwork field |
| `helpline` | helpline field |
| `nibRegistered` | Whether the Provider organisation holds a valid NIB. Required for EMPANELLED_FACILITATION_PARTNER and NGO_REFERRAL_PARTNER provider types. |
| `dataHandlingCertification` | Certification or self-declaration status for UU PDP 2022 compliant handling of beneficiary personal data. |

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
