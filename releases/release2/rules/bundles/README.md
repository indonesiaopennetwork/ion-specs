# Generated bundles

`ion-release2-policy.tar.gz` is the canonical Release 2 OPA bundle.
`ion-release2-policy-public.pem` verifies its embedded ES256 signature. Both
files are committed and published together through
`https://schema.ion.id/release2/rules/bundles/`. They are used by tests and,
after Release 2 publication, by production ONIX deployments.

Each rebuild generates a new ephemeral key pair. The private key exists only in
the build's temporary directory and is destroyed; only the public key and its
matching signed bundle are written here. Rebuilds must therefore replace and
review both files as one change.

The bundle contains only production Rego modules, `data.json`, OPA's manifest,
and its embedded signature. Tests, fixtures, documentation, caches, and private
keys are excluded. Repository validation compares its logical file bytes with
the approved sources, checks safe and unique archive paths, enforces ONIX's
10 MiB limit, verifies ES256 with key ID `default`, and evaluates the public
query through OPA.

ES256 signatures are non-deterministic, so freshness is based on the signed
logical inventory and source hashes rather than rebuilding and comparing gzip
bytes. Rebuild the artifact pair explicitly from the repository root:

```bash
ruby tools/rego/build_bundle.rb --write --ephemeral-sign releases/release2
```

This rotates the ephemeral key and replaces each artifact atomically after
verification. Ad hoc and unsigned bundles must not be committed.
