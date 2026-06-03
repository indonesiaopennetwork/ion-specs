# ion-core/reconcile/v1

Inter-NP financial reconciliation between BAP (collector) and BPP (receiver).

## Attaches to
`beckn:Settlement.settlementAttributes`

## APIs
`reconcile` → `on_reconcile`

## Flow
1. BAP initiates `/reconcile` with contract amounts, finder fee, withholding, adjustments
2. BPP responds via `/on_reconcile` with `reconStatus`: 01=AGREED, 02=OVERPAID, 03=UNDERPAID
3. If DISPUTED, either party raises a ticket via `raise/on_raise`

## Adjustments
Adjustments cover contract-level changes that must be agreed before settlement:
PRICE_ADJUSTMENT, CANCELLATION_FEE, RETURN_DEDUCTION, DAMAGE_PENALTY, COD_REMITTANCE, REFUND

## Reconciliation model
The ION reconcile/on_reconcile flow is a bilateral settlement confirmation mechanism between CN and PN.
Adjustment types (PRICE_ADJUSTMENT, RETURN_DEDUCTION, SLA_PENALTY etc.) are ION-native and defined in this schema pack.

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `reconId`
- `contractId`
- `baseContractAmount`
- `finderFee`
- `netSettlementAmount`
- `reconStatus`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/variants/cross-cutting/v1/variant.yaml`

## Common rejection reasons

Missing `reconId` → `ION-6xxx`. `reconStatus` must be one of PENDING | AGREED | DISPUTED. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
