# LogisticsTracking v1

This pack describes how a transaction's core Tracking URL is accessed and what
transient data it can return. It splits transport `mode` from data
`capabilities`, uses credential references rather than secrets, and replaces
unit-encoded GPS fields with GeoJSON and Quantity.

Durable route, assignment, milestone, observation, proof, and exception history
belongs to `LogisticsPerformance`. The pinned core Tracking Contract-reference
inconsistency remains a core-contract issue; this pack does not duplicate a full
Contract to work around it.
