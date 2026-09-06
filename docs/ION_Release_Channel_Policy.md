# ION Release Channel Policy

**Status:** Proposed maintainer policy

## Purpose

ION publishes immutable integer releases and uses mutable channel labels to
communicate how those releases should be adopted. Release manifests record
whether a release is mutable or permanent. Channels separately identify the
cutting-edge release, the recommended production release, and older releases
with an active long-term support commitment.

This separation lets the ION Council observe a newly published release before
recommending it as `current`, without weakening the permanence of its files or
public URLs.

## Release Status And Channel Assignment

Release status and channel assignment are different concepts:

- `status: draft` means the release is mutable, unpublished, and not assigned to
  a release channel. Feature work happens only in a draft.
- `status: published` means the release is permanent and immutable. A published
  release may be `next`, `current`, LTS, or unchannelled.

Changing a channel never changes release contents. Consumers must reference
explicit release URLs such as:

```text
https://schema.ion.id/release5/schema/...
```

Mutable labels such as `next` and `current` are operational guidance, not schema
retrieval paths.

## Release Channels

ION maintains three channel types:

| Channel | Cardinality | Meaning |
|---|---:|---|
| `next` | Zero or one | The newest published release, containing cutting-edge features and undergoing operational stabilization. |
| `current` | Zero or one | The release recommended for new production integrations. |
| LTS | Zero or more | Former `current` releases in their guaranteed, time-bounded support period. |

A release may occupy only one channel at a time. Every channel entry must refer
to a release whose manifest has `status: published`.

Example:

```text
lts     = release1, release2
current = release3
next    = release4
draft   = release5 (not a channel)
```

In this example, Release 4 is already published and immutable. Release 5 receives
new feature work while Release 4 is observed. The Council may later promote
Release 4 to `current`, but promotion is discretionary rather than automatic.

## Channel State

The repository should record channel state in a small machine-readable file:

```text
releases/channels.yaml
```

Suggested shape:

```yaml
schemaVersion: 1
current: release3
next:
  release: release4
  assignedAt: '2026-09-01T00:00:00Z'
  minimumStabilizationDays: 28
  eligibleForCurrentAt: '2026-09-29T00:00:00Z'
lts:
  - release: release1
    supportedUntil: '2028-12-31'
  - release: release2
    supportedUntil: '2029-12-31'
```

`current` and `next` may be `null`, and `lts` may be empty. The root `README.md`
should display the same state so readers can immediately see the supported
adoption path. Draft releases are identified by their manifests and do not
appear as channels.

## Draft Development

The highest active draft is the feature-development release. It may change until
the Council selects it for publication. Normative changes include schemas,
flows, policies, errors, vendored dependencies, release-local documentation,
generated registries, and manifest fields that affect the release contract.

A draft carries no permanence or support guarantee. Validation may pass while a
release remains a draft, but passing validation does not publish it or assign it
to a channel.

## Publishing A Draft As `next`

When the Council decides that a draft is ready for cutting-edge adoption, the
publication and `next` assignment happen together:

1. Ensure every included content area is validated and every excluded area is
   absent.
2. Populate publication metadata and change the release manifest to
   `status: published`.
3. Assign the release to `next` with `assignedAt`,
   `minimumStabilizationDays`, and `eligibleForCurrentAt`.
4. Run the complete publication gate.
5. Obtain Council approval and merge the publication and channel-state changes
   to `main`.
6. Create and protect the matching integer release tag.
7. Enforce immutability for the published release directory.
8. Create the following integer release as the new mutable draft.

For the first release, publication would produce channel state such as:

```yaml
current: null
next:
  release: release1
  assignedAt: <publication timestamp>
  minimumStabilizationDays: 28
  eligibleForCurrentAt: <publication timestamp + 28 days>
lts: []
```

Release 2 would then become the draft used for feature requests.

## Stabilizing `next`

