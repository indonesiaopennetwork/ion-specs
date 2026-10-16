# LogisticsConsideration v1

This pack uses the pinned Beckn `PriceSpecification` as its canonical monetary
shape. `currency`, `value`, and `components[]` replace legacy parallel totals.

Each component carries a generic price-component `type` and a logistics-specific
`chargeCode`. Discounts, credits, and rebates are negative; charges and taxes
are positive. Estimated, revised, and final prices are separate core
Considerations rather than parallel fields in one object.

COD collection/remittance and insurance coverage are intentionally outside this
pack. Tax detail is local and minimal until the common Tax pack has a
consideration-independent attachment seam.
