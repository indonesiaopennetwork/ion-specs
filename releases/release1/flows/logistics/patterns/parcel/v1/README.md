# Parcel v1

Parcel is the Release 1 reference Logistics flow. It uses standard Beckn
discovery and transaction actions, selects a state machine from the confirmed
`routingTopology`, and records durable execution facts in
`LogisticsPerformance`.

The legacy centralized catalog publication step is not carried forward because
it is absent from the Release 1 API contract. Multi-stop, COD, and eKYC are also
not part of this base profile; their Phase 6 dispositions are recorded in the
Logistics flow migration ledger.