Stabilization begins when a release is published and assigned to `next`. Because
that release is already immutable, stabilization does not permit normative fixes
or reset a content-change timer. It is an operational observation period in
which implementers and maintainers evaluate interoperability, conformance,
security, and adoption experience.

Problems found during stabilization must be documented and corrected in the
active draft. The Council may extend the observation period or decline to promote
the `next` release. Reaching `eligibleForCurrentAt` only makes promotion
permissible; it never makes promotion automatic.

## Promoting `next` To `current`

After the minimum stabilization period, the Council may promote `next` to
`current` at its discretion:

1. Review stabilization findings and unresolved compatibility risks.
2. Confirm the release remains valid and its immutable artifacts match their
   recorded checksums.
3. Obtain Council approval.
4. Move the `next` release to `current` and set `next: null`.
5. If a previous `current` exists, move it to LTS in the same channel-state
   change and record its `supportedUntil` date.

No release content or manifest status changes during channel promotion; both
releases are already published. A release that has served as `current` must not
become unchannelled or unsupported without first completing its LTS period.

## Replacing `next` Without Promotion

The Council may decide never to make a particular `next` release `current`. When
a later draft is ready, the Council may publish that draft and assign it to
`next`, starting a new stabilization period.

The superseded `next` release then becomes unchannelled unless the Council gives
it another channel designation. Its immutable directory, tag, and explicit
public URLs remain permanently available, but it is not recommended or actively
supported. The existing `current` release remains unchanged.

For example:

```text
before: current = release3, next = release4, draft = release5
after:  current = release3, next = release5, draft = release6
        release4 remains published but unchannelled
```

## Long-Term Support

Every release that leaves `current` must enter LTS. This transition is guaranteed,
not discretionary, and happens in the same channel-state change that installs a
new `current`. The Council records a `supportedUntil` date for the former current
release, and multiple LTS periods may overlap.

The minimum required LTS duration has not yet been decided by the Council. Three
months is the current planning estimate, but it is not an approved policy value
and must not be presented as a guarantee. Until the Council adopts a minimum,
each transition out of `current` must include an explicitly approved future
`supportedUntil` date. This document and any channel-state validation must be
updated when the minimum is ratified.

Because published releases are immutable, LTS support does not permit patches to
an LTS release directory. It means:

- its release files, public URLs, validators, and conformance guidance remain
  available;
- reported security, interoperability, and specification issues are assessed and
  documented;
- maintainers provide migration guidance to a supported replacement when a
  correction requires normative changes; and
- every normative correction is published in a newer integer release.

Before an LTS support date expires, the Council may approve an extension. A
release must not be removed from `lts` before its recorded support date. After
that date, maintainers may remove the entry and end active support. Implementers
may continue using the immutable release but should migrate to `current` or
another supported LTS release.

## Opening The Next Draft

Soon after a draft is published as `next`, create the following integer release
as the new draft baseline:

1. Copy the newly published release to `releases/releaseN+1/`.
2. Set the new manifest to `release: N+1`, `name: releaseN+1`, and
   `status: draft`.
3. Clear `publishedAt` and all other publication-only metadata.
4. Rewrite release-qualified document URLs to the new namespace.
5. Refresh generated registries and artifact checksums.
6. Validate the draft before feature work begins.

The draft is not added to `releases/channels.yaml` until the Council publishes it
as a future `next` release.

## Compatibility Promise

The channel model gives downstream software these guarantees:

- `next` is the newest immutable release and is undergoing a minimum operational
  stabilization period.
- `current` is the Council-recommended target for new production integrations.
- Every release that leaves `current` receives a guaranteed LTS period before it
  can become unsupported; its LTS entry states when that commitment ends.
- An unchannelled published release remains permanently resolvable but carries no
  active recommendation or support commitment. This direct transition is allowed
  for a superseded `next` that never became `current`, but not for a former
  `current`.
- Channel changes never modify a published release or its explicit public URLs.

This policy adds adoption guidance to immutable integer releases without making
channel labels part of the normative schema-addressing contract.
