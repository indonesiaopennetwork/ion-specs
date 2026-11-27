# ION Services Social Scheme Resource Extension (v1)

Canonical catalogue schema for social welfare and government benefit schemes
published on ION under the Services sector, Catalogue Resource Category
SVC-social (Social Welfare & Government Schemes). Covers subsidies, cash
transfers, pensions, scholarships, insurance-backed protection schemes,
document-issuance schemes, and other non-repayable government or
social-sector benefit programmes, discoverable and applicable through
empanelled facilitation partners (Seller Apps) on ION.

ION v2.0 placement:
  Placed in Resource.resourceAttributes returned in on_discover.
  The Beckn Resource wrapping it must carry:
    Resource.id          — provider-assigned scheme identifier
    Resource.descriptor  — human-readable scheme name/summary
    Resource.resourceAttributes["@context"] — context.jsonld URI
    Resource.resourceAttributes["@type"]    — "ion:IONSocialSchemeResource"

Distinguishing this CRC from adjacent ones:
  - Not FNC-lending: a scheme creates no repayment obligation. It is a
    non-repayable benefit, subsidy, entitlement, or facilitated service.
  - Not SVC-professional: eligibility is rule-based (means-tested against
    declared criteria), not negotiated between two commercial parties.
  - Not FNC-insurance: insurance-backed schemes (e.g. subsidised crop or
    health cover) are catalogued here when government-sponsored and
    premium-subsidised; commercially underwritten retail insurance
    remains FNC-insurance.

Regulatory anchors (Indonesia):
  - UU 11/2009 tentang Kesejahteraan Sosial — social welfare framework law
  - UU 13/2011 tentang Penanganan Fakir Miskin — poverty handling law
  - Perpres 63/2017 — non-cash social assistance disbursement (bansos non-tunai)
  - Permensos 5/2019 — DTKS (Data Terpadu Kesejahteraan Sosial) governance
  - UU PDP 2022 — Personal Data Protection Act (beneficiary data handling)
  - Permensos 3/2021 — SLRT (Sistem Layanan dan Rujukan Terpadu)

## Attachment

- **Attaches to:** `Resource.resourceAttributes`
- **Generic layer:** `SocialSchemeResource`
- **ION-specific layer:** `IONSocialSchemeResource`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `crc` | Catalogue Resource Category. Fixed at SVC-social for every resource using this schema. Declared explicitly (rather than only inferred) so ONIX and CNs can filter without parsing the full attribute bag. |
| `schemeIdentity` | schemeIdentity field |
| `eligibility` | eligibility field |
| `benefit` | benefit field |
| `requiredDocuments` | Checklist of documents an applicant must produce to apply for this scheme. Each entry names the document category and whether it is mandatory or conditional. |
| `applicationChannel` | applicationChannel field |
| `validity` | validity field |
| `fundingSource` | fundingSource field |
| `indonesianCompliance` | Present on every resource published on ION Indonesia. Carries the Indonesia-specific eligibility data-source, verification, and disbursement-channel fields that have no meaning outside this regulatory context. |

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
