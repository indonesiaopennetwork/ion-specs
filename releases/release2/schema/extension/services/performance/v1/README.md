# ION Services Social Scheme Performance Extension (v1)

Performance-level attributes tracking a social-scheme application through
its lifecycle on ION (CRC SVC-social) — from submission through government
decision to benefit disbursement. Surfaced at /on_confirm and via
/on_status updates.

ION v2.0 placement:
  Placed in Performance.performanceAttributes.
  Performance.performanceAttributes["@context"] — context.jsonld URI
  Performance.performanceAttributes["@type"]    — "ion:IONSocialSchemePerformanceAttributes"

## Attachment

- **Attaches to:** `Performance.performanceAttributes`
- **Generic layer:** `SocialSchemePerformance`
- **ION-specific layer:** `IONSocialSchemePerformanceAttributes`
- **CRC:** SVC-social (Social Welfare & Government Schemes, Services sector)

## Properties

| Field | Description |
|---|---|
| `applicationStage` | Current stage of the application lifecycle. This is the ION performance-state machine for SVC-social — distinct from generic Trade/Logistics delivery states because there is no physical fulfilment leg; the "fulfilment" is a government decision. |
| `caseworker` | caseworker field |
| `governmentReferenceNumber` | Application/case number issued by the implementing agency once submitted, if any. |
| `submittedAt` | submittedAt field |
| `decisionExpectedBy` | Estimated decision date, derived from the scheme's ApplicationChannel.processingTimeEstimate. |
| `decisionReceivedAt` | decisionReceivedAt field |
| `rejectionReason` | Present only when applicationStage is REJECTED. |
| `additionalInfoRequest` | additionalInfoRequest field |
| `disbursement` | disbursement field |

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
