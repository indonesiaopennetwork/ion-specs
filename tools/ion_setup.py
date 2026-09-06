#!/usr/bin/env python3
"""
ion_setup.py — ION integration setup generator (TOOL-2)

Asks six questions about your integration and generates a complete personalised
output folder with checklists, JSON scaffolds, business rules, and error handling.

Usage:
  python tools/ion_setup.py                          # interactive mode
  python tools/ion_setup.py --role BPP --sector trade --pattern storefront \\
      --crcs TRC-fashion,TRC-health-beauty \\
      --variants during-transaction,cancellation,returns,cross-cutting \\
      --payment QRIS,COD --output ion-integration/
  python tools/ion_setup.py --role BPP --sector trade --pattern storefront \\
      --crcs TRC-fashion --variants cross-cutting --payment QRIS --json
"""

import argparse
import json
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).parent.parent
VERSION = "1.0.0"
SPEC_VERSION = "ion.yaml v0.7.0"

# ── Helpers ───────────────────────────────────────────────────────────────────

def load_yaml(path: Path) -> dict:
    if not path.exists():
        return {}
    with open(path) as f:
        return yaml.safe_load(f) or {}

def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)

def load_ion_yaml() -> dict:
    return load_yaml(REPO_ROOT / "releases/release1/schema/core/api/v2.0.0/ion.yaml")

def load_pattern(sector: str, pattern: str) -> dict:
    return load_yaml(REPO_ROOT / f"flows/{sector}/patterns/{pattern}/v1/pattern.yaml")

def load_variant(sector: str, variant: str) -> dict:
    return load_yaml(REPO_ROOT / f"flows/{sector}/variants/{variant}/v1/variant.yaml")

def load_profile(sector: str, pack: str) -> dict:
    return load_json(REPO_ROOT / f"schema/extensions/{sector}/{pack}/v1/profile.json")

def load_policies() -> list:
    reg = load_json(REPO_ROOT / "policies/registry.json")
    return reg.get("policies", [])

def load_errors() -> list:
    reg = load_json(REPO_ROOT / "errors/registry.json")
    return reg.get("errors", [])

def load_context_jsonld(sector: str, pack: str) -> dict:
    path = REPO_ROOT / f"schema/extensions/{sector}/{pack}/v1/context.jsonld"
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)

def available_patterns(sector: str) -> list[str]:
    d = REPO_ROOT / f"flows/{sector}/patterns"
    if not d.exists():
        return []
    return sorted(p.name for p in d.iterdir() if p.is_dir() and (p / "v1/pattern.yaml").exists())

def available_variants(sector: str) -> list[str]:
    d = REPO_ROOT / f"flows/{sector}/variants"
    if not d.exists():
        return []
    return sorted(p.name for p in d.iterdir() if p.is_dir() and (p / "v1/variant.yaml").exists())

def available_crcs(ion_data: dict) -> list[str]:
    rules = ion_data.get("x-ion-profile", {}).get("x-ion-crc-rules", {}).get("rules", [])
    return [r["crc"] for r in rules]

def get_always_required(ion_data: dict) -> list[dict]:
    return (ion_data.get("x-ion-profile", {})
            .get("x-ion-field-requirements", {})
            .get("alwaysRequired", {})
            .get("fields", []))

def get_crc_rule(ion_data: dict, crc: str) -> dict:
    for rule in ion_data.get("x-ion-profile", {}).get("x-ion-crc-rules", {}).get("rules", []):
        if rule.get("crc") == crc:
            return rule
    return {}

def get_pack_context_url(sector: str, pack: str) -> str:
    return f"https://schema.ion.id/{sector}/{pack}/v1/context.jsonld"

def get_pack_type(sector: str, pack: str) -> str:
    profile = load_profile(sector, pack)
    points = profile.get("attachmentPoints", {})
    # Handle both dict format {"resourceAttributes": ["IONTradeResource"]}
    # and list format ["Offer.offerAttributes"]
    if isinstance(points, dict):
        for _, types in points.items():
            if types:
                return f"ion:{types[0]}"
    elif isinstance(points, list) and points:
        # e.g. ["Offer.offerAttributes"] — derive class from className
        cls = profile.get("className", "")
        if cls:
            return f"ion:{cls}"
    # Fallback: use ion:ION{Pack}
    cls = profile.get("className", "")
    return f"ion:{cls}" if cls else f"ion:ION{pack.replace('-','').capitalize()}"

