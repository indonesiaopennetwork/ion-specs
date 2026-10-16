# IdentifiableLocation v1 overview

Some protocol objects need to refer to a location more than once or associate
domain-specific facts with it. Array positions and geometry comparison are not
stable identifiers, while the pinned Beckn Location 2.0 has no `id` field.

IdentifiableLocation supplies that missing reference boundary without modifying
the vendored dependency. Its `geo` and `address` fields reference the matching
properties of Beckn Location, while `id` is governed by the enclosing ION object
or transaction scope. The flat layout lets a future Beckn Location with an `id`
replace this temporary shape without changing consumer field paths.

