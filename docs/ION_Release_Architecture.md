# ION Release Architecture

**Status:** Accepted — implemented for the Release 1 draft

**Decision date:** 2026-08-21

**Public URL namespace amended:** 2026-08-26

**Decision owners:** ION Council

**Related policy:** `docs/ION_Release_Channel_Policy.md`

## Purpose

This document defines how the ION Network Specification is packaged, published,
addressed, and preserved. It is the target architecture for the repository
reorganization. Release 1 implements this structure; unreleased working material
for later versions is authored in the active draft for a future integer release.

The goals are to ensure that every ION release is:

- complete, including all normative specifications and vendored dependencies;
- permanently available under a release-specific public URL;
- reproducible and independently verifiable;
- isolated from changes made for later releases; and
- resolvable both through `schema.ion.id` and from a local checkout.

## Decision

ION specification bundles use monotonically increasing integer release numbers:

```text
release1
release2
release3
```

Published releases are committed under `releases/` on the `main` branch:

```text
releases/release1/
releases/release2/
```

Each release directory is a complete, permanent specification bundle. Once a
release is published, its files MUST NOT be modified or removed. A correction or
clarification to a published release MUST be issued in a new release directory.

Each release keeps its four principal specification areas at the release root:
`schema/`, `flows/`, `policies/`, and `errors/`. Schema-owned content is not
flattened beside those areas: `core/`, `common/`, `extension/`, and `vendored/`
all live below the release's `schema/` directory.

Integer release numbers identify complete ION bundles. They do not replace the
versions of components contained within a bundle. For example, `release1` may
contain Beckn Protocol `v2.0.0`, Beckn domain schema `RetailResource` version
`2.1`, and ION attribute pack `TradeResource` version `v1`.

## Release contents

A release contains all normative artifacts needed to understand and validate that
version of ION, together with its vendored dependencies. Placement is determined
by whether an artifact defines or explains the behavior of a particular release.

The following artifacts are release-specific and MUST be stored within each
release:

- schemas and vendored schema dependencies;
- error definitions and generated error registries;
- policy definitions and generated policy registries;
- transaction flows and their release-specific examples;
- implementation-facing documentation that describes the release's wire format,
  validation behavior, signing requirements, sectors, or integration process.

The following repository-level material remains outside `releases/`:

- release creation, validation, generation, and maintenance tools;
- repository governance and contribution instructions;
- architecture decisions and schema authoring guidance for future work;
- working notes, review responses, migration plans, and unresolved observations;
  and
- repository automation and continuous integration configuration.

The target repository layout is:

```text
README.md
CONTRIBUTING.md
GOVERNANCE.md

docs/
  ION_Release_Architecture.md
  <architecture and contributor documentation>

tools/
  <release-aware repository tooling>

releases/
  release1/
    release.yaml
    README.md
    NOTICES.md

    schema/
      core/                  # API contract present only when ionApi is included
        api/
          v2.0.0/
            ion.yaml

      common/
        <SchemaName>/
          v1/
            attributes.yaml
            schema.json
            context.jsonld
            vocab.jsonld
            profile.json
            renderer.json
            README.md
            docs/
            examples/

      extension/
        <sector>/
          <SchemaName>/v1/

      vendored/
        beckn/
          protocol/v2.0.0/beckn.yaml
          schemas/<SchemaName>/<upstream-version>/attributes.yaml

    flows/
    policies/
    errors/
    docs/
```

`schema/common/` contains ION attribute packs that apply across sectors.
`schema/extension/<sector>/` contains sector-specific attribute packs. The final mapping
from existing pack names to public `SchemaName` directories MUST be established as
part of the pre-release cleanup. Once published, directory names are part of the
public API and cannot be renamed within that release.

The manifest determines which content areas are part of a particular release.
Every area MUST be `validated` or `excluded` before publication, and artifacts for
an excluded area MUST NOT appear in the release directory. In particular, a
release may omit the aggregate `schema/core/api/.../ion.yaml` when `ionApi` is
`excluded`; standalone validated schema packs remain valid release content.

### Normative release registries and flows

Error codes, policy terms, and transaction-flow requirements affect protocol
behavior and compatibility. The `errors/`, `policies/`, and `flows/` directories
therefore belong inside each release. They MUST remain aligned with the schemas in
that release. Generated registries belong alongside their source definitions in
the release, even when root-level tooling is used to generate them.

There MUST NOT be a second editable copy of these normative directories at the
repository root. Work on the next release happens in its draft release directory.
Published release copies remain unchanged.

### Documentation classification

Documentation is divided by audience and stability:

- The existing root `docs/` directory is retained as the common documentation set.
  During migration, documents remain there by default unless they are explicitly
  identified as describing behavior that differs between integer releases.
- Implementation documentation belongs inside a release when an implementer could
  receive a different answer for a different release. This includes transport and
  signing behavior, field requirements, sector behavior, integration guides, and
  release-specific examples.
- Repository documentation remains at the root when it governs how maintainers
  create future releases or records work that is not part of the normative
  specification. This includes architecture decisions, contributor instructions,
  authoring style guides, working notes, review responses, and migration plans.
