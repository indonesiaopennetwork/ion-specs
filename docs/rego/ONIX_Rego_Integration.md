# Configure ONIX to use an ION Rego bundle

This guide is for an ONIX operator who wants to load and test an ION
release-qualified policy bundle directly. The configuration pattern is the same
for later releases; the bundle path, verification key, OPA query, and test
fixtures must all come from the same selected release.

Release 2 is the current worked example. It and its committed bundle remain
drafts until Release 2 is published. ION currently co-hosts the bundle and its
public verification key on the GitHub-backed `schema.ion.id` origin. This
deliberately favors operational simplicity over an independent key trust
channel; see the architecture decision linked below.

## Select one release consistently

Before configuring ONIX, open the selected release's `rules/README.md` and use
the values it declares. Do not combine artifacts from different releases.

| Value | Release 2 example | Later release pattern |
|---|---|---|
| Release tree | `releases/release2/rules/` | `releases/releaseN/rules/` |
| Bundle | `ion-release2-policy.tar.gz` | Release README's canonical bundle |
| Public query | `data.ion.release2.result` | Release README's public query |
| Verification key | Release 2 public key below | Key published for that exact bundle |
| Fixtures | `releases/release2/rules/tests/fixtures/` | Selected release's fixtures |

For example, Release 3 is expected to use Release 3 paths and a
`data.ion.release3.result` query, but its own `rules/README.md` remains the
authority when that release is created.

ION currently standardizes on direct `type: bundle` configuration rather than
ONIX `type: manifest`. Current manifest resolution gives one `networkId` one
active bundle and cannot represent an intentional transition where different
NPs use different integer releases on the same network. Direct configuration
lets each NP select its supported release explicitly. See
[`ION_Rego_Architecture.md`](ION_Rego_Architecture.md#why-the-network-policy-manifest-is-deferred)
for the full decision and the conditions for revisiting it.

This selection is per ONIX deployment, not per message. The selected bundle is
applied to every message matching the configured `networkId`. An NP changing
releases must update the bundle URL, query, and verification key as one reviewed
configuration change and follow the network's compatibility and cutover
guidance.

## Release 2 values

Use these release-qualified URLs after the corresponding changes are deployed
from `main` to `schema.ion.id`:

- bundle: `https://schema.ion.id/release2/rules/bundles/ion-release2-policy.tar.gz`
- public key: `https://schema.ion.id/release2/rules/bundles/ion-release2-policy-public.pem`
- OPA query: `data.ion.release2.result`
- current integration-test network ID: `ion.id`

The raw public-key response is PEM. ONIX accepts a PEM response body directly;
it does not need a DeDi-shaped JSON wrapper. The public key is deliberately
loaded from the same release path as the bundle. It becomes immutable together
with the rest of Release 2 when that release is published.

## Create the ONIX network-policy config

Create `config/ion-network-policies.yaml` in the ONIX deployment:

```yaml
networkPolicies:
  ion.id:
    type: bundle
    location: https://schema.ion.id/release2/rules/bundles/ion-release2-policy.tar.gz
    query: data.ion.release2.result
    fetchTimeoutSeconds: "30"
    verification:
      enabled: true
      publicKeyLookupUrl: https://schema.ion.id/release2/rules/bundles/ion-release2-policy-public.pem
      algorithm: ES256
```

Do not configure `verification.signatureLocation` for a bundle. Its signature is
inside the archive. ONIX looks up the embedded key ID `default` and verifies it
with the configured ES256 public key.

Policy selection is an exact match on `context.networkId` (with
`context.network_id` as a compatibility fallback). With the configuration
above, a different network ID has no matching policy and is not evaluated. Do
not add a `default` entry unless applying ION rules to unmatched networks is an
intentional operator decision.

## Enable the plugin in every applicable handler

In each ONIX module that receives or sends ION messages, configure the plugin:

```yaml
plugins:
  checkPolicy:
    id: opapolicychecker
    config:
      networkPolicyConfig: ./config/ion-network-policies.yaml
      refreshInterval: "5m"
      debugLogging: "false"

steps:
  - validateSign
  - validateSchema
  - checkPolicy
  - addRoute
```

The ordering is normative for this integration: `validateSchema` must precede
`checkPolicy`. The module must also retain its existing `schemaValidator` plugin
configuration for `validateSchema`; the abbreviated fragment above adds only the
policy plugin. ION Rego rules assume that ONIX has already rejected malformed
messages. Review every applicable caller and receiver module because ONIX step
lists are configured per module.

`debugLogging: "false"` avoids verbose evaluation logs. Normal policy diagnostics
include network ID, action and message correlation identifiers, but not the full
message body.

## Expected behavior

For the Release 2 example, ONIX must report at startup that it loaded a `bundle`
for network `ion.id`, query `data.ion.release2.result`, and the three Release 2
modules. Startup must fail if the bundle cannot be fetched or its signature
cannot be verified.

For an applicable, structurally valid message:

- a valid policy result continues through the handler;
- a rule violation produces HTTP 400/NACK with code
  `POL_ELIGIBILITY_NOT_MET` and a message containing its `ION-R2-*` rule ID;
- an incorrect query is fail-closed and produces `POL_GENERIC_ERROR`;
- an unrelated action returns a valid empty result; and
- an unmatched network ID is skipped when no `default` policy is configured.

The ready-made inputs live under `releases/release2/rules/tests/fixtures/`.
Useful negative fixtures are:

- `common/payment-paid-missing-paid-at.json` → `ION-R2-COM-0001`;
- `trade/provider-temporarily-closed-missing-until.json` →
  `ION-R2-TRD-0001`; and
- `trade/provider-central-missing-entity.json` → `ION-R2-TRD-0002`.

Remove each fixture's `_meta` member before sending it as a protocol message if
the configured schema validator rejects undeclared top-level properties.

## Updating the draft bundle

Before Release 2 publication, the files behind the URLs above can change when a
Rego change is deployed. `refreshInterval` makes ONIX periodically refetch and
recompile the policy. A failed refresh keeps the last valid loaded policy;
inspect ONIX logs after an update.

For a controlled test, pin or copy the bundle and public key together. Never
combine a newly signed bundle with an older public key. Production adoption must
wait until Release 2 is published and this exact artifact pair becomes
immutable.
