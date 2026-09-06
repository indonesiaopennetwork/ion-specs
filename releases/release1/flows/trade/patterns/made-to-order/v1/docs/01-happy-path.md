# B2C-MTO — Happy Path

The consumer discovers a made-to-order resource, selects any required
customisations, reviews the quote and preparation SLA, supplies fulfilment and
payment details, and confirms the contract. The seller reports `PREPARING`,
which closes cancellation, followed by `READY`. A delivery order then progresses
through `DISPATCHED`, `OUT_FOR_DELIVERY`, and `DELIVERED`.

See [`pattern.yaml`](../pattern.yaml) for the complete step-by-step requirements.
