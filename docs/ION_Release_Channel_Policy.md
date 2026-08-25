# ION Release Channel Policy

**Status:** Proposed maintainer policy

## Purpose

ION publishes immutable integer releases and advertises a support window to
help downstream software plan upgrades. The release directories are the permanent
contract. The release channels are operational labels that describe which
releases the network currently supports.

## Immutable Integer Releases

Every published release lives under `releases/releaseN/`.

Once a release is published:

- its files must not be modified or removed;
- its public URLs remain stable;
- corrections and additions go into the next integer release; and
- a protected Git tag records the published state.

Consumers must reference explicit release URLs such as:

```text
https://schema.ion.id/releases/release5/schema/...
```

Mutable channel names such as `current` or `next` are support labels, not schema
retrieval paths.

## Support Channels

ION maintains up to three release channels:

```text
previous -> the prior supported release
current  -> the recommended production release
next     -> the next candidate release under stabilization
```

Example:

```text
previous = release4
current  = release5
next     = release6
```

`previous` gives implementers a supported migration window. `current` is the
default version for production integrations. `next` gives early visibility into
the candidate that will become current after its stabilization period.

## Channel State

The repository should record channel state in a small machine-readable file, for
example:

```text
releases/channels.yaml
```

Suggested shape:

```yaml
schemaVersion: 1
previous: release4
current: release5
next: release6
nextStabilization:
  requiredQuietDays: 28
  lastContentChangedAt: 2026-09-01T00:00:00Z
  eligibleForPromotionAt: 2026-09-29T00:00:00Z
```

The root `README.md` should display the same channel state prominently so human
readers can immediately see the supported upgrade path.

## Stabilizing `next`

`next` is a candidate, not a free-form draft. It should be assigned only after
the release is believed to be feature-complete for promotion.

Every normative content change under the `next` release restarts the quiet
period. Normative content includes schemas, flows, policies, errors, vendored
dependencies, release-local docs, generated registries, and manifest fields that
affect the release contract.

During stabilization:

- keep changes rare and reviewable;
- update `lastContentChangedAt` for every normative change;
- recompute `eligibleForPromotionAt`;
- regenerate affected artifacts; and
- run the complete release gate.

After the quiet period completes, `next` may be promoted only if validation passes
and the ION Council approves the promotion.

## Maintainer Workflow

### Promote Draft To `next`

When a draft release is feature-complete, promote it to the `next` candidate
before it can become `current`. This applies to every release, including
`release1`.

1. Ensure all included content areas are marked `validated` or `excluded`.
2. Run the full release gate:

   ```bash
   ruby tools/release/validate_release.rb releases/releaseN
   ```

3. Update `releases/channels.yaml`:

   ```yaml
   previous: <current previous or null>
   current: <current current or null>
   next: releaseN
   nextStabilization:
     requiredQuietDays: 21
     lastContentChangedAt: <promotion timestamp>
     eligibleForPromotionAt: <promotion timestamp + 21 days>
   ```

For the first release, the channel state should be:

```yaml
previous: null
current: null
next: release1
```

4. Open a pull request for Council review.

### Promote `next` To `current`

After the quiet period:

1. Confirm no normative changes occurred since `lastContentChangedAt`.
2. Run the publication gate for `next`:

   ```bash
   ruby tools/release/validate_release.rb --publication releases/releaseN
   ```

3. Obtain Council approval.
4. Set `releases/releaseN/release.yaml` to `status: published`.
5. Populate publication metadata, including `publishedAt` and `toolingCommit`.
6. Merge the publication pull request to `main`.
7. Create and protect the matching `releaseN` Git tag.
8. Update channels:

   ```yaml
   previous: <old current>
   current: <old next>
   next: null
   ```

For `release1`, the promotion produces:

```yaml
previous: null
current: release1
next: null
```

9. Open the next draft baseline PR for the following integer release.

### Open The Next Draft

Soon after `releaseN` becomes `current`, open a separate pull request to create
`releaseN+1` as the next draft baseline.

1. Copy the published release:

   ```text
   releases/releaseN/ -> releases/releaseN+1/
   ```

2. In `releases/releaseN+1/release.yaml`:

   - set `release: N+1`;
   - set `name: releaseN+1`;
   - set `status: draft`;
   - set `publishedAt: null`;
   - clear publication-only metadata; and
   - update notes for the new draft.

3. Rewrite release-qualified document URLs from `/releaseN/` to `/releaseN+1/`.
4. Refresh generated registries and artifact checksums.
5. Validate the new draft:

   ```bash
   ruby tools/release/validate_release.rb releases/releaseN+1
   ```

Do this as a baseline PR before feature work begins. Feature PRs should then
target the draft `releaseN+1` directory with small, focused changes.

## Compatibility Promise

The channel model gives downstream software two planning guarantees:

- `current` is the recommended target for production implementations.
- `previous` remains supported long enough for planned migration.
- `next` provides advance visibility and will not become `current` until it has
  completed its quiet period without changes.

This policy does not weaken immutable releases. It adds a predictable promotion
rhythm on top of them.
