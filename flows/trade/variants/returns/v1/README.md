# Returns Branch

Post-delivery return flows. Includes return pickup, delivery back to seller, replacement, exchange, and cancel-return.

## Sub-branches

| Branch | Window | Description |
|---|---|---|
| return-initiated | on_status[DELIVERED] → return window expiry | Buyer raises return request. Reason must be in return policy IRI (`policies.returns.policyRef`). Evidence photos optional. |
| return-picked-up | after return-initiated | Seller arranges pickup (if `policies.returns.method = SELLER_PICKUP`). Agent assigned. Return tracking begins. |
| return-delivered | after return-picked-up | Return received by seller. Quality check. Refund or replacement triggered. |
| replacement | after return-initiated | Seller sends replacement item instead of refund. Uses REPLACEMENT state machine. |
| exchange | after return-initiated | Return pickup + new forward delivery in one coordinated flow. |
| cancel-return-request | after return-initiated, before return-picked-up | Buyer cancels their own return request before agent pickup. |

## Refund
- Refund is a sub-step triggered inside `return-delivered`
- For prepaid: refund to original payment method
- Timeline declared in on_update[return-delivered]

## API sequence
```
return-initiated:
  BAP → /update (target.fulfillment.state = RETURN_INITIATED, reason, evidence)
  BPP → /on_update (RETURN_APPROVED or RETURN_REJECTED)

return-picked-up:
  BPP → /on_status (RETURN_AGENT_ASSIGNED, agent details)
  BPP → /on_status (RETURN_PICKED, returnTrackingUrl)

return-delivered:
  BPP → /on_status (RETURN_DELIVERED)
  BPP → /on_update (refundAmount, refundMethod) or /on_update (replacement dispatched)
```

## State machine
`performance-states/v1/states.yaml#return` and `#replacement`

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
