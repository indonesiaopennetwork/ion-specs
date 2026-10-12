# ion-core/payment/v1

Indonesian payment method objects and PaymentDeclaration wrapper.

## Attaches to
`beckn:Settlement.settlementAttributes`

## Payment types
| Object | Description |
|---|---|
| QRIS | Quick Response Code Indonesian Standard (static or dynamic) |
| VirtualAccount | Bank virtual account (BCA, BRI, Mandiri, BNI, etc.) |
| EWallet | OVO, DANA, GoPay, LinkAja, ShopeePay, AstraPay, Sakuku |
| CashOnDelivery | COD with collection amount and change instructions |
| BankTransfer | Direct bank transfer |
| SettlementAccount | A participant's bank account for PJP settlement payouts |
| BISettlement | BI-FAST / RTGS / SKN interbank settlement |
| BNPL | Buy Now Pay Later (Kredivo, Akulaku, etc.) |
| CardPayment | Credit/debit card (Visa, Mastercard, JCB, UnionPay) |

## PaymentDeclaration
Wraps the specific payment instrument with transaction-level context:
`method`, `collectedBy`, `timing`, `status`, `amount`, `paidAt`, `gatewayRef`, `methodDetail`

## Settlement accounts

In ION the buyer's payment is held at the PJP, not in a network participant's
account. After [reconciliation](../../../core/reconcile/v1/README.md), SEAM
instructs the PJP to pay each contract's settlement from those funds into the
participants' accounts. `settlementAccounts[]` carries one `SettlementAccount`
per receiving participant:

| `holderRole` | Receives | Declared in |
|---|---|---|
| `BAP` | Finder fee (`commission`) | `init` |
| `BPP` | Order proceeds (`netPayable`) | `on_init`, which also echoes the BAP's account |

Each entry carries `bankCode`, `accountNumber`, and `accountName`, with the
same meanings as in `BankTransfer`.

## Implementation guidance carried over from the excluded aggregate

The unreconciled `ion.yaml` draft previously treated the following fields as
network-required:

- `method`
- `paymentRail`

This is not a normative Release 1 requirement. Release 1 validation is defined by
the standalone schema and included Trade flow material.

## Used in

[Release 1 Trade flow](../../../../flows/trade/README.md)

## Common rejection reasons

See the Release 1 [Trade error registry](../../../../errors/README.md) for the error
codes included in this release.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
| v1 | 2026-10-12 | Added `settlementAccounts` (`SettlementAccount` per BAP/BPP) for PJP settlement payouts |
