# B2C-DIG — Happy Path

See `spine.yaml` for the full API sequence.

Typical flow — pulsa top-up example:

1. Consumer enters a mobile number as transaction input before `/select`.
2. BPP validates number with operator (inquiry API) → returns customer name in on_select, allows consumer confirmation.
3. Consumer selects denomination (Pulsa Rp 50.000) → standard init → on_init → confirm.
4. On confirm, BPP immediately calls operator API → state becomes `PENDING_OPERATOR`.
5. Operator confirms pulsa credited (usually < 10 seconds) → state transitions to `DELIVERED`. Contract `COMPLETE`.
6. If operator fails → state `DELIVERY_FAILED` → automatic refund triggered.

Voucher flow — game currency example:

1. Consumer enters a game user ID as transaction input before `/select`.
2. Issuer (Moonton/Garena) validates user ID exists → on_select returns validation.
3. Confirm → BPP calls issuer API → diamonds/coins credited to game account → `DELIVERED`.
4. Where supported, the provider returns a redemption URL for voucher activation.
