# ION Network Specification Governance

## ION Council

The ION Council approves release scope, public compatibility decisions, sector
activation, policy registries, and publication of permanent releases. Publication
requires at least two Council approvals.

## Integer releases

ION publishes monotonically increasing integer bundles: `release1`, `release2`,
and so on. Component schemas may retain their own versions inside a bundle.

A release is mutable only while its manifest says `status: draft`. After
publication:

- its directory and public URLs are permanent;
- no file may be modified or removed;
- corrections require the next integer release; and
- a matching protected Git tag records provenance.

Each content area in `release.yaml` must be `validated` or `excluded` before
publication. Excluded source material is not a supported part of that release.

## Change process

1. Open an issue describing the proposed behavior and compatibility impact.
2. Make the change in the applicable draft release or unreleased source area.
3. Run `ruby tools/release/validate_release.rb <release-directory>`.
4. Obtain review from the responsible schema or sector working group.
5. Obtain Council approval for scope, breaking, or publication changes.
6. Merge the approved draft into `main`.

Publication additionally requires the publication gate, Council approval,
release metadata, a protected release tag, and immutable-directory enforcement.

## Extension conventions

Released ION schema extensions must:

- name their Beckn attachment point with `x-beckn-attaches-to`;
- compose with an appropriate pinned vendored Beckn schema;
- use release-qualified `schema.ion.id` URLs for schema dependencies;
- keep JSON-LD semantic IRIs stable;
- follow the schema style and design guides; and
- pass the release and schema-pack validators.

## Release 1 scope

Release 1 includes Trade, its four validated common packs, and vendored Beckn
dependencies. `ion.yaml`, Logistics, Hospitality, and Finance are explicitly
excluded and remain future-release work.
