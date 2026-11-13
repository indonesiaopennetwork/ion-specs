# ION Address — Overview

Maintains the standard Beckn postal-address fields while adding an
`addressAttributes` extension point. `IONAddress` supplies the Indonesian
administrative hierarchy below city level.

## Why this exists
Indonesian last-mile delivery relies on RT/RW identifiers. Riders in kampung areas and dense residential zones use RT and RW to locate houses — street names alone are insufficient. Kelurahan and kecamatan are required for logistics zone resolution and tax jurisdiction assignment.

## Use through addressAttributes
A complete delivery address keeps standard fields such as `streetAddress` and
`postalCode` directly on Address and places Indonesian details under
`addressAttributes`.

## BPS province codes
All 34 provinces encoded with `BPS-` prefix plus the 2-digit BPS numeric code. Used for serviceability polygon assignment, tax zone determination, and logistics pricing zones.
