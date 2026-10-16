# LogisticsCommitment v1

This pack records facts established during logistics selection or booking that
do not belong to the selected core Resources or Offer.

Core `Commitment.resources[]` remains authoritative for selected Resources. The
known core quantity inconsistency is not bypassed with duplicate attribute
fields; quantities in this pack are limited to explicit capacity reservations.
Package aggregates are derived, and parent-child commitment references remain
deferred until cross-contract identifier scope is defined.
