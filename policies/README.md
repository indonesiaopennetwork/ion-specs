# ION Policy Terms Registry

Machine-enforceable policy terms referenced by offer IRIs across the ION network.

## How it works

Sellers declare policy IRIs on their offers. ION resolves each IRI to a structured
terms document that defines exactly what the policy means and how it is enforced.

```yaml
offerAttributes:
  returnPolicy:       ion://policy/return.standard.7d-sellerpays
  cancellationPolicy: ion://policy/cancel.prepacked.free
  warrantyPolicy:     ion://policy/warranty.standard.none
  disputePolicy:      ion://policy/dispute.consumer.bpsk
  grievanceSlaPolicy: ion://policy/grievance-sla.consumer.standard
  paymentTermsPolicy: ion://policy/payment-terms.upfront.full
```

## IRI naming scheme

All IRIs follow a uniform three-segment pattern:

```
ion://policy/{category}.{sector-or-scope}.{variant-name}
```

| Segment | Values |
|---|---|
| `category` | `return`, `cancel`, `warranty`, `dispute`, `grievance-sla`, `payment-terms`, `penalty`, `sla`, `evidence`, `re-attempt`, `weight-dispute`, `liability`, `incident`, `rts-handoff`, `insurance`, `collateral`, `kyc`, `finance.*`, … |
| `sector-or-scope` | `trade`, `logistics`, `finance`, `consumer`, `commercial`, `b2b`, `b2g`, `standard`, `enterprise`, `network` |
| `variant-name` | Hyphenated slug identifying the specific variant |

No underscores. No abbreviated category names. No sector prefix on the top-level segment.

## Directory structure

```
policies/
  {category}/v1/                     Cross-sector base policies
  {category}/v1/trade/               Trade-sector variants
  {category}/v1/logistics/           Logistics-sector variants
  {category}/v1/finance/             Finance-sector variants

  # Trade-only (no sub-folders needed)
  return/v1/                         15 return policies
  warranty/v1/                       8 warranty policies

  # Cross-sector with sector variants
  cancellation/v1/                   10 cross-sector cancellation policies
  cancellation/v1/logistics/         4 logistics cancellation policies
  cancellation/v1/finance/           2 finance cancellation policies
  dispute/v1/trade/                  5 trade dispute policies
  dispute/v1/finance/                3 finance dispute policies
  grievance-sla/v1/                  4 cross-sector grievance SLA policies
  payment-terms/v1/                  8 cross-sector payment terms
  penalty/v1/                        14 cross-sector penalty policies
  penalty/v1/logistics/              3 logistics penalty policies
  penalty/v1/finance/                3 finance penalty policies
  insurance/v1/logistics/            2 logistics cargo insurance policies
  insurance/v1/finance/              3 finance credit insurance policies

  # Logistics-only
  evidence/v1/                       3 delivery evidence policies
  sla/v1/                            2 logistics SLA policies
  re-attempt/v1/                     4 re-delivery attempt policies
  weight-dispute/v1/                 2 weight discrepancy policies
  liability/v1/                      5 loss/damage liability policies
  incident/v1/                       2 incident reporting policies
  rts-handoff/v1/                    2 RTS handoff policies
  logistics-fwa/v1/                  1 framework agreement instance

  # Finance-only
  collateral/v1/                     3 collateral registration policies
  collections-conduct/v1/            1 collections conduct policy
  credit-assessment/v1/              3 credit assessment policies
  disbursement/v1/                   4 disbursement policies
  interest-rate-cap/v1/              4 OJK interest rate cap policies
  kyc/v1/                            3 eKYC tier policies
  ltv-cap/v1/                        3 LTV cap policies
  prepayment/v1/                     4 prepayment penalty policies
  restructure/v1/                    4 loan restructuring policies
  slik-reporting/v1/                 1 SLIK reporting policy

  registry.json                      Generated aggregate index
  generate_registry.py               Generator script (run after any change)
```


## Common IRIs for Trade sector — quick reference

The most common policy IRIs used in a trade BPP offer. Full list is in each category subdirectory.

