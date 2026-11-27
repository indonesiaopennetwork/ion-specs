## Minimum for your first integration

**Services BPP (publishing a SVC-social scheme):** You must implement at minimum
`resource/v1`, `offer/v1`, and `consideration/v1` to pass ONIX validation for the
`scheme-application` reference pattern (see `flows/services/`). `performance/v1`
and `contract/v1` are required once the transaction moves beyond `/confirm`.
`provider/v1` is required to publish at all — every Provider on ION must declare
its `providerAttributes`.

**Services BAP (buyer app / citizen-facing app):** You must be able to read
`resource/v1`, `offer/v1`, and `consideration/v1` to render scheme discovery and
eligibility pre-screening. `performance/v1` is required to display application
status.

# ION Services Extension Packs

Services sector schema extensions. This is the **first attribute pack set built
for the Services sector** (`ion:services`) on ION — the six other Services CRCs
(`SVC-tech`, `SVC-professional`, `SVC-healthcare`, `SVC-telecom`, `SVC-creative`,
`SVC-home`, `SVC-education`) remain `attributePack: null` in the CRC registry and
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
| `commitment/v1` | `beckn:Commitment.commitmentAttributes` | lineId, resourceId, offerId, applicantProfile (self-declared, pre-verification), eligibilityPreCheckResult |

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
through the CRC taxonomy instead. `SVC-social` is a new entry in
`x-ion-crc-registry`, not a new domain.

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
