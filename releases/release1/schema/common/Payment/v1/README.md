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
| BISettlement | BI-FAST / RTGS / SKN interbank settlement |
| BNPL | Buy Now Pay Later (Kredivo, Akulaku, etc.) |
| CardPayment | Credit/debit card (Visa, Mastercard, JCB, UnionPay) |

## PaymentDeclaration
Wraps the specific payment instrument with transaction-level context:
`method`, `collectedBy`, `timing`, `status`, `amount`, `paidAt`, `gatewayRef`, `methodDetail`

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
