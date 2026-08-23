# B2C-DIG — Happy Path

The BPP publishes a digital voucher or subscription with
`resourceTangibility = DIGITAL_VOUCHER` or `DIGITAL_SUBSCRIPTION` and a delivery
method of `CODE_TO_BUYER` or `QR_VOUCHER`. The buyer selects the resource,
supplies contact and payment details without a shipping address, and confirms
the contract. The BPP responds with `PENDING_OPERATOR`, then sends an unsolicited
`on_status` with `DELIVERED` after issuer confirmation. When applicable, the
committed Resource includes an access-controlled redemption URL and the Contract
becomes `COMPLETE`.

If issuer delivery fails, the BPP instead sends `DELIVERY_FAILED` and records a
full refund with reason `DELIVERY_FAILED`.

See [`pattern.yaml`](../pattern.yaml) for the complete step-by-step requirements
and the Release 1 exclusions.