def all_pattern_fields(pattern_data: dict) -> set[str]:
    fields = set()
    for phase in pattern_data.get("phases", {}).values():
        for step in phase.get("steps", []):
            fields.update(step.get("requiredFields", []))
    return fields

def steps_with_fields(pattern_data: dict) -> list[dict]:
    steps = []
    for phase_key, phase in pattern_data.get("phases", {}).items():
        for step in phase.get("steps", []):
            step = dict(step)
            step["_phase"] = phase.get("name", phase_key)
            steps.append(step)
    return steps

def variant_steps_with_fields(variant_data: dict) -> list[dict]:
    steps = []
    for sf_name, sf in variant_data.get("subFlows", {}).items():
        for step in sf.get("steps", []):
            step = dict(step)
            step["_subflow"] = sf_name
            steps.append(step)
    return steps

# ── Interactive prompts ───────────────────────────────────────────────────────

def prompt(question: str, options: list[str], multi: bool = False, default: str = None) -> list[str] | str:
    print(f"\n{question}")
    for i, opt in enumerate(options, 1):
        print(f"  {i}. {opt}")
    if default:
        print(f"  (default: {default})")
    while True:
        raw = input("  > ").strip()
        if not raw and default:
            return [default] if multi else default
        if multi:
            parts = [p.strip() for p in raw.replace(",", " ").split()]
            valid = []
            for p in parts:
                if p.isdigit() and 1 <= int(p) <= len(options):
                    valid.append(options[int(p) - 1])
                elif p in options:
                    valid.append(p)
            if valid:
                return valid
        else:
            if raw.isdigit() and 1 <= int(raw) <= len(options):
                return options[int(raw) - 1]
            if raw in options:
                return raw
        print(f"  Invalid. Enter number(s) or name(s) from the list.")

def interactive_setup(ion_data: dict) -> dict:
    print("\n" + "=" * 60)
    print("  ION Integration Setup Generator")
    print("  Answer six questions to generate your personalised guide.")
    print("=" * 60)

    role = prompt("1. Are you building a BPP (seller/provider) or BAP (buyer app)?",
                  ["BPP", "BAP"])

    sectors = ["trade", "logistics", "hospitality", "finance"]
    sector = prompt("2. Which sector?", sectors)

    patterns = available_patterns(sector)
    if not patterns:
        print(f"ERROR: No patterns found for sector '{sector}'", file=sys.stderr)
        sys.exit(1)
    pattern = prompt("3. Which pattern?", patterns)

    crcs = available_crcs(ion_data)
    sector_crcs = [c for c in crcs if c.startswith(sector[:3].upper())]
    if not sector_crcs:
        sector_crcs = crcs
    selected_crcs = prompt("4. Which product categories (CRCs)? (select one or more)",
                           sector_crcs, multi=True)

    variants = available_variants(sector)
    always_active = ["cross-cutting"]
    optional = [v for v in variants if v not in always_active]
    print(f"\n5. Which variants apply? (cross-cutting is always included)")
    selected_variants = prompt("   Additional variants:", optional, multi=True, default="none")
    if selected_variants == ["none"] or selected_variants == "none":
        selected_variants = []
    selected_variants = list(set(always_active + selected_variants))

    payment_methods = ["QRIS", "COD", "VIRTUAL_ACCOUNT", "EWALLET", "BANK_TRANSFER",
                       "CREDIT_CARD", "DEBIT_CARD", "BNPL"]
    selected_payment = prompt("6. Which payment methods?", payment_methods, multi=True, default="QRIS")

    return {
        "role": role, "sector": sector, "pattern": pattern,
        "crcs": selected_crcs, "variants": selected_variants, "payment": selected_payment,
    }

# ── Output generators ─────────────────────────────────────────────────────────

