# TradeParticipant v1 overview

`IONTradeParticipant` is the Trade-facing type placed in the core Beckn
`Participant.participantAttributes` extension point. It inherits
`IONParticipant` so Trade payloads use the same role, person, and organization
semantics as other ION domains.

The Trade type adds `billingAddress` because billing information belongs to the
buyer or organization participating in the trade rather than to the shared
cross-domain participant identity model.
