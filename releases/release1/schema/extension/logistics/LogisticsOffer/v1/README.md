# LogisticsOffer v1

This pack describes catalog-time logistics service capabilities and calculation
inputs. It attaches to `Offer.offerAttributes`; core Offer owns identity,
description, validity, Resources, add-ons, and proposed Considerations.

Rate cards express calculation inputs rather than a final fare. Published and
agreed amounts remain in core and Contract Considerations. Mutable capacity is
excluded from catalog offers.

Technical API rate limits, endpoint latency promises, and framework-agreement
targeting are deferred pending dedicated protocol mechanisms.

## Validation

```powershell
go run ./cmd/schemav2validator schema-dir --json C:\work\ion\repos\ion-specs\releases\release1\schema\extension\logistics\LogisticsOffer\v1
```