- Each release has its own `README.md` and release notes describing its contents,
  compatibility impact, and entry points.

A root-level guide may link to the current release for convenience, but it is not
part of that release and MUST NOT be the sole source of release-specific behavior.
A release-level `docs/` directory is optional and is created only when such
release-specific documentation exists; the common root documentation is not copied
into every release.

### Repository tooling

`tools/` remains at the repository root and evolves independently of published
releases. Tools MUST accept an explicit release directory and remain capable of
validating every published release, for example:

```bash
python tools/validate_release.py releases/release1
python tools/create_release.py releases/release1 releases/release2
```

Generated output belongs to the applicable release. A release manifest SHOULD
record the repository commit or tool version used to generate it, but the complete
toolchain is not copied into every release.

A published release MUST NOT depend on root-level tools or documentation to
resolve its schemas or determine its normative behavior. Tools assist in building
and verifying a release; they are not part of the released protocol contract.

## Public URL namespace

The public URL for a released artifact mirrors its path below the repository's
`releases/` directory. The repository-only top-level `releases/` segment is not
part of the public URL:

```text
Repository path:
releases/release1/schema/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml

Public URL:
https://schema.ion.id/release1/schema/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml
```

Additional examples:

```text
releases/release1/schema/common/LocalizedLanguage/v1/attributes.yaml
https://schema.ion.id/release1/schema/common/LocalizedLanguage/v1/attributes.yaml

releases/release1/schema/extension/trade/TradeResource/v1/attributes.yaml
https://schema.ion.id/release1/schema/extension/trade/TradeResource/v1/attributes.yaml
```

`schema.ion.id` is the stable public origin. Its Nginx configuration serves the
corresponding files from the `main` branch of this repository. Conceptually:

```text
https://schema.ion.id/release1/<path>
  -> https://raw.githubusercontent.com/indonesiaopennetwork/ion-specs/refs/heads/main/releases/release1/<path>
```

The public URL contract is independent of the backing implementation. ION may
later serve the same immutable paths from protected Git tags, object storage, or a
schema registry without changing consumer-facing URLs.

## Schema reference rules

### Resolvable schema references

All `$ref` values authored in a published release MUST use absolute,
release-qualified `schema.ion.id` URLs. This applies to references to ION schemas
and vendored Beckn schemas.

```yaml
allOf:
  - $ref: https://schema.ion.id/release1/schema/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml#/components/schemas/RetailResource
```

Published `attributes.yaml` files MUST NOT use repository-relative `$ref` paths.
They also MUST NOT resolve validation dependencies directly from
`schema.beckn.io`, GitHub, or another external origin.

A release MUST NOT reference schemas in a different ION release. In particular,
files in `release2` must not retain `$ref` values under the `release1` namespace.
All dependencies required by `release2` must also be present within `release2`.

JSON Schema mirrors are subject to the same dependency closure rule. Their
reference syntax may follow the requirements of their format, but every
non-fragment reference must resolve within the same release namespace.

### JSON-LD contexts

An `@context` value that identifies an ION-hosted context document SHOULD use the
release-qualified URL of that document:

```json
{
  "@context": "https://schema.ion.id/release1/schema/extension/trade/TradeResource/v1/context.jsonld"
}
```

This ensures that processing an older message does not silently load a context
document from a newer release.

### Semantic IRIs

Semantic IRIs identify concepts; they are not schema retrieval dependencies.
Existing Beckn vocabulary identifiers therefore remain Beckn identifiers and are
not rewritten merely because the validation schema has been vendored:

```json
{
  "@id": "https://schema.beckn.io/vocab/v2.0.0#Resource"
}
```

Similarly, a `schema.beckn.io` value used only as a vocabulary namespace is not an
external schema dependency. Migration tooling MUST classify URLs by their role and
MUST NOT perform an indiscriminate replacement of Beckn domains.

Format and vocabulary identifiers such as the JSON Schema metaschema URI are also
not release dependencies unless a tool actually dereferences them as part of ION
validation.

## Vendored dependencies

Every external schema needed for validation MUST be copied into the release. The
vendored dependency set is transitive: if a vendored schema references another
external schema, that dependency must also be vendored and made resolvable within
the same release.

Each dependency entry in `release.yaml` MUST record at least:

- dependency and schema name;
- upstream version;
- original source repository and URL;
- immutable upstream commit identifier;
- path within the release;
- checksum of the upstream content;
- checksum of the released content if localization changed it; and
- applicable license and attribution.

Vendored content SHOULD be preserved byte-for-byte. When an upstream `$ref` must be
localized to close the release dependency graph, the transformation MUST be
minimal, recorded in the manifest, and reproducible. Upstream copyright and
license notices MUST be retained in `NOTICES.md` or an accompanying license file.

Vendored schemas are dependencies, not ION-owned extensions. They MUST NOT be
changed to introduce ION behavior. Any ION-specific constraint belongs in an ION
schema that composes with the vendored dependency.

## Release manifest

