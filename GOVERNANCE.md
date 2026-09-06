# ION Network Specification Governance

## ION Council

The ION Council approves release scope, public compatibility decisions, sector
activation, policy registries, publication into the `next` channel, promotion to
`current`, and LTS support dates and extensions. Publication requires at least
two Council approvals.

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
publication. Excluded content is not a supported part of that release.

Only published releases may be assigned to `next`, `current`, or LTS. Publishing
a draft and assigning it to `next` happen together. Promotion from `next` to
`current` is discretionary after the minimum stabilization period. The Council
may instead supersede `next` with a later published release. Published releases
remain immutable whether or not they have a channel assignment.

A published release that is superseded while still `next` may become unchannelled
and unsupported. A release that has served as `current` must instead enter LTS
when it leaves `current` and remain supported through its recorded
`supportedUntil` date. The Council has not yet adopted a minimum LTS duration;
three months is a planning estimate rather than a governance commitment.

## Change process

1. Open an issue describing the proposed behavior and compatibility impact.
2. Make the change in the applicable draft release.
3. Run `ruby tools/release/validate_release.rb <release-directory>`.
4. Obtain review from the responsible schema or sector working group.
5. Obtain Council approval for scope, breaking, or publication changes.
6. Merge the approved draft into `main`.

Publication into `next` additionally requires the publication gate, Council
approval, release metadata, a protected release tag, channel metadata, and
immutable-directory enforcement. Channel promotion never modifies the published
release contents.

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
excluded. If published, Release 1 will first enter the `next` channel and begin
its stabilization period.
