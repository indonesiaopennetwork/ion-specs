# IdentifiableLocation v1

IdentifiableLocation adds a stable identifier while retaining the Beckn
`Location/2.0` wire layout. It is a reusable common shape for any ION extension
that must refer to a location by identifier.

## Shape

| Property | Type | Meaning |
|---|---|---|
| `id` | string | Identifier unique within the enclosing object or transaction scope. |
| `geo` | vendored Beckn `Location.geo` | Authoritative geometry. |
| `address` | vendored Beckn `Location.address` | Optional postal address. |

The shape references the individual `geo` and `address` property definitions
rather than copying their schemas. JSON Schema inheritance cannot be used because
the pinned Beckn Location has `additionalProperties: false`; an `allOf` extension
would therefore reject an added `id` property.

## Migration intent

This is an interim compatibility object. If a later official Beckn Location adds
a stable identifier, new ION releases should reference that version and retire
this shape. Existing `x.id`, `x.geo`, and `x.address` paths will remain unchanged.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-10-16 | Added a reusable identifiable form of Beckn Location 2.0. |

