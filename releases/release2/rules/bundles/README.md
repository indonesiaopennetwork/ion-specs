# Generated bundles

`ion-release2-policy.tar.gz` is the canonical Release 2 OPA bundle. While the
release remains a draft, it is signed with an ephemeral non-production ES256
key. `TEST-ONLY-ion-release2-policy-public.pem` verifies that draft signature;
it cannot sign or modify a bundle and must not be treated as an ION production
key.

The bundle contains only production Rego modules, `data.json`, OPA's manifest,
and its embedded signature. Tests, fixtures, documentation, caches, and private
keys are excluded. Repository validation compares its logical file bytes with
the approved sources, checks safe and unique archive paths, enforces ONIX's
10 MiB limit, verifies ES256 with key ID `default`, and evaluates the public
query through OPA.

ES256 signatures are non-deterministic, so freshness is based on the signed
logical inventory and source hashes rather than rebuilding and comparing gzip
bytes. Rebuild the draft artifact explicitly from the repository root:

```bash
ruby tools/rego/build_bundle.rb --write --test-sign releases/release2
```

This rotates the ephemeral test key and replaces each draft artifact atomically
after verification. Publication must replace the draft signature
through the controlled external-key interface documented in
`tools/rego/README.md`; ad hoc and unsigned bundles must not be committed.
