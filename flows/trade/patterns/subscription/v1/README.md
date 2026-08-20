# B2C Subscription (B2C-SUB)

Recurring purchases on a defined billing cycle. Mandate setup at first confirm; subsequent cycles auto-trigger.

## Applicable categories
Grocery subscriptions, packaged meal kit delivery, supplements, dairy, water delivery, pet food, FMCGorder

## Key additions to B2C-SF
- `subscription.billingCycle`: WEEKLY / FORTNIGHTLY / MONTHLY / QUARTERLY / ANNUAL
- `subscription.nextBillingAt`: updated after each successful billing
- Mandate setup at on_init (UPI Autopay or e-mandate deep link)
- Lifecycle management via /update: PAUSE, SKIP, MODIFY_QUANTITY, RESUME
- Cancellation applies to future cycles; in-progress delivery completes normally

## API sequence
```
Phase 2  select (with billing_cycle tag) → on_select (confirms billing terms)
         init → on_init (mandate setup instructions)
         confirm → on_confirm (subscription created, first cycle scheduled)

Phase 3  Per-cycle: PACKED → DISPATCHED → DELIVERED (as B2C-SF)

Phase 4  update[PAUSE/SKIP/RESUME/MODIFY] — lifecycle management
         cancel[SUBSCRIPTION] — terminate recurring
```

## Performance state machine
`performance-states/v1/states.yaml#standard`
Applies per delivery cycle. Each recurring delivery is a fresh standard run.

## Schema packs

| Pack | Purpose | Reference |
|---|---|---|
| `trade/resource/v1` | See pack README | [`releases/release1/extension/trade/TradeResource/v1/README.md`](../../../../releases/release1/extension/trade/TradeResource/v1/README.md) |
| `trade/offer/v1` | See pack README | [`releases/release1/extension/trade/TradeOffer/v1/README.md`](../../../../releases/release1/extension/trade/TradeOffer/v1/README.md) |
| `trade/commitment/v1` | See pack README | [`releases/release1/extension/trade/TradeCommitment/v1/README.md`](../../../../releases/release1/extension/trade/TradeCommitment/v1/README.md) |
| `trade/consideration/v1` | See pack README | [`releases/release1/extension/trade/TradeConsideration/v1/README.md`](../../../../releases/release1/extension/trade/TradeConsideration/v1/README.md) |
| `trade/performance/v1` | See pack README | [`releases/release1/extension/trade/TradePerformance/v1/README.md`](../../../../releases/release1/extension/trade/TradePerformance/v1/README.md) |
| `trade/contract/v1` | See pack README | [`releases/release1/extension/trade/TradeContract/v1/README.md`](../../../../releases/release1/extension/trade/TradeContract/v1/README.md) |
| `core/payment/v1` | See pack README | [`releases/release1/common/Payment/v1/README.md`](../../../../releases/release1/common/Payment/v1/README.md) |

## Variants

**Always active:** `cross-cutting` — available on all patterns after `on_confirm`: tracking, support, rating, reconciliation, raise escalation. You must implement this regardless of which base pattern you use.

**Conditionally active:** `during-transaction, cancellation` — activate when specific conditions are met. Check each variant's `variant.yaml` for activation conditions. Variant field requirements are **additive** — they add to this pattern's required fields, they do not replace them.


## Using pattern.yaml as your implementation checklist

> **The `pattern.yaml` in this directory is your primary implementation reference.** It lists every field ONIX validates at each API step — use it as your implementation checklist alongside this README. If ONIX rejects a message, look up the step in `pattern.yaml` first.

Variant field requirements are declared in each variant's `variant.yaml` and are additive on top of this pattern's requirements.