def make_readme(cfg: dict, pattern_data: dict) -> str:
    role, sector, pattern = cfg["role"], cfg["sector"], cfg["pattern"]
    crcs = ", ".join(cfg["crcs"])
    variants = ", ".join(cfg["variants"])
    payment = ", ".join(cfg["payment"])

    return f"""# ION Integration Guide — {role} / {sector} / {pattern}

Generated by `ion_setup.py` v{VERSION} from {SPEC_VERSION}.

## Who you are on ION

You are building a **{role}** ({"seller/provider app" if role=="BPP" else "buyer app"}) on the
**{sector}** sector, using the **{pattern}** commerce pattern.

- **Product categories (CRCs):** {crcs}
- **Active variants:** {variants}
- **Payment methods:** {payment}

## What each file in this folder is for

| File | Purpose |
|---|---|
| `01-endpoints.md` | Complete endpoint list — which you implement, which direction, which flow phase |
| `02-catalog/checklist.md` | Every field required for `publish_catalog`, labelled by source |
| `02-catalog/scaffold-publish_catalog.json` | Complete JSON scaffold with all required fields as placeholders |
| `02-catalog/policy-IRIs.md` | Available policy IRI options for your offer type |
| `03-transaction/` | One checklist + scaffold per API step in the transaction spine |
| `04-fulfilment/` | Per-state `on_status` scaffolds and variant-specific checklists |
| `05-post-order/` | Reconciliation, rating, and dispute scaffolds |
| `06-business-rules.md` | All business rules in plain English, grouped by step |
| `07-errors.md` | All error codes you must handle, with resolution text |
| `08-pack-reference.md` | Active schema packs: `@context` URL, `@type`, link to `attributes.yaml` |

## Start here

1. Read `01-endpoints.md` to understand what you implement.
2. Open `02-catalog/checklist.md` — fill every field before your first publish.
3. Work through `03-transaction/` step by step.
4. Check `06-business-rules.md` for the business logic ONIX expects.
5. Keep `07-errors.md` open while testing — it tells you exactly what to fix on rejection.
"""

def make_endpoints(cfg: dict, pattern_data: dict, variant_datas: list[dict]) -> str:
    role = cfg["role"]
    lines = ["# Endpoints\n",
             f"Role: **{role}** — {'you implement the BPP side of each call' if role=='BPP' else 'you implement the BAP side of each call'}\n"]

    lines.append("\n## Pattern spine\n")
    lines.append("| Step | Direction | You | Phase |\n|---|---|---|---|\n")

    for phase_key, phase in pattern_data.get("phases", {}).items():
        for step in phase.get("steps", []):
            step_name = step.get("step", "")
            trigger = step.get("trigger", "")
            full = f"`{step_name}[{trigger}]`" if trigger else f"`{step_name}`"
            frm, to = step.get("from", "?"), step.get("to", "?")
            direction = f"{frm} → {to}"
            you = "**implement**" if (role == "BPP" and frm == "BPP") or (role == "BAP" and frm == "BAP") else "receive"
            lines.append(f"| {full} | {direction} | {you} | {phase.get('name', phase_key)} |\n")

    for vdata in variant_datas:
        vname = vdata.get("variantType", "variant")
        lines.append(f"\n## Variant: {vname}\n")
        lines.append("| Step | Sub-flow | Direction | You |\n|---|---|---|---|\n")
        for sf_name, sf in vdata.get("subFlows", {}).items():
            for step in sf.get("steps", []):
                step_name = step.get("step", "")
                frm, to = step.get("from", "?"), step.get("to", "?")
                you = "**implement**" if (role == "BPP" and frm == "BPP") or (role == "BAP" and frm == "BAP") else "receive"
                lines.append(f"| `{step_name}` | {sf_name} | {frm} → {to} | {you} |\n")

    return "".join(lines)

