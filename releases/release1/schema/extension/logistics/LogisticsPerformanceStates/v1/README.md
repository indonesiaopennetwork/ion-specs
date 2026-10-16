# LogisticsPerformanceStates v1

This directory defines the ten canonical Logistics performance state machines
used by Release 1 patterns. `states.yaml` is the normative registry and
`registry.schema.json` is its formal grammar. `profile.json` identifies the
artifact without claiming an attribute attachment point.

Every machine declares one initial state and places outgoing transitions on the
source state. A state is terminal only when it has a `terminalOutcome`; terminal
states cannot have outgoing transitions. Requirement entries resolve to actual
properties of `LogisticsPerformance` or `LogisticsContract`. Guards and effects
are structured so validation does not depend on prose.

## Contract status aggregation

The registry deliberately separates an individual Performance outcome from the
whole Contract lifecycle. Required Performances are aggregated in rule order:

1. Any non-terminal required Performance keeps the Contract `ACTIVE`.
2. A terminal failure or dispute keeps it `ACTIVE` while resolution work occurs.
3. If every required Performance is cancelled, the Contract is `CANCELLED`.
4. If all required Performances end successfully, are returned, or transfer work
   to a child Contract, the Contract is `COMPLETE`.
5. With no required Performance, the Contract remains `ACTIVE`.

Optional or supporting Performances do not block completion. A return,
remediation, or warehouse-dispatch child Contract has its own lifecycle.

## Planned flow references

`flowCatalog` gives every transition `flowRef` a resolvable local declaration.
Entries marked `planned` are integration points for Phase 6; they do not claim
that a Logistics flow has already been published. Once flow profiles are added,
the validator also verifies their `stateMachine` or `performanceStateMachine`
fragment against the machine IDs in this registry.

## Validation

From the repository root:

```bash
ruby tools/release/validate_logistics_performance_states.rb releases/release1
```

The complete release gate runs the same validation.
