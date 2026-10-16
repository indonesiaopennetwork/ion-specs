# Release 1 Logistics policy migration ledger

> **Status:** Phase 5 complete  
> **Target:** Shared root policy registry  
> **Legacy source:** `indonesiaopennetwork/ion-specs` at
> `33e6b4c40feabecf6b0f6a827b488ff82998c735`  
> **Machine-readable inventory:**  
> `tools/policies/logistics-policy-migration-map.yaml`

This ledger records the Phase 5 disposition of every policy IRI found in the
pinned legacy Logistics flow tree. Policies remain governed independently of
integer releases. Migration into this repository does not constitute Council
ratification.

## Outcome

The legacy flow tree contains 59 distinct policy-IRI strings:

- 22 baseline Logistics policies had authoritative legacy documents and were
  migrated as separate, normalized `draft` policy sources;
- 7 obsolete legacy IRIs map to already registered policy terms whose semantics
  are reused;
- 3 legacy IRIs are replaced by a more precise migrated Logistics term; and
- 27 IRIs are deferred because they are unsourced, incomplete placeholders,
  enterprise/FWA-specific examples, or require separate legal and semantic
  closure.

Every migrated policy has explicit version, lifecycle, sector, applicability,
bilingual display text, and pinned source provenance. Draft terms deliberately
have no effective or ratification date. The generated registry now contains 89
terms: 28 Trade, 39 cross-sector, and 22 Logistics. The policy registry
generator enforces the Logistics metadata and lifecycle shape.

## Migrated draft families

| Family | Count | Migrated terms |
|---|---:|---|
| Cancellation | 4 | Pre-pickup free, pre-pickup futile-trip fee, in-transit buyer cost, LSP TAT breach |
| Evidence | 2 | Standard photo within 24 hours, cold-chain datalogger |
| Incident | 2 | Standard incident handling, high-severity escalation |
| Insurance | 1 | Standard declared-value cap |
| Liability | 3 | Force-majeure exclusions, loss cap per shipment, COD cap per shipment |
| Penalty | 3 | LSP TAT breach, late COD remittance, pickup failure caused by consignor |
| Delivery re-attempt | 3 | Standard three free, hyperlocal one only, standard two with second-attempt fee |
| RTS handoff | 2 | Standard, cross-BPP timeout |
| SLA | 1 | Standard 95 percent on-time target |
| Weight dispute | 1 | Standard 10 percent tolerance |

Legacy dispute references inside migrated terms were normalized to existing
registered IRIs. Commercial BANI maps to `ion://policy/dispute.commercial.bani`;
commercial ODR and the legacy `network-adjudication` label map to
`ion://policy/dispute.commercial.odr`. The migration-map validator checks that
all policy-to-policy references from Logistics terms resolve.

## Reused or replaced terms

| Legacy IRI | Current IRI | Treatment |
|---|---|---|
| `ion://policy/dispute-resolution.commercial-bani` | `ion://policy/dispute.commercial.bani` | Reuse |
| `ion://policy/dispute-resolution.commercial-odr` | `ion://policy/dispute.commercial.odr` | Reuse |
| `ion://policy/dispute-resolution.consumer-bpsk` | `ion://policy/dispute.consumer.bpsk` | Reuse |
| `ion://policy/dispute.weight-discrepancy` | `ion://policy/weight-dispute.standard-10pct-tolerance` | Replace with typed tolerance policy |
| `ion://policy/incident.accident.standard` | `ion://policy/incident.standard` | Replace with the general incident policy |
| `ion://policy/loss.standard.72hr-threshold` | `ion://policy/liability.loss-cap-per-shipment` | Replace with the liability term that owns the threshold |
| Four legacy `return.*` spellings | Existing canonical Trade return IRIs | Reuse for the underlying returned goods |

The exact four return mappings are recorded in the machine-readable map and
validated against the registry.

## Deferred groups

The 27 deferred strings remain unavailable to Phase 6 flows until their reasons
are resolved:

- cold-chain temperature policies lack an approved policy grammar;
- customs appeals, customs-duty liability, Logistics eKYC, multi-stop
  liability, COD remittance schedules, hyperlocal/multi-stop SLA, freight
  reweighing, and return-unboxing evidence have no authoritative source policy;
- enterprise damage, loss, evidence, re-attempt, and weight-tolerance terms are
  agreement-specific and cannot be promoted as network defaults;
- the framework-agreement instance is party-specific, while its prefix and the
  bare re-attempt IRI are placeholders rather than concrete identifiers; and
- driver insurance requires employment and insurance governance separate from
  transaction cargo liability.

Phase 6 must use the `targetIri` recorded for migrated, reused, or replaced
entries. A branch that needs a deferred IRI must remain deferred or introduce a
separately reviewed policy source; it must not restore the legacy string as an
ad hoc policy.

## Validation

Run the deterministic registry and mapping checks from the repository root:

```bash
ruby tools/policies/generate_registry.rb
ruby tools/policies/validate_logistics_policy_map.rb
ruby tools/policies/validate_logistics_policy_map.rb --source-root ../ion-specs-ion-launch
```

The source-root form additionally proves that all 59 strings in the pinned
legacy Logistics flow tree have exactly one recorded disposition.
