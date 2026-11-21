# IONParticipant v1 overview

The core Beckn `Participant` provides a stable participant identifier,
descriptor, and the `participantAttributes` extension point.
`IONParticipant` supplies a common machine-readable role and embeds the
corresponding NFH natural-person or organization identity.

The pack does not require `person` or `organization` globally. A participant's
identity form depends on the transaction pattern and actor represented; those
requirements belong in pattern or network policy.
