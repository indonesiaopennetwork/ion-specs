# Trade Consideration Extension — Overview

Retail consideration amounts and breakup entries for the trade sector.

## Breakup entries

Use the inherited `breakup[].type` values from RetailConsideration v2.1,
including `BASE_PRICE`, `TAX`, `DISCOUNT`, and `DELIVERY_CHARGE`.

## Tax entries

Each PPN, PPnBM, or withholding tax is a separate `TAX` breakup entry. Its
`amount` is the calculated tax amount. Its nested `taxDetail` uses inherited
`rate`, `included`, and `taxableBase`, plus ION `taxRegime`, `taxCategory`, and
optional `eFakturRef`.

## Discount entries

Use a `DISCOUNT` breakup entry for the realized monetary reduction. Offer-level
promotion fields declare eligibility, calculation mechanics, and funding.
