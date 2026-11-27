# ION Services Extension Packs

Draft. Services sector schema extensions, proposed for Services working group
review. This is the **first attribute pack set proposed for the Services
sector** (`ion:services`) on ION. The other Services categories (for example
`SVC-tech`, `SVC-professional`, `SVC-healthcare`, `SVC-telecom`,
`SVC-creative`, `SVC-home`, `SVC-education`) have no attribute packs yet and
are open for future SWG contribution, following the pattern established here.

These packs cover **CRC `SVC-social`** — Social Welfare & Government Schemes:
subsidies, cash transfers, pensions, scholarships, government-sponsored
insurance, document-issuance schemes, and other non-repayable public benefit
programmes, discoverable and applicable through ION Network Participants
(government agencies publishing directly, or empanelled facilitation partners).

## Packs

| Pack | Attaches to | What it covers |
|---|---|---|
| `provider/v1` | `beckn:Provider.providerAttributes` | providerType, empanelment status, operatingRegions, caseworkerNetwork, helpline, NIB registration, data-handling certification |
| `resource/v1` | `beckn:Resource.resourceAttributes` | Full `IONSocialSchemeResource` — schemeIdentity, eligibility (structured rules, not free text), benefit, requiredDocuments, applicationChannel, validity, fundingSource, Indonesian compliance block (DTKS, NIK verification, disbursement channel) |
| `offer/v1` | `beckn:Offer.offerAttributes` | serviceType (eligibility check / document assistance / full facilitation / status tracking / grievance filing), pricingModel, facilitationFee, feeChargeTiming, refundOnRejection, cancellationPolicy, grievanceSlaPolicy |
| `consideration/v1` | `beckn:Consideration.considerationAttributes` | breakupLineType (facilitation fee, document processing fee, government fee passthrough, discount, tax) |
| `performance/v1` | `beckn:Performance.performanceAttributes` | applicationStage state machine, caseworker, governmentReferenceNumber, decision timestamps, additionalInfoRequest, disbursement record |
| `contract/v1` | `beckn:Contract.contractAttributes` | caseId, applicantConsent (UU PDP 2022), assignedProviderId, caseStatus, case closure, reapplication cooldown |
| `commitment/v1` | `beckn:Commitment.commitmentAttributes` | lineId, resourceId, offerId, applicantProfile (self-declared, pre-verification), eligibilityPreCheck |
| `settlement/v1` | `beckn:Settlement.settlementAttributes` | settlementType (free, facilitation fee, government fee passthrough), paymentStatus, paymentMethod, remittance to the agency, refundRecord |
| `performance-states/v1` | (state machine, no attachment) | `scheme_facilitation` application stages and allowed transitions for `performanceAttributes.applicationStage`; `on_status` obligations |

## Minimum for a first integration

Draft guidance for the
[`scheme-facilitation/v1`](../../../flows/services/patterns/scheme-facilitation/v1/)
flow. Field-level mandatoriness is not set in these packs; it is listed per
step in that flow's `pattern.yaml`.

**Services BPP (publishing a SVC-social scheme):** `provider/v1`,
`resource/v1` and `offer/v1` to publish a catalogue; `commitment/v1` and
`consideration/v1` to answer `select`; `contract/v1`, `performance/v1` and
`settlement/v1` once the application moves past `init`.

**Services BAP (applicant-facing or agent app):** read `resource/v1`,
`offer/v1` and `consideration/v1` to show schemes and the eligibility
pre-check; read `performance/v1` to show application status.

## Why CRC `SVC-social`, not a new sector or a new domain string

ION's Unification-over-Standardization principle (see
`docs/ION_Schema_Design_Guide.md` §2) says a new use case should first be tested
against the question "can an existing schema/classification express this?"
Social welfare schemes are professional/institutional services rendered to
citizens — they belong in the Services sector (`ion:services`) alongside
healthcare, education, and advisory services, not in a new sector. ION does not
mint a new `context.domain` per vertical the way some Beckn deployments do
(compare the reference `upagrees.in/govt-schemes` domain in the sample payload
this pack was designed against) — verticals within a sector are expressed
through the CRC taxonomy instead. `SVC-social` is proposed as a new category
code within `ion:services`, not a new domain. Release 2 does not yet publish a
normative CRC registry, so the code and its final form are for the Services
working group to confirm.

## Why this is not `FNC-lending` or `SVC-professional`

See `IONSocialSchemeResource`'s description block in `resource/v1/attributes.yaml`
for the full boundary rules. In short: a scheme creates no repayment obligation
(unlike `FNC-lending`), and eligibility is rule-based / means-tested rather than
commercially negotiated (unlike `SVC-professional`).

## Eligibility as structured rules, not tags

The reference payload this pack was designed against (a Beckn v1-style
`catalog/publish` with scheme eligibility expressed as free-text `tags`) was
deliberately restructured into the `Eligibility` / `EligibilityRule` objects in
`resource/v1`. Per NFH-012 CON-012-28 (thin Attributes, dense Descriptor) and
the ION structured-field test in `ION_Schema_Design_Guide.md` §7, eligibility
criteria are the canonical case of a field ONIX must filter and evaluate
structurally — an AI agent or a Buyer App eligibility pre-screener cannot
reliably parse `"CT000015": "= Farmer"` style tag text at scale. Prose summary
is retained in `Eligibility.eligibilitySummary` for human display, but it is not
the source of truth for evaluation.
