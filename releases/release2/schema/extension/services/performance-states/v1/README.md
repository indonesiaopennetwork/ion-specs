# services/performance-states/v1

ION canonical state machine for CRC `SVC-social` social scheme facilitation.

## State machine: `scheme_facilitation`

| State | Contract | Commitment | Settlement | Terminal? |
|---|---|---|---|---|
| `ELIGIBILITY_CHECKED` | ACTIVE | ACTIVE | DRAFT | |
| `DOCUMENTS_REQUESTED` | ACTIVE | ACTIVE | DRAFT | |
| `DOCUMENTS_COLLECTED` | ACTIVE | ACTIVE | COMMITTED | |
| `APPLICATION_SUBMITTED` | ACTIVE | ACTIVE | COMMITTED | |
| `UNDER_GOVERNMENT_REVIEW` | ACTIVE | ACTIVE | COMMITTED | |
| `ADDITIONAL_INFO_REQUESTED` | ACTIVE | ACTIVE | COMMITTED | |
| `APPROVED` | ACTIVE | ACTIVE | COMMITTED | |
| `BENEFIT_DISBURSED` | **COMPLETE** | **CLOSED** | **COMPLETE** | ✅ |
| `REJECTED` | **COMPLETE** | **CLOSED** | **COMPLETE** | ✅ |
| `WITHDRAWN_BY_APPLICANT` | **CANCELLED** | **CLOSED** | **COMPLETE** | ✅ |

## State field

`Performance.status.descriptor.code` — kept in sync with `performanceAttributes.applicationStage`.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-07-29 | Initial release |
