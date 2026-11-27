# Services Scheme Facilitation Pattern v1

Draft Release 2 flow for CRC `SVC-social` (social welfare and government
schemes) in the Services sector. A facilitation partner publishes government
schemes as resources and its facilitation service as offers. An applicant, or an
agent helping the applicant, discovers a scheme, receives a provisional
eligibility pre-check, gives consent, and follows the application until the
government decision and disbursement.

Status: **draft reference profile**, proposed for review by the Services
working group. It uses only the eight Services packs in
[`schema/extension/services`](../../../../../schema/extension/services/).

## API sequence

```text
BPP -> publish_catalog -> ION Catalogue Service
BAP -> discover -> ION Discovery Service -> on_discover   (answered from crawled catalogues)
BAP -> select -> BPP -> on_select     (applicant profile -> eligibilityPreCheck)
BAP -> init -> BPP -> on_init         (applicant details, consent scope, fee or FREE)
BAP -> confirm -> BPP -> on_confirm   (consent record, case opened, caseworker assigned)
BAP -> status -> BPP -> on_status     (repeated; the BPP may also push on_status)
BAP -> update -> BPP -> on_update     (optional: applicant withdraws before a decision)
```

## Application stages

The performance state machine is
[`performance-states/v1`](../../../../../schema/extension/services/performance-states/v1/states.yaml)
`#scheme_facilitation`. The worked examples walk through
`DOCUMENTS_REQUESTED -> APPLICATION_SUBMITTED -> UNDER_GOVERNMENT_REVIEW ->
APPROVED -> BENEFIT_DISBURSED`, plus a `REJECTED` alternative.

## Policies

Each offer names two policy terms from the shared registry
([`policies/`](../../../../../../../policies/)):

| Category | Offer field | Default term |
|---|---|---|
| CANCELLATION | `offerAttributes.cancellationPolicy` | `ion://policy/cancel.social-scheme.until-submission` |
| GRIEVANCE_SLA | `offerAttributes.grievanceSlaPolicy` | `ion://policy/grievance-sla.social-scheme.standard` |

Both terms are `draft`.

## Examples

[`examples/`](examples/) has one message per step, taken from the
"Ibu Dewi" worked journey (a PKH application through a foundation). Every
example validates against the Release 2 Beckn core API
(`schema/core/api/v2.0.0/ion-beckn.yaml`) and every `...Attributes` block
validates against its Services pack.

## Open points for review

- **Personal data at select.** The pack's `applicantProfile` requires `nik` and
  `fullName`, and this flow sends the profile at `select` for the pre-check. The
  Beckn API text says no personal data is shared at `select`. A
  minimal-profile variant (no direct identifiers until `init`) may be needed.
- **Business applicants.** The profile is for individual citizens. Schemes for
  micro and small businesses need business fields (for example NIB, turnover
  band, sector, worker count).
- **External redirect.** A scheme that is applied for on a government portal
  maps to `applicationChannel.applicationMode: SELF_SERVICE` with
  `governmentPortalUrl`; a dedicated redirect fulfilment type may be clearer.
- **Naming and category code.** Pack names follow the source pack (`resource`,
  `offer`, ...) rather than Trade's `TradeResource` style, and `SVC-social` may
  need to become a registered category or CRC code.
