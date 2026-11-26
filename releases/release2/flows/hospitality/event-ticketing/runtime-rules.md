# Runtime and error requirements (proposed)

| Condition | Required response/outcome |
|---|---|
| Seat unavailable / pool exhausted | Reject allocation; return fresh alternatives; no charge or silent replacement |
| Expired hold / quote | Reject stale confirmation; verify payment and recover or reverse |
| Duplicate operation with identical digest | Replay durable result, no additional charge or booking |
| Same operation with different digest | Reject conflict |
| Payment uncertain | Pending, verify with payment authority |
| Ticket issuance failure | Confirmed booking retained, retry by ticket ID |
| Cancellation revision stale | Refresh preview, require renewed consent |
| Used or revoked ticket | Reject ordinary cancellation or entry as appropriate |
| Refund uncertain | Verify before retry, preserve obligation |
| Policy missing or unresolved | Block acceptance |

These are error semantics, not assigned network codes. Runtime tests must demonstrate atomic cross-channel locks, table/child exclusion, all-session pass allocation, payment races, replay, out-of-order callbacks, gate/cancel serialization and refund idempotency.
