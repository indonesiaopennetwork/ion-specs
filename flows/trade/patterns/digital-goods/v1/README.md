# B2C Digital Goods (B2C-DIG)

Digital goods commerce on ION. No physical fulfilment — delivery is electronic.

## Applicable categories
Pulsa, data packages, electricity tokens (PLN), utility bill payments (water, PDAM, internet), BPJS contributions, gift cards, game currencies (Mobile Legends, Free Fire, Valorant, Genshin Impact), streaming service vouchers (Netflix, Disney+ Hotstar, Spotify), e-wallet top-ups, transport credits.

## Resource types used
- `DIGITAL_VOUCHER` — voucher codes, gift cards, game currency
- `DIGITAL_TOP_UP` — pulsa, data, electricity tokens, bill payments
- `DIGITAL_SUBSCRIPTION` — streaming service access, time-bound subscriptions

Each resource carries a `digital` sub-object with denomination, target type, delivery method, and category-specific fields.

## Key differences from B2C-SF

- **No shipping.** No fulfilment location, no logistics provider, no AWB, no delivery agent.
- **Fast fulfilment.** Digital fulfilment typically completes in seconds. State machine is `digital` — PENDING_OPERATOR → DELIVERED or DELIVERY_FAILED.
- **Target identifier mandatory.** Mobile number for pulsa, meter number for PLN, game user ID for game currency. Declared in `digital.target`.
- **Operator validation.** For pulsa and bill pay, BPP validates target before accepting (operator inquiry returns customer name for confirmation).
- **Typically non-refundable after delivery.** Pulsa delivered to phone cannot be recalled. Vouchers may be refundable if unredeemed.
- **Cancellation window very narrow.** Only possible before operator call is made.

## Performance state machine
`performance-states/v1/states.yaml#digital`

## Common operators / issuers
| Category | Issuers |
|---|---|
| Pulsa/Data | Telkomsel, XL, Indosat, Tri, Smartfren |
| Electricity | PLN (Perusahaan Listrik Negara) |
| Water | PDAM (per province) |
| Insurance | BPJS Kesehatan, BPJS Ketenagakerjaan |
| Gaming | Moonton (ML), Garena (FF), Riot Games (Valorant), MiHoYo (Genshin) |
| Streaming | Netflix, Disney+ Hotstar, Vidio, Iflix, Spotify |
| E-wallet | OVO, GoPay, DANA, ShopeePay top-up |

## Tax treatment
Digital goods often have specific tax treatment:
- **Pulsa and data packages**: PPN (at the current applicable rate, e.g. 11% under PMK 131/2024) applies on reseller margin (not face value) per PMK 6/2021
- **Bill payments**: typically exempt from PPN (pass-through)
- **Vouchers and gift cards**: PPN on issuance, not on redemption
- **Cross-border streaming (Netflix)**: PPN PMSE applies (PMK 48/2020)

BPP declares correct `ppnRate` per item based on category.

## Regulatory
- **UU 36/1999 tentang Telekomunikasi** — pulsa and mobile data regulated under telecoms law
- **UU 8/1999 tentang Perlindungan Konsumen** — applies to all digital purchases
- **PMK 6/2021** — PPN on pulsa, kartu perdana, token listrik
- **PMK 48/2020** — PPN PMSE for cross-border digital services

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`schema/extensions/trade/resource/v1/README.md`](../../../../schema/extensions/trade/resource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`schema/extensions/trade/offer/v1/README.md`](../../../../schema/extensions/trade/offer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`schema/extensions/trade/commitment/v1/README.md`](../../../../schema/extensions/trade/commitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`schema/extensions/trade/consideration/v1/README.md`](../../../../schema/extensions/trade/consideration/v1/README.md) |
| `trade/contract/v1` | See pack README | [`schema/extensions/trade/contract/v1/README.md`](../../../../schema/extensions/trade/contract/v1/README.md) |
| `core/payment/v1` | See pack README | [`schema/extensions/core/payment/v1/README.md`](../../../../schema/extensions/core/payment/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.

