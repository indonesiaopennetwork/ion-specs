# TradeParticipant v1

**Schema:** `IONTradeParticipant`

`IONTradeParticipant` attaches to `Participant.participantAttributes`. It
inherits the common `IONParticipant` fields and adds the billing address used
for the trade transaction.

| Inherited property | Type | Meaning |
|---|---|---|
| `role` | string enum | Participant role in the trade relationship or transaction. |
| `person` | NFH `Person/2.0` | Natural-person identity details. |
| `organization` | NFH `Organization/2.0` | Organization identity details. |
| `billingAddress` | ION `IONAddress/v1` | Billing address associated with the participant for the trade transaction. |

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-11-14 | Added the Trade participant extension over common `IONParticipant`. |