def make_checklist(step_name: str, step_data: dict, cfg: dict,
                   ion_data: dict, is_catalog: bool = False) -> str:
    lines = [f"# Required Fields — `{step_name}`\n\n"]
    lines.append(f"Direction: {step_data.get('from','?')} → {step_data.get('to','?')}\n\n")

    always = get_always_required(ion_data)
    all_pf = all_pattern_fields(load_pattern(cfg["sector"], cfg["pattern"]))

    lines.append("## Network-policy fields (always required on ION)\n\n")
    lines.append("Source: `ion.yaml → x-ion-field-requirements.alwaysRequired`\n\n")
    for entry in always:
        schema = entry.get("schema", "")
        for f in entry.get("fields", []):
            not_in_p = f not in " ".join(all_pf)
            note = "  ← not in pattern.yaml" if not_in_p else ""
            lines.append(f"- [ ] `{schema}.{f}`{note}\n")

    for crc in cfg["crcs"]:
        rule = get_crc_rule(ion_data, crc)
        if rule and is_catalog:
            lines.append(f"\n## CRC-conditional fields — `{crc}`\n\n")
            lines.append(f"Source: `ion.yaml → x-ion-crc-rules`\n\n")
            for block in rule.get("requiredBlocks", []):
                lines.append(f"- [ ] `resourceAttributes.{block}` (entire block required)\n")
            for block, fields in rule.get("requiredFields", {}).items():
                for f in fields:
                    path = f"resourceAttributes.{f}" if block == "root" else f"resourceAttributes.{block}.{f}"
                    lines.append(f"- [ ] `{path}`\n")

    if is_catalog:
        discovery = []
        for pack in ["resource", "offer", "provider"]:
            p = load_profile(cfg["sector"], pack)
            discovery.extend(p.get("minimalForDiscovery", []))
        for p in ["product-compliance", "localization"]:
            pr = load_profile("core", p)
            discovery.extend(pr.get("minimalForDiscovery", []))
        if discovery:
            lines.append("\n## Discovery indexing fields\n\n")
            lines.append("Source: `profile.json → minimalForDiscovery` — missing = resource not indexed\n\n")
            for f in sorted(set(discovery)):
                lines.append(f"- [ ] `{f}`\n")

    pattern_fields = step_data.get("requiredFields", [])
    if pattern_fields:
        lines.append("\n## Pattern required fields\n\n")
        lines.append(f"Source: `flows/{cfg['sector']}/patterns/{cfg['pattern']}/v1/pattern.yaml`\n\n")
        for f in pattern_fields:
            lines.append(f"- [ ] `{f}`\n")

    cond = step_data.get("conditionalFields", [])
    if cond:
        lines.append("\n## Conditional fields\n\n")
        for cf in cond:
            field = cf.get("field", cf) if isinstance(cf, dict) else cf
            cond_str = cf.get("condition", "") if isinstance(cf, dict) else ""
            lines.append(f"- [ ] `{field}`\n")
            if cond_str:
                lines.append(f"  - Condition: {cond_str}\n")

    return "".join(lines)

