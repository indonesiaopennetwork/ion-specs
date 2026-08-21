# ION Error Registry

A unified, machine-readable registry of all ION error codes across all sectors.
`registry.json` is generated from the category YAML files — never edit it directly.


## Handling errors in your integration

When ONIX returns a NACK (HTTP 400 or 422), the response body contains an `error.code` field with an ION error code. Here is how to use it:

1. **Find the entry.** Query `errors/registry.json` where `code` matches your error code. For example, to find `ION-8001`: `jq '.[] | select(.code == "ION-8001")' errors/registry.json`
2. **Read `resolution.en`.** This field tells you exactly what to fix in your payload.
3. **Check `affected_field`.** This is the JSON path of the field that caused the rejection (e.g. `message.catalog.resources[].resourceAttributes.halalStatus`).
4. **Follow `schema_ref` and `flow_ref`.** These link back to the relevant schema pack and flow step so you can check the full field definition.

Schema rejections (`ION-8xxx`) are the most common category during integration. If ONIX rejects your message, check your `pattern.yaml` step definition first — it lists every field ONIX validates at that step.

## Code naming scheme

| Prefix | Sector / category | Range |
|---|---|---|
| `ION-1xxx` | Transport — auth, signature, TTL, messageId | 1001–1999 |
| `ION-2xxx` | Catalog — publish, discover, KYC, policy IRI | 2001–2999 |
| `ION-3xxx` | Transaction — select through confirm | 3001–3999 |
| `ION-4xxx` | Fulfillment — status, track, state machine | 4001–4999 |
| `ION-5xxx` | Post-order — cancel, return, RTO, SLA | 5001–5999 |
| `ION-6xxx` | Settlement — reconcile, payment rails, tax | 6001–6999 |
| `ION-7xxx` | Network — participant conduct, ION policy | 7001–7999 |
| `ION-8xxx` | Schema — field validation, type mismatches | 8001–8999 |
| `ION-9xxx` | System — internal errors, timeouts | 9001–9999 |
| `ION-B1xxx` | Logistics — serviceability, eKYC, compliance, RTS, cut-off | B1001–B1999 |
| `ION-B2xxx` | Logistics — delivery attempts | B2001–B2999 |
| `ION-B3xxx` | Logistics — weight/dimension disputes | B3001–B3999 |
| `ION-B4xxx` | Logistics — cancellation | B4001–B4999 |
| `ION-B5xxx` | Logistics — cold chain | B5001–B5999 |
| `ION-B6xxx` | Logistics — customs / cross-border | B6001–B6999 |
| `ION-B7xxx` | Logistics — RoRo / vessel | B7001–B7999 |
| `ION-B8xxx` | Logistics — warehouse | B8001–B8999 |
| `ION-B9xxx` | Logistics — framework agreements (FWA) | B9001–B9999 |
| `ION-B10xxx` | Logistics — participants | B10001–B10999 |
| `ION-B11xxx` | Logistics — payment | B11001–B11999 |
| `ION-B12xxx` | Logistics — incident | B12001–B12999 |
| `ION-B13xxx` | Logistics — SLA / state dwell | B13001–B13999 |
| `ION-B14xxx` | Logistics — carbon reporting | B14001–B14999 |
| `ION-B15xxx` | Logistics — transport / Beckn protocol | B15001–B15999 |
| `ION-B16xxx` | Logistics — registry / subscriber | B16001–B16999 |
| `ION-F6xxx` | Finance — credit, KYC, collateral, disbursement, regulatory | F6000–F6999 |

A developer receiving `ION-B6002` knows immediately it is a logistics customs error without looking it up.

## Files

| File | Description |
|---|---|
| `transport.yaml` | ION-1xxx: auth, signature, TTL |
| `catalog.yaml` | ION-2xxx: catalog publish and discovery |
| `transaction.yaml` | ION-3xxx: select → confirm |
| `fulfillment.yaml` | ION-4xxx: status, track, state machine |
| `post-order.yaml` | ION-5xxx: cancellation, returns, RTO |
| `settlement.yaml` | ION-6xxx: reconciliation, payment rails |
| `network.yaml` | ION-7xxx: network policy |
| `schema.yaml` | ION-8xxx: field validation |
| `system.yaml` | ION-9xxx: system errors |
| `logistics.yaml` | ION-Bxxx: all logistics patterns and variants |
| `finance.yaml` | ION-Fxxx: finance sector (FIN-02 lending) |
| `registry.json` | **Unified registry** — generated, do not edit |
| `logistics-registry.json` | Logistics sector view — generated |
| `finance-registry.json` | Finance sector view — generated |
| `generate_registry.py` | Generator script |

