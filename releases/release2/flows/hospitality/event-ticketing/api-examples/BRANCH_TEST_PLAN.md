# Remaining branch and runtime conformance plan

Status: planned, not executed. The primary sequence for each in-scope scenario is a static message fixture; the following tests must run against a real adaptor or test double. Use existing ION registered error codes once confirmed, not draft symbolic codes as normative assignments.

| Scenario(s) | Stimulus | Expected assertion |
|---|---|---|
| SC01–06, SC07, SC16, SC22 | Parallel purchase of same last capacity, overlapping table/seat or different session pools; mixed basket one pool fails | At most one winner; all-or-none holds; no orphan capacity; no silent substitution; independent session seats unaffected. |
| SC04, SC08 | Adjacent or accessible/companion pair unavailable | Explicit new offer or rejection; no silent reallocation. |
| SC09, SC10, SC11, SC12 | Price changes before confirm; promotion quota exceeded; zero-payable; add-on fails | Expired quote rejected, no payment without explicit new acceptance; free booking no capture; optional add-ons and benefits clearly distinguished. |
| SC13, SC14 | Student proof missing, corporate quantity exceeds limits | Reject or offer explicit revised adult fare; no unnecessary identity data. |
| SC15–18 | Wrong session/zone, re-entry maximum, duplicate scan or named mismatch | Reject without increment; bearer/named rights remain distinct. |
| SC19, SC20 | Ticket generator fails, retries and duplicate callbacks | Booking preserved, same entitlement ID, single credential issuance outcome. |
| SC21, SC23, SC33–35 | Hold expires, sale closes, per-buyer cap exceeded, definitive payment failure, payment callback lost or late | No overbooking; release holds; query draft contract; never retry capture blindly; late refund scoped to payment attempt. |
| SC25–27 | Stale preview, expired consent, already used ticket, partial cancellation | No mutation on stale/invalid preview; valid subset only revoked; refund amount bounded by eligible paid amount. |
| SC28 | VIP capacity unavailable after preview, additional payment fails, retry update | Original ticket remains valid, reconcile any extra capture; no double entitlement. |
| SC29–32 | Event cancellation, postponement declined, incompatible venue seating, insolvency/unfunded refund | Stop sale; explicit change consent or applicable remedy; accurate owed/failed refund status, no ION funding promise. |
| SC36 | Identical operation replay vs distinct legitimate purchase; proven duplicate booking and charge | Replay durable result; preserve legitimate second purchase; cancel only proven duplicate and refund associated payment. |
| SC37–39 | Unused ticket expires; invalid credential; simultaneous admission/cancellation with either ordering; offline gate | No-show not redeemed; reject invalid; serialize race; unresolved offline conflicts to support. |
| SC40 | Refund timeout and repeated refund request | Verify prior refund result; one refund only; obligation stays open until completion. |
| SC41 | Direct and marketplace offer same event | Distinguishable seller/provider and shared authoritative capacity or non-overlapping allocations. |
| SC42 | Missing/unresolved policy, incorrect CRC allocation condition, policy snapshot differs | Block acceptance; reject invalid payload; no silent policy substitution. |
| SC43 | Financial remedy proposed but not accepted; unresolved grievance | No unilateral financial agreement unless policy authorises; retain evidence, SATU portal escalation. |
| SC44 | Counterparty disputes fee/refund; prior settlement already completed | Pending/disputed until both agree; later adjustment; no payout from unaccepted reconciliation. |

SC24 is deferred; no waitlist booking or capacity promise is defined. All tests require upstream core validation, policy review, and network conformance before certification.
