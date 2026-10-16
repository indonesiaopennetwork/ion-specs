# Release 1 Logistics flow migration ledger

> **Status:** Phase 6 complete  
> **Legacy source:** `indonesiaopennetwork/ion-specs` at
> `33e6b4c40feabecf6b0f6a827b488ff82998c735`  
> **Target:** `releases/release1/flows/logistics/`

This ledger records the reviewed disposition of all six legacy Logistics
patterns and all fifteen variants. “Included” means the Release 1 flow uses only
available protocol actions, migrated schema properties, validated state-machine
IDs, and registered policy IRIs. “Scoped” means unsupported legacy sub-branches
were removed. “Deferred” means no normative flow was added.

## State-machine placement decision

The Phase 4 state registry was initially placed under
`schema/extension/logistics/LogisticsPerformanceStates/`. Phase 6 confirmed that
it is not a message-validation schema: it describes execution graphs selected
by flow profiles, while current state is carried by core
`Performance.status.code`.

The registry therefore moved to
`flows/logistics/state-machines/v1/`. It remains one shared versioned registry,
rather than one file per pattern or variant, because:

- Contract-status aggregation applies across all required Performances;
- recovery flow IDs are referenced from multiple machines;
- Parcel topology machines and the parcel reverse variant share one public
  state vocabulary; and
- splitting the registry would require cross-file uniqueness, reachability, and
  compatibility coordination without improving message validation.

Pattern and variant profiles now sit close to the state registry and select
specific machine fragments. The formal grammar and dedicated validator remain
with the registry. This is flow metadata, not an OpenAPI attribute pack.

## Pattern disposition

| Pattern | Disposition | State-machine selection | Main review outcome |
|---|---|---|---|
| Parcel | Included; reference flow | `parcel-p2p`, `parcel-p2h2p`, or `parcel-p2h2h2p` from confirmed routing topology | Replaced centralized catalog publication with Beckn `discover`/`on_discover`; removed unsupported multi-stop, COD, and eKYC assumptions from the base flow. |
| Hyperlocal | Included | `hyperlocal-pre-assigned` or `hyperlocal-fifo` from agent assignment model | Reused the reviewed generic pre-pickup cancellation and SLA policies; removed unsourced insurance and fast-track-dispute aliases. |
| Freight | Included | `freight-capacity` | Uses typed capacity, route, event, proof, and service-reference structures; freight reverse remains deferred. |
| Ro-Ro | Included | `roro` | Uses typed vehicle cargo, schedule, capacity, and route facts; the separate missed-sailing rebooking flow remains planned. |
| Warehouse | Included | `warehouse-inventory` | Uses typed inventory execution and parent/child Contract relationships; party-specific FWA identifiers are not policy terms. |
| Cross-border | Included base pattern | `xb` | Typed cargo, participant, trade-term, route, event, and proof structures close the base pattern; customs appeals and remediation remain deferred. |

The migrated patterns intentionally contain no legacy examples. Every legacy
example used fields removed or reorganized during Phase 4, and several asserted
deferred policy IRIs. Copying them would produce plausible-looking but invalid
message contracts. New message examples require a separate object-validation
slice before Logistics can become `validated` in Phase 8.

## Variant disposition

| Review order | Variant | Disposition | Included scope or blocker |
|---:|---|---|---|
| 1 | During-transaction | Scoped | Includes BAP-collected electronic prepayment only. COD remittance, FWA, credit, and technical pseudo-cancellation branches are excluded. |
| 2 | Cancellation | Included | Uses Beckn `cancel`/`on_cancel`, typed Contract cancellation data, and four reviewed Logistics cancellation policies. |
| 3 | Cash-on-delivery | Deferred | No authoritative reusable COD remittance-schedule policy; the liability cap and late penalty do not define settlement timing. |
| 4 | Delivery-attempts | Included | Uses `LogisticsPerformance.attempts[]` and three reviewed re-attempt policies; owns flow ID `delivery-attempts`. |
| 5 | Multi-stop | Deferred | The partial-delivery liability and multi-stop completion SLA terms have no approved policy sources. |
| 6 | Cold-chain | Deferred | Evidence policy exists, but the temperature-range policy grammar and authoritative range terms do not. |
| 7 | Reverse | Scoped | Includes parcel return-with-QC as a related child Contract using `parcel-reverse-qc`; freight and cross-border reverse machines are unavailable. |
| 8 | Exception | Scoped | Includes loss and pickup failure. Damage is deferred because the legacy term conflates claim liability and cargo insurance. |
| 9 | Weight-dispute | Scoped | Includes the standard ten-percent tolerance and standard evidence policy; enterprise and freight-specific aliases are excluded. |
| 10 | Value-added-services | Deferred | `WarehouseExecution` models receipt and inventory movement, but not the legacy QC, kitting, labelling, packaging, grading, or disposition reports. |
| 11 | eKYC | Deferred | No authoritative Logistics eKYC policy source is available. |
| 12 | Incident | Scoped | Uses typed Performance alerts/events and Contract cases; inline legacy incident objects and driver-insurance policy are excluded. |
| 13 | RTS handoff | Included | Uses `update`/`on_update`, typed events and proofs, and the two registered RTS policies. |
| 14 | Customs-clearance | Deferred | Customs-appeal and duty-dispute policy sources are unavailable; remediation remains a planned state-registry flow ID. |
| 15 | Cross-cutting | Scoped | Includes core tracking, status, support, and rating action pairs plus ION reconciliation; excludes undefined `raise*` endpoints. |

## Connection and registry closure

`validate_logistics_connections.rb` enforces the six included pattern profiles,
nine included or scoped variant profiles, profile file targets, schema-pack
directories, concrete policy IRIs, supported protocol actions, state-machine
paths and fragments, and ownership of state-registry flow IDs.

The following registry flow IDs became `published` because exactly one included
variant owns each one:

- `pickup-failure` → Exception;
- `delivery-attempts` → Delivery Attempts; and
- `parcel-reverse-qc` → Reverse.

The other seven IDs remain `planned`; their presence is a resolvable transition
integration point, not a claim that the flow has been published.

## Validation

Run from the repository root:

```bash
ruby tools/release/validate_logistics_performance_states.rb releases/release1
ruby tools/release/validate_logistics_connections.rb releases/release1
ruby tools/release/validate_release.rb releases/release1
```
