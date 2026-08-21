# Trade Provider Extension — Overview

Seller operational state and configuration. Published in catalog; used for discovery filtering and UI rendering.

## operationalStatus
`TEMPORARILY_CLOSED` requires `operationalStatus.until` under ION policy. A
consumer application should suppress ordering and show the expected reopening
time when it is available.

## operatingHours
Typed array for ORDER, DELIVERY, SELF_PICKUP, and PREPARATION windows.
`locationId` optionally scopes a window to one `Provider.availableAt` location.
Times use RFC 3339 `time` values.

## invoicing
`CENTRAL` uses the entity referenced by `invoicing.entityId`.
`PER_FULFILMENT_CENTRE` allows each fulfilment centre to invoice independently.

## verification
Only the catalog-visible verification status, validity, and caveats are
published. Sensitive KYC evidence is retained off-network.

ION adds `verification.level`. The provider's actual Indonesian identity is
composed under `businessRegistration`; trust awards are represented by
verifiable `trustMarks[]` documents.
