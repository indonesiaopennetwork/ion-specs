# Remaining conformance execution — engineering handoff

Use the real clean Git branch matching the source ZIP and apply the proposed overlay after review. The supplied Testnet Compose references `fidedocker/onix-adapter:latest`; do not treat that tag as a pinned conformance result. The ion-specs official optional ONIX integration CI pins `beckn/beckn-onix` revision `bbfb517114e1cefc63b72423d8dfdc4ad13c0191` and Go 1.26.1. Official release validation pins OPA 1.15.2. Use Ruby 3.3 and a UTF-8 locale. Docker is required for the ION Testnet; OPA CLI and the actual ONIX source were unavailable here.

## 1. Compile and test policy source; rebuild bundle
Run from the integrated ion-specs root with OPA 1.15.2 installed and on PATH:
```
opa fmt -w releases/release2/rules/rego releases/release2/rules/tests
ruby tools/rego/generate_registry.rb --write releases/release2
ruby tools/rego/validate_sources.rb releases/release2
ruby tools/rego/validate_scaffold.rb releases/release2
ruby tools/rego/build_bundle.rb --ephemeral-sign --write releases/release2
ruby tools/rego/verify_bundle.rb releases/release2
ruby tools/release/validate_release.rb releases/release2
```
Formatting changes should be reviewed and committed; generated registry must match the resulting source. Use the proper Git comparison base in CI. Never deploy an old signed bundle against changed rule source. The draft publication gate should remain closed.

## 2. Direct ONIX integration
Obtain the pinned upstream ONIX checkout (the provided `ion-onix` ZIP is configuration and Testnet, not that source). Execute the official test harness:
```
ruby tools/rego/test_onix_integration.rb --onix-root /path/to/pinned/beckn-onix
```
Ensure its coverage includes Hospitality positive and rule-invalid examples; add fixtures/tests in the Go integration harness as needed. Passing only the existing common/Trade test is insufficient.

## 3. Testnet adapter configuration
`testnet/config/local-simple-bap.yaml` and `local-simple-bpp.yaml` currently point to Release 1 `ion-beckn.yaml` and `ion-additional.yaml`; some receiver paths use `extendedSchema_enabled: "false"`. Do not simply switch to public draft Release 2 URLs (unsupported until publication). Stage the candidate schema locally with:
```
ruby tools/release/stage_schema_validator_tree.rb releases/release2 /absolute/path/ion-r2-stage
```
Run staging in the same filesystem namespace/path as the validator or provide an equivalent container mount at that exact absolute path. The official staging tool emits absolute file refs and an `extended-schemas` type index. Configure the actual pinned ONIX schema validator to use those local core and auxiliary schema paths, enable extension validation on caller and receiver paths, and configure the staged extension root per that version's supported parameters. Confirm signed OPA bundle configuration and `data.ion.release2.result` query using the supplied `releases/release2/rules/README.md` and official integration harness. Review actual plugin configuration, route ordering, registry and cache settings rather than assume a field name not present in the supplied config. Testnet compose and configuration scripts are in the supplied `ion-onix` archive; follow its local test instructions using isolated test identities and no live credentials. Pin the actual adapter image digest used. No Testnet config is overwritten by this package.

## 4. Message and business-state tests
- Core/extension acceptance and rejection (including all four Hospitality rule-negative fixtures). Record HTTP ACK/NACK and callbacks.
- Generate runtime timestamps, TTL, unique IDs and valid signature headers; verify registry resolution, Ed25519, request digest, signed ACK, replay rejection and callback correlation. Never replay the static fixture dates or identities into production.
- Publish five catalogue examples, verify actual index/filter behaviour and discover corresponding events. Confirm category and resource/offer identity closure.
- Execute all 43 primary scenarios and the `api-examples/BRANCH_TEST_PLAN.md` branches with persistent BAP/BPP inventory and payment/admission test doubles. Test competing holds, expiry, payment failure/late capture, duplicate requests, atomic mixed baskets, refunds, upgrades, both race orderings, revised event consent, complaint escalation and settlement disputes. Verify financial and entitlement state before/after each operation.
- Record pass/fail per scenario and assertion; preserve failed traces. Approve draft policy IRIs, partial cancellation semantics, zero-payment behaviour, canonical Tax and due-date/fee choices before changing manifest maturity.

## Acceptance
Release 1 unchanged; actual Git CI gate passes; signed candidate bundle built and verified; extension schemas and Rego enforced by pinned ONIX; positive and negative message tests pass; all runtime branch acceptance tests pass; product, protocol, policy and engineering owners approve. Only then consider merge/publication. This handoff is an execution plan, not evidence that these commands were run here.
