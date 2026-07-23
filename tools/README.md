# ION Integration Tools

Two CLI tools that collapse the required-field discovery problem into a single command.

## TOOL-1: `ion_required_fields.py` — Required fields query

Answers the question "which fields do I have to send?" for a specific (pattern + CRC) combination. Reads `ion.yaml`, the relevant `pattern.yaml`, and each pack's `profile.json` and assembles the complete mandatory field list for your integration scenario.

### Usage

```bash
# All steps for a trade BPP using storefront pattern with fashion products
python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion

# Just the confirm step
python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion --step confirm

# Food-bev CRC
python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-food-bev

# Logistics BPP, parcel pattern
python tools/ion_required_fields.py --sector logistics --pattern parcel --crc LGC-lastmile

# JSON output (for AI agent consumption)
python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion --json
```

### Output format

Fields are labelled by their source so you know which source they came from and where to investigate if ONIX rejects them:

```
Step: publish_catalog
  [network-policy]  resourceStructure           (ion.yaml → x-ion-field-requirements)
  [network-policy]  resourceTangibility         (ion.yaml → x-ion-field-requirements)
  [network-policy]  halalStatus                 (ion.yaml → x-ion-field-requirements)  ← not in pattern.yaml
  [network-policy]  ageRestricted               (ion.yaml → x-ion-field-requirements)  ← not in pattern.yaml
  [network-policy]  countryOfOrigin             (ion.yaml → x-ion-field-requirements)
  [crc:TRC-fashion] fashion.gender              (ion.yaml → x-ion-crc-rules)
  [crc:TRC-fashion] fashion.size                (ion.yaml → x-ion-crc-rules)
  [crc:TRC-fashion] fashion.fabric              (ion.yaml → x-ion-crc-rules)
  [discovery]       images                      (profile.json → minimalForDiscovery)
  [discovery]       availability                (profile.json → minimalForDiscovery)
  [pattern]         policies.cancellation.policyRef          (pattern.yaml → requiredFields)
  [pattern]         policies.returns.policyRef                (pattern.yaml → requiredFields)
```

Fields marked `← not in pattern.yaml` are enforced by ION network policy but not declared in the pattern — you will only discover these from the tool or from `ion.yaml → x-ion-field-requirements` directly.

### Sources read

| Source | Used for |
|---|---|
| `flows/{sector}/patterns/{pattern}/v1/pattern.yaml` | Required fields per step |
| `schema/core/v2/api/v2.0.0/ion.yaml → x-ion-field-requirements` | Network-wide always-required fields |
| `schema/core/v2/api/v2.0.0/ion.yaml → x-ion-crc-rules` | Category-conditional required fields |
| `schema/extensions/{pack}/v1/profile.json → minimalForDiscovery` | Discovery indexing fields |

See `tools/samples/` for pre-generated outputs for common integration profiles.

---

## TOOL-2: `ion_setup.py` — Full integration setup generator (highest priority)

Answers six questions about your integration and generates a complete personalised output folder with checklists, JSON scaffolds, business rules, and error handling for your specific scenario. Most developers never need to open the raw spec after running this tool.

### Usage

```bash
# Interactive mode — prompts for all six questions
python tools/ion_setup.py

# Non-interactive — all flags provided
python tools/ion_setup.py \
  --role BPP \
  --sector trade \
  --pattern storefront \
  --crcs TRC-fashion,TRC-health-beauty \
  --variants during-transaction,cancellation,returns,cross-cutting \
  --payment QRIS,COD \
  --output ion-integration/

# JSON output (for AI agent consumption)
python tools/ion_setup.py --role BPP --sector trade --pattern storefront \
  --crcs TRC-fashion --variants cross-cutting --payment QRIS --json
```

### The six questions

1. **Role** — BPP (seller/provider) or BAP (buyer app)?
2. **Sector** — trade, logistics, or hospitality?
3. **Pattern** — storefront, parcel, delivery-order, made-to-order, etc.?
4. **CRCs** — which product categories? (TRC-fashion, TRC-food-bev, TRC-electronics, LGC-lastmile, etc.)
5. **Variants** — which variants apply? (cross-cutting is always included)
6. **Payment methods** — QRIS, COD, VIRTUAL_ACCOUNT, EWALLET, etc.?

### Output: one folder, eight files

```
ion-integration/BPP-trade-storefront-TRC-fashion/
│
├── README.md               ← Start here: who you are on ION, what each file is for
├── 01-endpoints.md         ← Complete endpoint list with direction and flow phase
├── 02-catalog/
│   ├── checklist.md        ← Every field required for publish_catalog, labelled by source
│   ├── scaffold-publish_catalog.json  ← Complete JSON with all required fields as placeholders
│   └── policy-IRIs.md      ← Available policy IRI options for your offer type
├── 03-transaction/
│   ├── select-checklist.md
│   ├── select-scaffold.json
│   ├── ... (one checklist + scaffold per API step)
│   └── on_confirm-scaffold.json
├── 04-fulfilment/
│   ├── on_status-PACKED.json
│   ├── on_status-DISPATCHED.json
│   └── ... (one per performance state)
├── 05-post-order/
│   ├── reconcile-checklist.md
│   ├── reconcile-scaffold.json
│   └── raise-scaffold.json
├── 06-business-rules.md    ← All business rules in plain English, grouped by step
├── 07-errors.md            ← All error codes you must handle, with resolution text
└── 08-pack-reference.md    ← Active schema packs: @context URL, @type, link to attributes.yaml
```

### Common integration profiles

**Trade BPP, storefront, fashion, QRIS + COD:**
```bash
python tools/ion_setup.py --role BPP --sector trade --pattern storefront \
  --crcs TRC-fashion --variants during-transaction,cancellation,returns,cross-cutting \
  --payment QRIS,COD
```

**Logistics BPP, parcel, last-mile, COD:**
```bash
python tools/ion_setup.py --role BPP --sector logistics --pattern parcel \
  --crcs LGC-lastmile --variants during-transaction,cancellation,cross-cutting \
  --payment COD
```

**Hospitality BPP, delivery order, restaurant, QRIS:**
```bash
python tools/ion_setup.py --role BPP --sector hospitality --pattern delivery-order \
  --crcs HSC-delivery --variants cancellation,cross-cutting --payment QRIS
```

### Design principle

Patterns and variants were built to enable exactly this tool. The `pattern.yaml` defines the flow skeleton and required fields per step. Variants define additive deltas. `x-ion-field-requirements` and `x-ion-crc-rules` provide the network policy floor. All the data is in the repo — this tool traverses the connections that already exist and assembles them into one place.

Developers who want to understand the underlying structure can still read every source file — this tool adds an abstraction layer without removing anything below it.

---

## Implementation status

Both tools are **specified but not yet implemented**. The specification above defines the complete interface and output format. Implementation follows the same pattern as the existing `errors/generate_registry.py` and `policies/generate_registry.py` scripts — reading structured YAML and producing developer-facing output.

Contributors interested in implementing these tools should open an Issue referencing this README.