def make_scaffold(step_name: str, step_data: dict, cfg: dict, ion_data: dict) -> str:
    """Generate a JSON scaffold for a given step."""
    sector, pattern, role = cfg["sector"], cfg["pattern"], cfg["role"]
    payment = cfg["payment"]

    context_block = {
        "action": step_name,
        "version": "2.0.0",
        "domain": f"ion:{sector}",
        "bapId": "<your-bapId>",
        "bapUri": "https://<your-bap-domain>/beckn",
        "bppId": "<bppId>",
        "bppUri": "https://<your-bpp-domain>/beckn",
        "transactionId": "<uuid — same across entire flow>",
        "messageId": "<uuid — new for each request>",
        "timestamp": "<ISO-8601-UTC e.g. 2026-06-03T10:30:00.000+07:00>",
        "ttl": "PT30S",
        "location": {"city": {"code": "<std:3171 for Jakarta — see BPS codes>"}},
    }

    # Build message based on step
    resource_attrs_context = get_pack_context_url(sector, "resource")
    resource_attrs_type = get_pack_type(sector, "resource")
    offer_attrs_context = get_pack_context_url(sector, "offer")
    offer_attrs_type = get_pack_type(sector, "offer")
    payment_context = get_pack_context_url("core", "payment")

    if "publish_catalog" in step_name:
        crcs = cfg["crcs"]
        crc_val = crcs[0] if crcs else "TRC-fashion"
        message = {
            "catalog": {
                "provider": {
                    "id": "<your-provider-id>",
                    "descriptor": {"name": "<your store name>"},
                    "providerAttributes": {
                        "@context": get_pack_context_url(sector, "provider"),
                        "@type": get_pack_type(sector, "provider"),
                        "storeStatus": "OPEN",
                        "operatingHours": [{"day": "<MON>", "open": "09:00", "close": "21:00"}],
                        "providerCategory": "<MERCHANT>",
                        "businessRegistration": {
                            "nib": "1234567890123",
                        },
                        "invoicingModel": "<PLATFORM_INVOICE>",
                    },
                    "availableAt": [{"gps": "<lat,lng>"}],
                },
                "resources": [{
                    "id": "<resource-id>",
                    "descriptor": {"name": "<product name>"},
                    "resourceAttributes": {
                        "@context": resource_attrs_context,
                        "@type": resource_attrs_type,
                        "crc": crc_val,
                        "resourceStructure": "<SIMPLE>",
                        "resourceTangibility": "<PHYSICAL>",
                        "images": ["<https://cdn.example.com/product.jpg>"],
                        "availability": {"status": "<IN_STOCK>"},
                        "countryOfOrigin": "<ID>",
                        "ageRestricted": False,
                        "logisticsServiceType": "<DELIVERY>",
                    },
                }],
                "offers": [{
                    "id": "<offer-id>",
                    "price": {"value": "<price>", "currency": "IDR"},
                    "offerAttributes": {
                        "@context": offer_attrs_context,
                        "@type": offer_attrs_type,
                        "policies": {
                            "cancellation": {"policyRef": "ion://policy/cancellation.trade.standard-v1"},
                            "returns": {"allowed": True, "policyRef": "ion://policy/return.trade.standard-v1"},
                            "warranty": {"policyRef": "ion://policy/warranty.trade.manufacturer-v1"},
                            "dispute": {"policyRef": "ion://policy/dispute.trade.standard-v1"},
                        },
                        "timeToShip": "<PT24H>",
                        "paymentConstraints": {"codAvailable": "COD" in payment},
                        "contactDetailsConsumerCare": {"phone": "<+6221XXXXXXX>"},
                        "displayLanguage": ["id"],
                    },
                }],
            }
        }
    elif step_name == "select":
        message = {
            "contract": {
                "participants": [{"role": "PROVIDER", "id": "<bppId>"}],
                "commitments": [{
                    "id": "<CMT-001>",
                    "commitmentAttributes": {
                        "@context": get_pack_context_url(sector, "commitment"),
                        "@type": get_pack_type(sector, "commitment"),
                        "lineId": "<L01>",
                        "resourceId": "<resource-id>",
                        "offerId": "<offer-id>",
                        "quantity": {"value": 1, "unit": "piece"},
                    },
                }],
                "performance": [{
                    "id": "<PERF-001>",
                    "performanceAttributes": {
                        "@context": get_pack_context_url(sector, "performance"),
                        "@type": get_pack_type(sector, "performance"),
                        "performanceMode": "<DELIVERY>",
                    },
                }],
            }
        }
    elif step_name == "init":
        message = {
            "contract": {
                "participants": [
                    {"role": "PROVIDER", "id": "<bppId>"},
                    {"role": "BUYER", "person": {"name": "<buyer name>"}, "contact": {"phone": "<+62XXXXXXXXXX>"},
                     "address": {"door": "<unit>", "building": "<building>", "street": "<street>",
                                 "city": "<city>", "state": "<province>", "country": "ID"}},
                ],
                "commitments": [{"id": "<CMT-001>"}],
                "performance": [{
                    "id": "<PERF-001>",
                    "performanceAttributes": {
                        "@context": get_pack_context_url(sector, "performance"),
                        "@type": get_pack_type(sector, "performance"),
                        "performanceMode": "<DELIVERY>",
                    },
                    "stops": [{"location": {"address": "<delivery address>", "gps": "<lat,lng>",
                                            "areaCode": "<kelurahan code>",
                                            "ionAddressAttributes": {"provinsiCode": "<ID-JK>"}}}],
                }],
                "settlements": [{
                    "settlementAttributes": {
                        "@context": payment_context,
                        "@type": "ion:PaymentDeclaration",
                        "method": payment[0] if payment else "QRIS",
                        "paymentRail": payment[0] if payment else "QRIS",
                        "collectedBy": "<BAP>",
                        "timing": "<PRE_ORDER>",
                        "status": "NOT_PAID",
                        "currency": "IDR",
                    }
                }],
            }
        }
    elif step_name == "confirm":
        message = {
            "contract": {
                "participants": [
                    {"role": "PROVIDER", "id": "<bppId>"},
                    {"role": "BUYER", "person": {"name": "<buyer name>"}, "contact": {"phone": "<+62XXXXXXXXXX>"}},
                ],
                "commitments": [{"id": "<CMT-001>"}],
                "performance": [{"id": "<PERF-001>"}],
                "settlements": [{
                    "settlementAttributes": {
                        "@context": payment_context,
                        "@type": "ion:PaymentDeclaration",
                        "method": payment[0] if payment else "QRIS",
                        "status": "PAID",
                        "currency": "IDR",
                    }
                }],
                "contractAttributes": {
                    "@context": get_pack_context_url(sector, "contract"),
                    "@type": get_pack_type(sector, "contract"),
                    "npwp": "<15-digit NPWP>",
                    "nib": "<13-digit NIB>",
                },
            }
        }
    elif step_name == "on_confirm":
        message = {
            "contract": {
                "id": "<contract-id>",
                "status": "ACTIVE",
                "performance": [{
                    "id": "<PERF-001>",
                    "status": {"descriptor": {"code": "ORDER_ACCEPTED"}},
                }],
                "settlements": [{"settlementAttributes": {"status": "PAID"}}],
                "contractAttributes": {
                    "@context": get_pack_context_url(sector, "contract"),
                    "@type": get_pack_type(sector, "contract"),
                    "fulfillingLocationId": "<warehouse-id>",
                },
            }
        }
    else:
        # Generic scaffold for other steps
        message = {"contract": {"id": "<contract-id>", "_note": f"Add fields per {step_name} checklist"}}

    scaffold = {"context": context_block, "message": message}
    return json.dumps(scaffold, indent=2, ensure_ascii=False)

