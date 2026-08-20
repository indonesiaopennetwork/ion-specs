# ION Release Architecture

**Status:** Accepted — implementation pending  
**Decision date:** 2026-08-21  
**Decision owners:** ION Council  

## Purpose

This document defines how the ION Network Specification is packaged, published,
addressed, and preserved. It is the target architecture for the repository
reorganization. Existing repository paths and references remain in place until the
migration described here is implemented.

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

Integer release numbers identify complete ION bundles. They do not replace the
versions of components contained within a bundle. For example, `release1` may
contain Beckn Protocol `v2.0.0`, Beckn domain schema `RetailResource` version
`2.1`, and ION attribute pack `TradeResource` version `v1`.

## Release contents

A release contains all normative artifacts needed to understand and validate that
version of ION, together with its vendored dependencies. The target layout is:

```text
releases/
  release1/
    release.yaml
    README.md
    NOTICES.md

    core/
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

    vendored/
      beckn/
        protocol/
          v2.0.0/
            beckn.yaml
        schemas/
          <SchemaName>/
            <upstream-version>/
              attributes.yaml

    flows/
    policies/
    errors/
    docs/
    dist/
```

`common/` contains ION attribute packs that apply across sectors.
`extension/<sector>/` contains sector-specific attribute packs. The final mapping
from existing pack names to public `SchemaName` directories MUST be established as
part of the pre-release cleanup. Once published, directory names are part of the
public API and cannot be renamed within that release.

Repository tooling and contributor documentation may remain outside `releases/`
when they are not normative release artifacts. A release MUST NOT depend on those
external files to resolve or validate its specifications.

## Public URL namespace

The public URL for a released artifact mirrors its path below the repository's
`releases/` directory:

```text
Repository path:
releases/release1/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml

Public URL:
https://schema.ion.id/releases/release1/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml
```

Additional examples:

```text
releases/release1/common/LocalizedLanguage/v1/attributes.yaml
https://schema.ion.id/releases/release1/common/LocalizedLanguage/v1/attributes.yaml

releases/release1/extension/trade/TradeResource/v1/attributes.yaml
https://schema.ion.id/releases/release1/extension/trade/TradeResource/v1/attributes.yaml
```

`schema.ion.id` is the stable public origin. Its Nginx configuration serves the
corresponding files from the `main` branch of this repository. Conceptually:

```text
https://schema.ion.id/releases/release1/<path>
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
  - $ref: https://schema.ion.id/releases/release1/vendored/beckn/schemas/RetailResource/2.1/attributes.yaml#/components/schemas/RetailResource
```

Published `attributes.yaml` files MUST NOT use repository-relative `$ref` paths.
They also MUST NOT resolve validation dependencies directly from
`schema.beckn.io`, GitHub, or another external origin.

A release MUST NOT reference schemas in a different ION release. In particular,
files in `release2` must not retain `$ref` values under the `release1` namespace.
All dependencies required by `release2` must also be present within `release2`.

JSON Schema mirrors and generated distributions are subject to the same dependency
closure rule. Their reference syntax may follow the requirements of their format,
but every non-fragment reference must resolve within the same release namespace.

### JSON-LD contexts

An `@context` value that identifies an ION-hosted context document SHOULD use the
release-qualified URL of that document:

```json
{
  "@context": "https://schema.ion.id/releases/release1/extension/trade/TradeResource/v1/context.jsonld"
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
release: 1
status: draft
publishedAt: null
publicBaseUrl: https://schema.ion.id/releases/release1/
sourceBranch: main
dependencies: []
```

Before publication, `status` is changed to `published`, `publishedAt` is populated,
the dependency inventory is complete, and release checksums are recorded. The final
manifest schema and checksum representation will be defined with the release
tooling.

## Lifecycle and immutability

1. Create the next integer release by copying the most recent published release.
2. Set the new manifest status to `draft`.
3. Rewrite release-qualified document references to the new release namespace.
4. Apply approved specification and dependency changes.
5. Regenerate derived artifacts.
6. Validate the complete release locally with network access disabled.
7. Merge the reviewed release into `main` and mark it `published`.
8. Create a matching protected Git tag, such as `release1`, for provenance.
9. Prevent all subsequent modifications or deletions under that release directory.

Draft paths may be visible from `main`, but they are not stable or supported until
the manifest says `published`. Only published release URLs carry the permanence
guarantee.

A mutable convenience pointer to the current release may be provided outside the
release directories, but it is non-normative. Implementations and specifications
MUST reference an explicit `releaseN` URL.

## Validation and enforcement

Repository validation MUST be release-aware and MUST support deterministic mapping
between a public URI prefix and the local release directory:

```text
https://schema.ion.id/releases/release1/
  <-> releases/release1/
```

For every release, automated checks must:

- parse all YAML, JSON, and JSON-LD artifacts;
- resolve every schema `$ref` and JSON Pointer fragment;
- reject schema references outside the current release namespace;
- verify the complete vendored dependency inventory and checksums;
- validate examples against their schemas;
- check the alignment of `attributes.yaml` and `schema.json` mirrors;
- rebuild and verify generated distribution artifacts;
- validate successfully with network access disabled; and
- reject changes to directories whose manifest status is `published`.

The same checks should verify that every published public URL maps to the expected
repository file and that Nginx returns appropriate content types for YAML, JSON,
and JSON-LD resources.

## Compatibility and governance

The integer release number is the public compatibility boundary for a complete ION
specification bundle. Implementations must declare which integer release they
support. The compatibility impact of a new release must be documented, even though
the number itself does not encode major, minor, or patch semantics.

Existing notice periods and ION Council approval requirements continue to apply.
Publication requires Council approval. The release notes must identify breaking,
additive, corrective, and documentation-only changes explicitly.

Current documentation that prescribes semantic bundle versions, mutable remote
schema dependencies, or relative references describes the pre-migration layout.
It must be updated during the cleanup and migration, but this decision document is
the authority for the target release architecture.

## Migration principles

The migration to `release1` will be performed separately from this decision. It
must follow these principles:

1. Inventory and classify existing URLs as schema references, context document
   URLs, semantic IRIs, source citations, or prose examples.
2. Establish the canonical public `SchemaName` and repository path for each
   existing pack before publishing it.
3. Obtain the complete transitive Beckn dependency closure from immutable upstream
   revisions.
4. Move the normative specification into `releases/release1/` without maintaining
   a second editable source tree.
5. Rewrite resolvable references to the `release1` public namespace.
6. Update generated mirrors, distributions, examples, flows, policies, errors,
   documentation, licensing, and tooling together.
7. Prove local, offline, and public-URL resolution before publication.

Cleanup unrelated to producing a correct first release should be deferred so that
the migration remains reviewable.
