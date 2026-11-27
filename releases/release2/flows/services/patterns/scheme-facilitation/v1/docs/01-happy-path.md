# SVC-SF — Happy Path

See [`pattern.yaml`](../pattern.yaml) for the complete step-by-step happy path
with required and conditional fields per API call, and [`examples/`](../examples/)
for one message per step.

Narrative walkthrough: a foundation publishes the PKH scheme with a free
facilitation offer → an agent app discovers it for Ibu Dewi → the app selects
the scheme with her profile and receives `LIKELY_ELIGIBLE` → init sends her
details and the consent scope → confirm records her consent and opens a case
with a caseworker → status updates follow: documents requested, application
submitted, under government review, approved, benefit disbursed.
