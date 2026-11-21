# ION Address Extension — Overview

Provides a complete Indonesian address by combining every Beckn `Address/2.0`
property with the Indonesian administrative hierarchy below city level.

## Why this exists
Indonesian last-mile delivery relies on RT/RW identifiers. Riders in kampung areas and dense residential zones use RT and RW to locate houses — street names alone are insufficient. Kelurahan and kecamatan are required for logistics zone resolution and tax jurisdiction assignment.

## Beckn Address composition

The object preserves the flat Beckn wire fields `addressCountry`,
`addressRegion`, `addressLocality`, `streetAddress`, `extendedAddress`, and
`postalCode`. It adds the ION fields to that same object. Property-level
references are used because the upstream Beckn `Address` is closed with
`additionalProperties: false` and therefore cannot be extended using `allOf`.

## BPS province codes
All 34 provinces encoded with `BPS-` prefix plus the 2-digit BPS numeric code. Used for serviceability polygon assignment, tax zone determination, and logistics pricing zones.
