# Release 1 Notices

**Status:** Draft release; dependency inventory complete

Release 1 vendors files from these official Beckn repositories at immutable
commits:

- `beckn/protocol-specifications-v2` at
  `a22300aa83796cb8dfc2b63cd9dd0e36a7f4d3a1`;
- `beckn/schemas` at `b0ffbdd409c2fbe988a344161345a88ebb11d544`;
- `beckn/local-retail` at `280726e123f907173f31db840931426045fcfd52`.

The corresponding license texts are preserved at:

- `vendored/beckn/licenses/protocol-specifications-v2/LICENSE`;
- `vendored/beckn/licenses/schemas/LICENSE.md`;
- `vendored/beckn/licenses/local-retail/LICENSE.md`.

The upstream materials identify the license as Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International. The precise upstream and
released SHA-256 values for every dependency are recorded in `release.yaml`.

Ten schema files are byte-for-byte copies of their pinned upstream sources. The
vendored protocol differs only by removal of upstream trailing whitespace, with
no change to its parsed OpenAPI content. Seven schema files—`GeoJSONGeometry`, `Location`,
`PriceSpecification`, `RetailCommitment`, `RetailOffer`, `RetailPerformance`, and
`RetailResource`—contain only a vendoring transformation: active
`schema.beckn.io` `$ref` values were rewritten to permanent Release 1 URLs under
`schema.ion.id`. No semantic vocabulary IRI was rewritten.

This notice covers dependency provenance for the draft. Release 1 remains
unpublished until its content validation and approval gates are complete.