def make_policy_iris(cfg: dict, policies: list) -> str:
    sector = cfg["sector"]
    lines = ["# Policy IRIs\n\n",
             "Use these IRIs in your offer `offerAttributes`. ONIX validates that each IRI resolves.\n\n"]

    categories = ["cancellation", "return", "warranty", "dispute", "grievance-sla",
                  "payment-terms", "penalty", "sla"]
    for cat in categories:
        cat_policies = [p for p in policies
                        if p.get("category", "").lower().replace("_", "-") == cat
                        or cat in p.get("iri", "").lower()]
        if cat_policies:
            lines.append(f"## {cat.capitalize()}\n\n")
            for p in cat_policies[:6]:
                label = p.get("displayText", {}).get("en", p.get("iri", ""))
                status = p.get("status", "ratified")
                lines.append(f"- `{p['iri']}` — {label} [{status}]\n")
            lines.append("\n")
    return "".join(lines)

def make_business_rules(cfg: dict, pattern_data: dict, variant_datas: list[dict]) -> str:
    lines = ["# Business Rules\n\n",
             "Plain-English rules ONIX expects. Source: pattern.yaml and variant.yaml `businessRules` blocks.\n\n"]

    for phase_key, phase in pattern_data.get("phases", {}).items():
        for step in phase.get("steps", []):
            rules = step.get("businessRules", [])
            if rules:
                lines.append(f"## {step.get('step', phase_key)}\n\n")
                for r in rules:
                    lines.append(f"- {r}\n")
                lines.append("\n")

    for vdata in variant_datas:
        vname = vdata.get("variantType", "variant")
        lines.append(f"## Variant: {vname}\n\n")
        for sf_name, sf in vdata.get("subFlows", {}).items():
            rules = sf.get("businessRules", [])
            if rules:
                lines.append(f"### {sf_name}\n\n")
                for r in rules:
                    lines.append(f"- {r}\n")
                lines.append("\n")

    if len(lines) < 4:
        lines.append("_Business rules are defined in the pattern and variant YAML files. "
                     "Check the source files for the latest rules as the spec evolves._\n")
    return "".join(lines)