## Error entry structure

Every entry in every YAML file uses the same schema:

```yaml
- code: ION-3001                          # Unique code — never reuse
  legacy_code: ION-LOG-6001              # Only on migrated logistics/finance entries
  http_status: 400                        # HTTP status code for NACK response
  sector: trade                           # trade | logistics | finance (omit for cross-sector)
  category: transaction                   # Sub-category within the file
  title:
    id: "Judul dalam Bahasa Indonesia"    # Always required
    en: "Error title in English"          # Always required
  description:
    en: "Full description of what went wrong and why, including which actor produces it."
  affected_field: message.contract.commitments[]   # JSON path, or null
  affected_apis:
    - select
  schema_ref: releases/release1/schema/extension/trade/TradeResource/v1  # Repo-relative path, or null
  flow_ref: flows/trade/patterns/storefront/v1     # Repo-relative path, or null
  resolution:
    en: "What the implementer should do to fix this."
```

## Adding a new error

1. Identify the correct category file
2. Assign the next available code in that range (never reuse or skip codes)
3. Add the entry following the structure above
4. Run `python errors/generate_registry.py`
5. Commit both the YAML change and the regenerated registry files

The generator fails with a non-zero exit code on: duplicate codes, malformed codes, missing required fields, YAML parse errors. This can be wired into CI as a pre-merge gate.

## Legacy codes

Logistics errors previously used `ION-LOG-Nxxx` format. Finance errors used `ION-FIN-Nxxx`.
Both have been renumbered to the unified scheme. The old codes are retained in the `legacy_code`
field on each entry to support migration. Old codes MUST NOT be used in new implementations.

## The four-tier architecture

```
ION-1xxx..ION-9xxx   Cross-sector / universal
    Concepts that apply in ALL sectors: transport auth, resource not found,
    quantity limits, payment rail errors, cancellation windows, performance
    state transitions, data residency, schema field validation, system errors.
    Any sector (trade, logistics, hospitality, finance) can produce or consume
    these codes. Adding a new sector never requires changing these codes.

ION-Axxx   Trade sector (sector A)
    Concepts specific to the trade sector: customisation groups, variant
    matrices, return windows, stock caps, live-commerce session expiry,
    voucher stacking, halal status, policy IRI validation.

ION-Bxxx   Logistics sector (sector B)
    Concepts specific to logistics patterns and variants: serviceability,
    cold chain, customs clearance, RoRo, warehouse, FWA, weight disputes.

ION-Fxxx   Finance sector
    Concepts specific to FIN-02 lending: credit assessment, KYC, collateral,
    disbursement, SLIK, OJK regulatory compliance.
```

## Stability guarantees

- **Cross-sector errors (ION-Nxxx) are frozen.** Once published, a code's
  meaning cannot change. New sectors NEVER need to touch these codes.
- **Sector errors (ION-Axxx, ION-Bxxx, ION-Fxxx) are independently extensible.**
  Adding 50 new logistics errors does not affect trade or finance files.
  A logistics implementer never needs to read trade.yaml or finance.yaml.
- **New sectors get their own letter prefix** (ION-Cxxx for hospitality,
  ION-Dxxx for mobility, etc.). No existing code is ever renumbered.
- **generate_registry.py is the gate.** It rejects: duplicate codes, missing
  required fields, malformed code formats, YAML parse errors. Wire it into CI.

## Finding errors by schema pack or flow step

Each error entry in the YAML files links to its relevant schema pack (`schema_ref`) and flow step (`flow_ref`). To find all errors relevant to a specific pack or flow:

```bash
# All errors for the trade/resource pack
jq '[.[] | select(.schema_ref == "releases/release1/schema/extension/trade/TradeResource/v1")]' errors/registry.json

# All errors for the storefront pattern
jq '[.[] | select(.flow_ref == "flows/trade/patterns/storefront/v1")]' errors/registry.json

# All errors for a specific API step (e.g. confirm)
jq '[.[] | select(.affected_apis[] == "confirm")]' errors/registry.json
```

