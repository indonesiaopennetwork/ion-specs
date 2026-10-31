# Release 1 Notices

**Status:** Draft release; dependency inventory complete

Release 1 vendors files from these official Beckn repositories at immutable
commits:

- `beckn/protocol-specifications-v2` at
  `a22300aa83796cb8dfc2b63cd9dd0e36a7f4d3a1`;
- `beckn/schemas` at `b0ffbdd409c2fbe988a344161345a88ebb11d544`;
- `beckn/local-retail` at `280726e123f907173f31db840931426045fcfd52`.

The corresponding license texts are preserved at:

- `schema/vendored/beckn/licenses/protocol-specifications-v2/LICENSE`;
- `schema/vendored/beckn/licenses/schemas/LICENSE.md`;
- `schema/vendored/beckn/licenses/local-retail/LICENSE.md`.

The upstream materials identify the license as Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International. The precise upstream and
released SHA-256 values for every dependency are recorded in `release.yaml`.

`schema/core/api/v2.0.0/ion-beckn.yaml` is the ION-maintained copy of the Beckn
Protocol contract. Its initial contents were copied without changes from
`beckn/protocol-specifications-v2` commit
`df1ade0c6610d4160968177a706f32df680e4758`, with SHA-256
`5afc7586ef1fbc378ea6abb139292dbe85750e4c5ea1a2fd410a40479aadc0f0`. ION then
corrected `DiscoverAction.matchType.default` from the invalid lowercase `any` to
the declared enum value `ANY`, and changed the `/catalog/publish` example's
date-only offer validity values to RFC 3339 date-time values matching the
`TimePeriod` schema. ION subsequently integrated the `beckn.yaml` changes
proposed in Beckn PR #202, "Add AsyncError to on_xxxAction". Those changes make
asynchronous callback envelopes carry `context` and exactly one of `message` or
`error`, and specialize `AsyncError` without reopening the base error object's
property set. The two earlier ION corrections were retained during the
integration. The maintained copy remains subject to the upstream license above.
The immutable vendored contract is retained temporarily as a compatibility URL
while consumers migrate to the ION-maintained path.

The vendored protocol and ten schema files are byte-for-byte copies of their
pinned upstream sources. Seven schema files—`GeoJSONGeometry`, `Location`,
`PriceSpecification`, `RetailCommitment`, `RetailOffer`, `RetailPerformance`, and
`RetailResource`—contain only a vendoring transformation: active
`schema.beckn.io` `$ref` values were rewritten to permanent Release 1 URLs under
`schema.ion.id`. No semantic vocabulary IRI was rewritten.

This notice covers dependency provenance for the draft. Release 1 remains
unpublished until its content validation and approval gates are complete.