def make_errors_guide(cfg: dict, errors: list) -> str:
    sector = cfg["sector"]
    lines = ["# Error Handling\n\n",
             "When ONIX returns a NACK, look up the `error.code` here. "
             "Full registry: `errors/registry.json`.\n\n"]

    # Filter to relevant errors (core + sector)
    sector_prefix = {"trade": "ION-A", "logistics": "ION-B", "finance": "ION-F"}.get(sector, "")
    relevant = [e for e in errors
                if not e["code"][4:5].isalpha() or e["code"].startswith(sector_prefix)]

    by_category: dict[str, list] = {}
    for e in relevant:
        cat = e.get("category", "GENERAL")
        by_category.setdefault(cat, []).append(e)

    for cat, errs in sorted(by_category.items()):
        lines.append(f"## {cat}\n\n")
        lines.append("| Code | Title | Resolution |\n|---|---|---|\n")
        for e in errs[:10]:
            title = e.get("title", {}).get("en", e["code"])
            res = e.get("resolution", {}).get("en", "See registry.json")
            res_short = res[:60] + "…" if len(res) > 60 else res
            lines.append(f"| `{e['code']}` | {title} | {res_short} |\n")
        lines.append("\n")

    return "".join(lines)

def make_pack_reference(cfg: dict, pattern_data: dict) -> str:
    sector = cfg["sector"]
    lines = ["# Schema Pack Reference\n\n",
             "Active packs for your integration. Use the `@context` URL and `@type` in every Attributes bag.\n\n"]
    lines.append("| Pack | @context URL | @type | attributes.yaml |\n|---|---|---|---|\n")

    seen = set()
    for phase in pattern_data.get("phases", {}).values():
        for step in phase.get("steps", []):
            for sec, packs in step.get("schemaPacks", {}).items():
                for pack in packs:
                    pack_name = pack.split("/")[0]
                    key = f"{sec}/{pack_name}"
                    if key in seen:
                        continue
                    seen.add(key)
                    ctx_url = get_pack_context_url(sec, pack_name)
                    ion_type = get_pack_type(sec, pack_name)
                    attrs_path = f"schema/extensions/{sec}/{pack_name}/v1/attributes.yaml"
                    lines.append(f"| `{sec}/{pack_name}` | `{ctx_url}` | `{ion_type}` | `{attrs_path}` |\n")

    return "".join(lines)

# ── Main ──────────────────────────────────────────────────────────────────────

