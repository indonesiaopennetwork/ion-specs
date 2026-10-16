# ION Release 1 Logistics Error Migration Ledger

**Status:** Phase 7 complete  
**Legacy source:** `indonesiaopennetwork/ion-specs` at
`33e6b4c40feabecf6b0f6a827b488ff82998c735`, `errors/logistics.yaml`  
**Release source:** `releases/release1/errors/logistics.yaml`  
**Machine-readable disposition:**
`tools/release/release1-logistics-error-map.yaml`

## Result

All 97 legacy Logistics error codes were reviewed individually. Thirty errors
have a connected Release 1 schema field, supported callback, applicable flow or
policy target, and actionable recovery path, so they are included. Sixty-seven
are deferred with a named reason in the migration map.

Legacy `ION-LOG-NNNN` identifiers are retained as provenance only. Included
errors use the current sector convention `ION-BNNNN`; this avoids publishing a
second Logistics code namespace while keeping every migration decision
traceable.

Every included entry names an `on_*` callback sent by the BPP in the pinned
protocol contract. The callback therefore identifies the error sender without
adding a second sender field that is absent from the current shared error
shape. Recovery text was rewritten to use only included protocol actions and
Release 1 objects.

## Included errors

| Area | Included legacy codes | Count |
|---|---|---:|
| Delivery attempts and cancellation | `5001`, `5004`, `5101`, `5102` | 4 |
| Service eligibility, quote, capacity, and SLA | `6001`, `6002`, `6003`, `6004`, `6005`, `6006`, `6008`, `6009`, `6011`, `6108`, `6111`, `6122` | 12 |
| Measurement dispute | `6201` | 1 |
| Cross-border compliance | `6404`, `6405` | 2 |
| Ro-Ro | `6501`, `6502`, `6505` | 3 |
| Warehousing | `6601`, `6602` | 2 |
| Participant roles | `6801` | 1 |
| During-transaction payment | `6904`, `6905` | 2 |
| Incident handling | `7001`, `7003` | 2 |
| Policy governance | `9004` | 1 |
| **Total** | | **30** |

`ION-B6009` is intentionally connected to the provider cold-chain capability
but has no `flow_ref`: Release 1 can reject a selection that exceeds a declared
capability without publishing the separately deferred cold-chain execution
variant. All other included flow and policy targets resolve to committed files.

## Deferred errors

| Reason | Count |
|---|---:|
| Cross-sector transport, authentication, registry, or feature error | 12 |
| Missing maintained jurisdictional or regulatory rule | 7 |
| Informational, successful, or predictive condition rather than an error | 6 |
| Deferred eKYC, framework-agreement, or warehouse branches | 15 |
| Deferred address-attempt or customs-remediation branches | 8 |
| Missing business-tax lifecycle | 4 |
| Deferred cash-on-delivery or cold-chain semantics | 5 |
| Missing participant, cross-BPP authorization, or payment-offer rule | 5 |
| Deferred dimension dispute, Ro-Ro rebooking, driver safety, or `raise` action | 4 |
| Missing Offer-level maximum-dimensions constraint | 1 |
| **Total** | **67** |

The machine-readable map is authoritative for the exact code-to-reason
assignment. In particular, success notifications and predicted risk markers
remain state, event, or alert data; they are not promoted into protocol errors.

## Validation

The dedicated validator checks code and category conventions, required fields,
HTTP status ranges, supported callbacks, schema directories, exact JSON
Pointers, flow and policy targets, registry equality, and migration-map
closure. When the legacy checkout is available, it also proves that the map
covers the pinned 97-code source exactly:

```bash
ruby tools/release/validate_logistics_errors.rb \
  --source-root ../ion-specs-ion-launch releases/release1
ruby tools/release/generate_error_registry.rb releases/release1
ruby tools/release/validate_release.rb releases/release1
```

Phase 7 does not change Logistics from `review-required` to `validated`.
That release-state decision belongs to the Phase 8 closure review.