### Return policies
| IRI | What it means |
|---|---|
| `ion://policy/return.standard.7d-sellerpays` | 7-day return, seller arranges pickup and pays shipping |
| `ion://policy/return.standard.15d-sellerpays` | 15-day return, seller pays return shipping |
| `ion://policy/return.standard.7d-buyerpays` | 7-day return, buyer ships back at own cost |
| `ion://policy/return.standard.none` | No returns accepted |

### Cancellation policies
| IRI | What it means |
|---|---|
| `ion://policy/cancel.prepacked.free` | Free cancellation before item is packed |
| `ion://policy/cancel.mto.nofee-before-prepare` | MTO: free before preparation starts |
| `ion://policy/cancel.standard.none` | No cancellations accepted |

### Warranty policies
| IRI | What it means |
|---|---|
| `ion://policy/warranty.manufacturer.1y-distance-service` | 1-year manufacturer warranty, distance service |
| `ion://policy/warranty.manufacturer.2y-distance-service` | 2-year manufacturer warranty, distance service |
| `ion://policy/warranty.standard.none` | No warranty |

### Dispute policies
| IRI | What it means |
|---|---|
| `ion://policy/dispute.consumer.bpsk` | B2C via BPSK (consumer protection board) |
| `ion://policy/dispute.commercial.bani` | B2B via BANI arbitration |

### Grievance SLA policies
| IRI | What it means |
|---|---|
| `ion://policy/grievance-sla.consumer.standard` | Standard consumer grievance SLA |

### Payment terms policies
| IRI | What it means |
|---|---|
| `ion://policy/payment-terms.upfront.full` | Full payment upfront at confirm |
| `ion://policy/payment-terms.cod.standard` | Cash on delivery, standard terms |

For all available IRIs including logistics, finance, and sector-specific variants, browse the category subdirectories under `policies/`.

## Policy document format

Every policy document uses the same format regardless of sector:

```yaml
iri: ion://policy/return.standard.7d-sellerpays
version: "1.0.0"
versionEffectiveFrom: "2026-05-01"
category: RETURN
status: ratified        # ratified | draft | deprecated
ratifiedAt: "2026-04-15"

displayText:
  id: "Pengembalian 7 hari — penjual menanggung ongkos kirim balik"  # always required
  en: "7-day return — seller pays return shipping"

# Policy-specific fields follow (returnWindowDays, cancellationFee, etc.)

applicableCategories: [fashion, electronics, ...]    # omit for sector-wide
applicableResourceTypes: [PLAIN, VARIANT, ...]       # omit for sector-wide

regulatoryBasis:
  - "UU 8/1999 tentang Perlindungan Konsumen Pasal 19"

supersededBy: null      # or replacement IRI
deprecatedAt: null      # or ISO date
```

## Stability guarantees

- **IRIs are permanent.** Once ratified, an IRI's meaning cannot change.
  If terms need updating, a new IRI is created and the old one sets `supersededBy`.
- **Council ratifies with 90-day notice.** On the cutover date, catalogs
  auto-upgrade. Sellers receive notification at ratification.
- **Sector sub-folders are independently extensible.** Adding logistics cancellation
  policies never touches trade return policies.
- **`generate_registry.py` is the gate.** Exits non-zero on duplicate IRIs.
  Wire into CI as a pre-merge gate.

## Validation

At catalog publish time, ION Central validates every policy IRI:

- Unknown IRI → `ION-A2010 INVALID_POLICY_IRI_AT_CATALOG_PUBLISH`
- Deprecated IRI → `ION-A2011 POLICY_IRI_DEPRECATED` (with `supersededBy` guidance)

At runtime, policy violations are rejected:

- Cancel outside window → `ION-5001`
- Return past `returnWindowDays` → `ION-5004` (via `ION-A5002`)
- Action outside policy bounds → `ION-5008`

## Generating the registry

```bash
python policies/generate_registry.py
```

Reads all `*.yaml` files under each category directory (including sector sub-folders),
deduplicates by IRI, rejects duplicates with non-zero exit, and writes `registry.json`.
