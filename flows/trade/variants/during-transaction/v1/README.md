# During-Transaction Branch

Branches active between `select` and `on_confirm`. They shape the transaction before it is committed. Multiple can be active simultaneously.

## Sub-branches

| Branch | Window | Description |
|---|---|---|
| fulfillment-type | select → on_confirm | Consumer chooses delivery vs self-pickup. BPP must declare `supportedPerformanceModes[]` in on_select. |
| payment-prepaid-BAP-collected | init → on_confirm | BAP collects payment upfront. QRIS, EWallet, Virtual Account. Payment object fully populated in on_init. |
| payment-prepaid-BPP-collected | init → confirm | BPP collects directly. Includes unsolicited on_init for payment status update after consumer pays. |
| payment-COD-BAP-collected | init → on_status[DELIVERED] | COD where marketplace collects. COD amount declared in contractAttributes.codAmount. |
| payment-COD-BPP-collected | init → on_status[DELIVERED] | COD where seller collects at doorstep. Agent carries exact change requirement. |
| multi-fulfillment | select → init | Order split across multiple FCs. Each split = a separate Performance record in on_select. |
| cancellation-terms | on_init → on_confirm | Buyer reviews and explicitly accepts cancellation fee terms before confirming. |
| on-network-LSP | on_confirm | BPP triggers a separate on-network Logistics Contract after trade confirm. Linked via `linkedContractId`. |
| technical-cancellation-confirm-failure-BAP | confirm | BAP receives NACK on confirm. Cancels with code 999. No contract created. Refund if payment was initiated. |
| technical-cancellation-confirm-failure-BPP | on_confirm | BPP receives NACK. Cancels with code 998. Same outcome — no live contract. |

## Key design rules
- fulfillment-type and payment method selection always happen during this window
- Technical cancellations use standardised codes 998 (BPP) and 999 (BAP)
- on-network-LSP is triggered by BPP unilaterally after on_confirm — BAP is not involved in the Logistics contract

## How variant fields layer

These fields are required **in addition to** the base pattern's required fields for the same API step. They do not replace pattern requirements — they extend them. Always check your pattern's `pattern.yaml` for the base requirements, then add variant requirements on top.

The `variant.yaml` in this directory is the machine-readable source of truth for this variant's required fields per step.