Every release contains a machine-readable `release.yaml`. At minimum it declares:

```yaml
schemaVersion: 1
release: 1
name: release1
status: draft
publishedAt: null
publicBaseUrl: https://schema.ion.id/release1/
sourceBranch: main
contentStatus:
  ionApi: review-required
  common: review-required
  trade: validation-pending
  logistics: review-required
  hospitality: review-required
  finance: review-required
  flows: review-required
  policies: review-required
  errors: review-required
dependencyStatus: incomplete
dependencies: []
artifactChecksums: {}
```

When the Council publishes a draft into the `next` channel, `status` is changed
to `published`, `publishedAt` is populated, the dependency inventory is complete,
and release checksums are recorded. The final manifest contract is defined in
`tools/release/release-manifest.schema.json` and enforced by the release tooling.

## Lifecycle and immutability

1. Develop approved specification and dependency changes in the active draft.
2. Regenerate derived artifacts and validate the complete release locally with
   network access disabled.
3. When the Council selects the draft for `next`, populate its publication
   metadata and change its manifest to `status: published`.
4. Publish the release and assign it to `next` in the same reviewed change.
5. Create a matching protected Git tag, such as `release1`, for provenance.
6. Prevent all subsequent modifications or deletions under that release
   directory.
7. Begin the `next` stabilization period and create the following integer release
   as the new mutable draft.
8. After the minimum stabilization period, allow the Council to promote `next` to
   `current`, retain it as `next`, or later supersede it with another published
   release.
9. Move every release that leaves `current` into LTS with an explicit support end
   date. A former `current` cannot become unsupported before completing that
   guaranteed LTS period.

Draft paths may be visible from `main`, but they are not stable or supported until
the manifest says `published`. Only published release URLs carry the permanence
guarantee.

The `next`, `current`, and LTS channel labels are mutable, non-normative adoption
guidance recorded outside immutable release directories. Only published releases
may be assigned to a channel. A published release that loses its channel remains
permanently resolvable through its explicit `releaseN` URL. Implementations and
specifications MUST use those explicit URLs rather than channel names.

The complete channel semantics, including discretionary promotion, stabilization,
replacement of an unpromoted `next`, and overlapping LTS commitments, are defined
in `docs/ION_Release_Channel_Policy.md`.

## Validation and enforcement

Repository validation MUST be release-aware and MUST support deterministic mapping
between a public URI prefix and the local release directory:

```text
https://schema.ion.id/release1/
  <-> releases/release1/
```

For every release, automated checks must:

- parse all YAML, JSON, and JSON-LD artifacts;
- resolve every schema `$ref` and JSON Pointer fragment;
- reject schema references outside the current release namespace;
- verify the complete vendored dependency inventory and checksums;
- validate examples against their schemas;
- check the alignment of `attributes.yaml` and `schema.json` mirrors;
- validate successfully with network access disabled; and
- reject changes to directories whose manifest status is `published`.

Channel-state checks should additionally verify that every channel refers to a
published release, no release occupies more than one channel, `next` and `current`
are singletons, every LTS entry has a valid support end date, and a release leaving
`current` enters LTS in the same channel-state change.

The same checks should verify that every published public URL maps to the expected
repository file and that Nginx returns appropriate content types for YAML, JSON,
and JSON-LD resources.

## Compatibility and governance

The integer release number is the public compatibility boundary for a complete ION
specification bundle. Implementations must declare which integer release they
support. The compatibility impact of a new release must be documented, even though
the number itself does not encode major, minor, or patch semantics.

Existing notice periods and ION Council approval requirements continue to apply.
Publication into `next`, promotion from `next` to `current`, replacement of an
unpromoted `next`, and every LTS support date or extension require Council
approval. LTS is mandatory for a release leaving `current`; only its support date
and any extension require a decision. The release notes must identify breaking,
additive, corrective, and documentation-only changes explicitly.

Current documentation that prescribes semantic bundle versions, mutable remote
schema dependencies, or relative references describes the pre-migration layout.
It must be updated during the cleanup and migration, but this decision document is
the authority for the target release architecture.

## Migration principles

The migration to `release1` will be performed separately from this decision. It
is inventoried in `docs/ION_Release1_Migration_Inventory.md` and must follow these
principles:

1. Inventory and classify existing URLs as schema references, context document
   URLs, semantic IRIs, source citations, or prose examples.
2. Establish the canonical public `SchemaName` and repository path for each
   existing pack before publishing it.
3. Obtain the complete transitive Beckn dependency closure from immutable upstream
   revisions.
4. Move the normative specification into `releases/release1/` without maintaining
   a second editable source tree.
5. Rewrite resolvable references to the `release1` public namespace.
6. Move normative flows, policies, errors, and implementation documentation into
   the release; classify remaining documentation as repository-level material.
7. Update release-aware root tooling and regenerate mirrors, registries, and
   examples without creating root-level normative copies.
8. Prove local, offline, and public-URL resolution before publication.

Cleanup unrelated to producing a correct first release should be deferred so that
the migration remains reviewable.
