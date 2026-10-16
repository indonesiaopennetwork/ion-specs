# LogisticsParticipant v1

This pack describes logistics roles carried by a core Beckn `Participant` and
organizes Indonesian driver and customs-broker identifiers as typed licences.

It attaches at `Participant.participantAttributes`. Core participant identity,
descriptor, contact presentation, assignments, live location, and availability
remain outside this pack.

## Design decisions

- `participantRoles` is the minimal role discriminator needed by Logistics flows.
- `COURIER` and `DRIVER` remain distinct even when one person performs both roles.
- SIM and PPJK identifiers are ION-layer data with Indonesian residency metadata.
- Licence validity and evidence are deferred because they were not in the legacy source.

## Validation

```powershell
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics\LogisticsParticipant\v1
```