def generate(cfg: dict, output_dir: Path, as_json: bool) -> None:
    ion_data = load_ion_yaml()
    pattern_data = load_pattern(cfg["sector"], cfg["pattern"])
    variant_datas = [load_variant(cfg["sector"], v) for v in cfg["variants"]
                     if (REPO_ROOT / f"flows/{cfg['sector']}/variants/{v}/v1/variant.yaml").exists()]
    policies = load_policies()
    errors = load_errors()
    steps = steps_with_fields(pattern_data)

    if as_json:
        out = {
            "meta": {"tool": "ion_setup", "version": VERSION, "spec": SPEC_VERSION, **cfg},
            "endpoints": [
                {"step": s.get("step"), "trigger": s.get("trigger"), "phase": s.get("_phase"),
                 "from": s.get("from"), "to": s.get("to"),
                 "requiredFields": s.get("requiredFields", [])}
                for s in steps
            ],
            "packs": [
                {"sector": sec, "pack": pack.split("/")[0],
                 "contextUrl": get_pack_context_url(sec, pack.split("/")[0]),
                 "type": get_pack_type(sec, pack.split("/")[0])}
                for phase in pattern_data.get("phases", {}).values()
                for step in phase.get("steps", [])
                for sec, packs in step.get("schemaPacks", {}).items()
                for pack in packs
            ],
        }
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return

    # Create output directory
    label = f"{cfg['role']}-{cfg['sector']}-{cfg['pattern']}-{'+'.join(cfg['crcs'][:2])}"
    out_dir = output_dir / label
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "02-catalog").mkdir(exist_ok=True)
    (out_dir / "03-transaction").mkdir(exist_ok=True)
    (out_dir / "04-fulfilment").mkdir(exist_ok=True)
    (out_dir / "05-post-order").mkdir(exist_ok=True)

    def write(path: Path, content: str):
        with open(path, "w") as f:
            f.write(content)
        print(f"  Created: {path.relative_to(output_dir)}")

    print(f"\nGenerating integration guide → {out_dir}/")

    write(out_dir / "README.md", make_readme(cfg, pattern_data))
    write(out_dir / "01-endpoints.md", make_endpoints(cfg, pattern_data, variant_datas))

    # Catalog files
    catalog_step = next((s for s in steps if "publish_catalog" in s.get("step", "")), {})
    write(out_dir / "02-catalog/checklist.md",
          make_checklist("publish_catalog", catalog_step, cfg, ion_data, is_catalog=True))
    write(out_dir / "02-catalog/scaffold-publish_catalog.json",
          make_scaffold("publish_catalog", catalog_step, cfg, ion_data))
    write(out_dir / "02-catalog/policy-IRIs.md", make_policy_iris(cfg, policies))

    # Transaction steps
    tx_steps = [s for s in steps if s.get("_phase") in ("Transaction", "Phase 2")]
    for step in tx_steps:
        sname = step.get("step", "step")
        write(out_dir / f"03-transaction/{sname}-checklist.md",
              make_checklist(sname, step, cfg, ion_data))
        write(out_dir / f"03-transaction/{sname}-scaffold.json",
              make_scaffold(sname, step, cfg, ion_data))

    # Fulfilment steps
    full_steps = [s for s in steps if s.get("_phase") in ("Fulfilment", "Phase 3")]
    for step in full_steps:
        trigger = step.get("trigger", "")
        fname = f"on_status-{trigger}" if trigger else step.get("step", "step")
        write(out_dir / f"04-fulfilment/{fname}.json",
              make_scaffold(f"on_status[{trigger}]" if trigger else "on_status", step, cfg, ion_data))

    # Post-order (from cross-cutting variant)
    seen_post = set()
    for vdata in variant_datas:
        if "cross-cutting" in vdata.get("variantType", ""):
            for sf_name, sf in vdata.get("subFlows", {}).items():
                if sf_name in ("reconcile", "rate", "support", "raise"):
                    for step in sf.get("steps", []):
                        sname = step.get("step", sf_name)
                        fname = f"05-post-order/{sname}-scaffold.json"
                        if fname in seen_post:
                            continue
                        seen_post.add(fname)
                        write(out_dir / fname, make_scaffold(sname, step, cfg, ion_data))

    write(out_dir / "06-business-rules.md", make_business_rules(cfg, pattern_data, variant_datas))
    write(out_dir / "07-errors.md", make_errors_guide(cfg, errors))
    write(out_dir / "08-pack-reference.md", make_pack_reference(cfg, pattern_data))

    print(f"\nDone. Open {out_dir}/README.md to start.\n")


def main():
    parser = argparse.ArgumentParser(
        description="Generate a personalised ION integration guide.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python tools/ion_setup.py                          # interactive
  python tools/ion_setup.py --role BPP --sector trade --pattern storefront \\
      --crcs TRC-fashion --variants cross-cutting,cancellation --payment QRIS,COD
  python tools/ion_setup.py --role BPP --sector logistics --pattern parcel \\
      --crcs LGC-lastmile --variants cross-cutting --payment COD
        """,
    )
    parser.add_argument("--role", choices=["BPP", "BAP"])
    parser.add_argument("--sector")
    parser.add_argument("--pattern")
    parser.add_argument("--crcs", help="Comma-separated CRC codes")
    parser.add_argument("--variants", help="Comma-separated variant names")
    parser.add_argument("--payment", help="Comma-separated payment methods")
    parser.add_argument("--output", default="ion-integration", help="Output directory (default: ion-integration/)")
    parser.add_argument("--json", action="store_true", help="JSON output for AI agent consumption")
    parser.add_argument("--version", action="store_true")
    args = parser.parse_args()

    if args.version:
        print(f"ion_setup v{VERSION} — {SPEC_VERSION}")
        sys.exit(0)

    ion_data = load_ion_yaml()

    if args.role and args.sector and args.pattern and args.crcs and args.variants and args.payment:
        cfg = {
            "role": args.role,
            "sector": args.sector,
            "pattern": args.pattern,
            "crcs": [c.strip() for c in args.crcs.split(",")],
            "variants": [v.strip() for v in args.variants.split(",")],
            "payment": [p.strip() for p in args.payment.split(",")],
        }
    else:
        cfg = interactive_setup(ion_data)

    output_dir = Path(args.output)
    generate(cfg, output_dir, as_json=args.json)


if __name__ == "__main__":
    main()
