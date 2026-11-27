# services/settlement/v1

Settlement attributes for a social-scheme facilitation service on ION (CRC SVC-social).

## Attaches to
`beckn:Settlement.settlementAttributes`

## Key design note
Government benefit amounts are **never** a Settlement line — the benefit is disbursed directly by the implementing government agency to the beneficiary. This pack covers only:
- Facilitation service fees charged to the applicant (when non-zero)
- Government fee passthroughs (e.g. statutory document-issuance charges)
- Refunds of facilitation fees (when `Offer.refundOnRejection=true` and the application is rejected)

FREE_FACILITATION offers must still carry a Settlement record with `settlementType=FREE` and `totalAmount=0` so ONIX can confirm no unlawful fee was collected.

## Network-required fields

Per `ion.yaml → x-ion-field-requirements.alwaysRequired` for `IONSocialSchemeSettlementAttributes`:
- `settlementType`
- `totalAmount`
- `currency`
- `paymentStatus`

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-07-29 | Initial release — created to complete 8-pack coverage for SVC-social sector |
