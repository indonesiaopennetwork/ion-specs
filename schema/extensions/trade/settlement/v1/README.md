# ION Trade Settlement Extension — v1

**Schema:** `IONTradeSettlement`  
**Attaches to:** `Settlement.settlementAttributes`  
**Sector:** Trade  

## Purpose

Carries the payment method declaration, instrument detail, and refund lifecycle for each settlement record in a trade transaction. One `Settlement` object per payment event in `Contract.settlements[]`.

## Key fields

| Field | Stage | Notes |
|---|---|---|
| `method` | init (BAP) | Payment method: QRIS, VIRTUAL_ACCOUNT, EWALLET, COD, etc. |
| `paymentRail` | init (BAP) | Specific rail: GOPAY, QRIS_DYNAMIC, VA_BCA, etc. |
| `collectedBy` | init (BAP) | BAP or BPP — determines settlement direction |
| `timing` | init (BAP) | PRE_ORDER, ON_CONFIRM, ON_DELIVERY, POST_DELIVERY |
| `status` | confirm (BAP/BPP) | NOT_PAID → PAID → REFUNDED lifecycle |
| `currency` | always | IDR (const) |
| `methodDetail` | on_init (BPP) | QRIS string, VA number, e-wallet deep link |
| `refundAmount` | on_cancel / on_update | Refund for cancellation or return resolution |
| `refundMethod` | on_cancel / on_update | Where refund is credited |
| `refundTimeline` | on_cancel / on_update | ISO 8601 duration e.g. P3D |

## Network policy

`method`, `collectedBy`, `timing`, `status`, `currency` are always required on every ION trade settlement record. Enforced via `x-ion-field-requirements.alwaysRequired` in ion.yaml.

## Relationship to core/payment/v1

`core/payment/v1` is the ION payment METHOD registry — it defines the structured sub-objects for each payment method (QRIS, VirtualAccount, EWallet, etc.) including instrument-level fields. `trade/settlement/v1` is the per-transaction settlement DECLARATION — it references method types by string and carries the runtime status and refund lifecycle. Use both together.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |

## Network-required fields

Enforced by ONIX at `confirm` and `on_confirm`:

| Field | Condition |
|---|---|
| `method` | Always required |
| `paymentRail` | Always required |
| `collectedBy` | Always required |

For the full step-by-step list: `python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion`

## Used in

`flows/trade/README.md` — all trade patterns (storefront, made-to-order, subscription)

## Common rejection reasons

- `method` not in the declared payment method set for the network → `ION-A6xxx`.
- `paymentRail` and `method` combination not supported → `ION-A6xxx`. E.g. `method: QRIS` requires `paymentRail: QRIS`.
- `collectedBy` value is neither `BAP` nor `BPP` → `ION-A8xxx`.
