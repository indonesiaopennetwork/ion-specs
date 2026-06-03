# Trade Performance States (v1)

> **Non-standard pack**: This pack contains only a state-machine definition (`states.yaml`) and does not follow the standard 5-file schema pack structure. It is intentionally non-standard because it defines state-machine metadata rather than a Beckn Attributes extension schema.

## Why this pack is non-standard

The `trade/performance-states/v1` pack defines the canonical ION state machine for `TradePerformance` objects. It carries:

- **`states.yaml`** — Complete state definition including allowed transitions, max dwell durations, alert thresholds, and SLA breach flags.
- **`profile.json`** — Pack metadata for ONIX and the schema registry.

It does **not** carry `attributes.yaml`, `schema.json`, `context.jsonld`, or `vocab.jsonld` because this pack does not define an Attributes extension — it defines state-machine constraints that ONIX applies at the network policy layer, not a payload schema that implementers populate.

## How this pack is used

ONIX reads `states.yaml` to validate performance state transitions during a transaction. Implementers do not reference this pack in payload `@context` or `@type` fields. The states defined here are referenced by the `trade/performance/v1` pack's `status.code` property.

## State machine

See `states.yaml` for the full state list with transition rules, dwell limits, and SLA thresholds.

## Exception documentation

This pack is a **documented exception** to CON-012-02 of NFH-012, which requires all schema packs to include five required files. The exception is justified because:
1. This pack does not define an Attributes extension schema.
2. There is no JSON-LD context or vocabulary to publish — states are not RDF classes.
3. The `attributes.yaml` / `schema.json` artifacts would be empty or trivially thin.

The exception is tracked in the ION spec issue register.

## Changelog

- v1 — Initial release, 2026-06-02. State machine for ION trade performance lifecycle.
