# IONParticipant v1

`IONParticipant` is the common participant attribute bag for ION transactions.
It attaches to `Participant.participantAttributes` and combines a role
discriminator with NFH `Person` or `Organization` identity details.

## Properties

| Property | Type | Meaning |
|---|---|---|
| `role` | string enum | Participant role: `BUYER`, `PROVIDER`, `DRIVER`, `COURIER`, or `CUSTOMS_BROKER`. |
| `person` | NFH `Person/2.0` | Natural-person identity details. |
| `organization` | NFH `Organization/2.0` | Organization identity details. |

The fields are optional at the schema layer so message patterns and network
policy can require the appropriate identity form for each lifecycle step.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-11-14 | Added the common ION participant role and identity attributes. |
