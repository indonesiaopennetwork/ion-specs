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

## Network-required fields

The following fields are always required for this pack by ION network policy (`ion.yaml → x-ion-field-requirements.alwaysRequired`):

- `method`
- `paymentRail`

Mandatoriness is enforced by ONIX — these fields are not marked `required:` in the schema itself (mandatoriness lives in network policy, not the schema).

## Used in

`flows/trade/README.md`

## Common rejection reasons

Unknown `paymentRail` → `ION-6xxx`. Missing `method` → `ION-8xxx`. See `errors/README.md` for the full error code reference.

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1 | 2026-06-02 | Initial release |
