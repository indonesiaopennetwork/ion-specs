#!/usr/bin/env python3
"""
ion_required_fields.py — ION required fields query tool (TOOL-1)

Answers "which fields do I have to send?" for a specific (sector + pattern + CRC)
combination by merging four sources:
  1. flows/{sector}/patterns/{pattern}/v1/pattern.yaml  → per-step required fields
  2. ion.yaml → x-ion-field-requirements.alwaysRequired  → network-wide always-required
  3. ion.yaml → x-ion-crc-rules                          → CRC-conditional required fields
  4. schema/extensions/{pack}/v1/profile.json            → minimalForDiscovery fields

Usage:
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion --step confirm
  python tools/ion_required_fields.py --sector logistics --pattern parcel --crc LGC-lastmile
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion --json
  python tools/ion_required_fields.py --version
"""

import argparse
import json
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


# ── Loaders ──────────────────────────────────────────────────────────────────

def load_yaml(path: Path) -> dict:
    if not path.exists():
        return {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def load_ion_yaml() -> dict:
    path = REPO_ROOT / "releases/release1/schema/core/api/v2.0.0/ion.yaml"
    if not path.exists():
        print(f"ERROR: ion.yaml not found at {path}", file=sys.stderr)
        sys.exit(1)
    with open(path) as f:
        return yaml.safe_load(f) or {}


def load_pattern(sector: str, pattern: str) -> dict:
    path = REPO_ROOT / f"flows/{sector}/patterns/{pattern}/v1/pattern.yaml"
    if not path.exists():
        print(f"ERROR: Pattern not found: {path}", file=sys.stderr)
        print(f"  Available patterns for '{sector}':", file=sys.stderr)
        pattern_dir = REPO_ROOT / f"flows/{sector}/patterns"
        if pattern_dir.exists():
            for p in sorted(pattern_dir.iterdir()):
                if p.is_dir():
                    print(f"    {p.name}", file=sys.stderr)
        sys.exit(1)
    return load_yaml(path)


def load_profile(sector: str, pack: str) -> dict:
    path = REPO_ROOT / f"schema/extensions/{sector}/{pack}/v1/profile.json"
    if not path.exists():
        return {}
    with open(path) as f:
        return json.load(f)


# ── Extraction helpers ────────────────────────────────────────────────────────

# Schemas that only apply at specific steps.
# Schemas absent from this map apply at every step (NPWP, NIB, halalStatus etc.)
_STEP_SCOPING: dict[str, list[str]] = {
    "IONRating":         ["rate", "on_rate"],
    "IONReconciliation": ["reconcile", "on_reconcile"],
    "IONSupportTicket":  ["support", "on_support"],
    "IONTicket":         ["raise", "on_raise", "raise_status", "on_raise_status",
                          "raise_close", "on_raise_close", "raise_details", "on_raise_details"],
    "QRIS":              ["init", "on_init", "confirm", "on_confirm"],
    "VirtualAccount":    ["init", "on_init", "confirm", "on_confirm"],
    "EWallet":           ["init", "on_init", "confirm", "on_confirm"],
    "BNPL":              ["init", "on_init", "confirm", "on_confirm"],
    "BankTransfer":      ["init", "on_init", "confirm", "on_confirm"],
    "CardPayment":       ["init", "on_init", "confirm", "on_confirm"],
    "BISettlement":      ["reconcile", "on_reconcile"],
    "Refund":            ["cancel", "on_cancel"],
    "CreditTerms":       ["init", "on_init", "confirm", "on_confirm"],
    "CashOnDelivery":    ["init", "on_init", "confirm", "on_confirm"],
    "TradeCommitment":   ["select", "on_select", "init", "on_init", "confirm", "on_confirm"],
    "TradeConsideration":["on_select", "on_init", "on_confirm"],
    "TradeOffer":        ["publish_catalog"],
    "TradePerformance":  ["on_select", "on_init", "on_confirm", "on_status"],
    "TradeProvider":     ["publish_catalog"],
    "TradeResource":     ["publish_catalog", "on_discover"],
    "TradeContract":     ["init", "on_init", "confirm", "on_confirm"],
    "LogisticsOffer":    ["publish_catalog"],
    "LogisticsConsideration": ["on_select", "on_init", "on_confirm"],
    "LogisticsProvider": ["publish_catalog"],
    "LogisticsResource": ["publish_catalog", "on_discover"],
    "LogisticsTracking": ["track", "on_track"],
    "LogisticsAgent":    ["select", "on_select", "init", "on_init", "confirm", "on_confirm"],
}


def get_always_required(ion_data: dict, step_filter: str | None = None) -> dict[str, list[str]]:
    """Returns {schema_name: [field, ...]} for always-required fields.
    
    When step_filter is provided, only returns schemas relevant to that step,
    eliminating noise from schemas that only apply at other steps.
    """
    result = {}
    fields_list = (
        ion_data.get("x-ion-profile", {})
        .get("x-ion-field-requirements", {})
        .get("alwaysRequired", {})
        .get("fields", [])
    )
    for entry in fields_list:
        schema = entry.get("schema", "")
        fields = entry.get("fields", [])
        if step_filter and schema in _STEP_SCOPING:
            # Only include if this step is in the schema's allowed steps
            allowed_steps = _STEP_SCOPING[schema]
            if not any(s in step_filter for s in allowed_steps):
                continue
        result[schema] = fields
    return result


def get_crc_rules(ion_data: dict, crc: str) -> dict:
    """Returns the CRC rule dict for the given CRC code, or {}."""
    rules = (
        ion_data.get("x-ion-profile", {})
        .get("x-ion-crc-rules", {})
        .get("rules", [])
    )
    for rule in rules:
        if rule.get("crc") == crc:
            return rule
    return {}


def get_discovery_fields(sector: str, packs: list[str]) -> list[str]:
    """Returns minimalForDiscovery fields across all packs for this sector."""
    fields = []
    for pack in packs:
        profile = load_profile(sector, pack)
        for f in profile.get("minimalForDiscovery", []):
            if f not in fields:
                fields.append(f)
    # Also check core packs
    for pack in ["product-compliance", "localization", "address"]:
        profile = load_profile("core", pack)
        for f in profile.get("minimalForDiscovery", []):
            if f not in fields:
                fields.append(f)
    return fields


def get_pattern_steps(pattern_data: dict, step_filter: str = None) -> list[dict]:
    """Extract all steps (or a filtered subset) from pattern phases."""
    steps = []
    for phase_key, phase in pattern_data.get("phases", {}).items():
        for step in phase.get("steps", []):
            step_name = step.get("step", "")
            trigger = step.get("trigger", "")
            full_name = f"{step_name}[{trigger}]" if trigger else step_name

            if step_filter:
                if step_filter not in [step_name, full_name]:
                    continue

            step["_phase"] = phase.get("name", phase_key)
            step["_full_name"] = full_name
            steps.append(step)
    return steps


def infer_packs(sector: str, pattern_data: dict) -> list[str]:
    """Collect all sector-specific packs referenced in the pattern."""
    packs = set()
    for phase in pattern_data.get("phases", {}).values():
        for step in phase.get("steps", []):
            schema_packs = step.get("schemaPacks", {})
            for pack in schema_packs.get(sector, []):
                packs.add(pack.split("/")[0])  # strip /v1
    return sorted(packs)


# ── Main output builder ───────────────────────────────────────────────────────

def build_report(sector: str, pattern: str, crc: str | None,
                 step_filter: str | None, as_json: bool) -> dict:

    ion_data = load_ion_yaml()
    pattern_data = load_pattern(sector, pattern)

    always_required = get_always_required(ion_data, step_filter)
    crc_rule = get_crc_rules(ion_data, crc) if crc else {}
    sector_packs = infer_packs(sector, pattern_data)
    discovery_fields = get_discovery_fields(sector, sector_packs)
    steps = get_pattern_steps(pattern_data, step_filter)

    # Collect all pattern-level required field names (flat, for ← not in pattern.yaml annotation)
    all_pattern_fields: set[str] = set()
    for step in steps:
        all_pattern_fields.update(step.get("requiredFields", []))

    report = {
        "meta": {
            "tool": "ion_required_fields",
            "version": VERSION,
            "spec": SPEC_VERSION,
            "sector": sector,
            "pattern": pattern,
            "crc": crc,
            "step_filter": step_filter,
        },
        "steps": [],
    }

    for step in steps:
        step_name = step.get("_full_name", step.get("step", ""))
        phase = step.get("_phase", "")
        pattern_fields = step.get("requiredFields", [])
        conditional_fields = step.get("conditionalFields", [])

        entry = {
            "step": step_name,
            "phase": phase,
            "direction": f"{step.get('from', '?')} → {step.get('to', '?')}",
            "fields": [],
        }

        # Source 1: network-policy always-required, scoped to relevant steps
        step_always = get_always_required(ion_data, step_name)
        for schema, fields in step_always.items():
            for field in fields:
                not_in_pattern = field not in " ".join(all_pattern_fields)
                entry["fields"].append({
                    "source": "network-policy",
                    "schema": schema,
                    "field": field,
                    "note": "not in pattern.yaml" if not_in_pattern else None,
                })

        # Source 2: CRC-conditional fields (only on steps that touch catalog/resources)
        if crc_rule and ("publish_catalog" in step_name or "resource" in step_name.lower()):
            for block in crc_rule.get("requiredBlocks", []):
                entry["fields"].append({
                    "source": f"crc:{crc}",
                    "schema": "IONTradeResource" if sector == "trade" else f"ION{sector.capitalize()}Resource",
                    "field": block,
                    "note": "entire block required",
                })
            for block, block_fields in crc_rule.get("requiredFields", {}).items():
                if block == "root":
                    for f in block_fields:
                        entry["fields"].append({
                            "source": f"crc:{crc}",
                            "schema": "Resource.resourceAttributes",
                            "field": f,
                            "note": None,
                        })
                else:
                    for f in block_fields:
                        entry["fields"].append({
                            "source": f"crc:{crc}",
                            "schema": f"resourceAttributes.{block}",
                            "field": f,
                            "note": None,
                        })

        # Source 3: discovery fields (only on publish_catalog step)
        if "publish_catalog" in step_name:
            for f in discovery_fields:
                entry["fields"].append({
                    "source": "discovery",
                    "schema": "Resource.resourceAttributes",
                    "field": f,
                    "note": "required for catalogue indexing",
                })

        # Source 4: pattern required fields
        for f in pattern_fields:
            entry["fields"].append({
                "source": "pattern",
                "schema": None,
                "field": f,
                "note": None,
            })

        # Conditional fields (informational)
        entry["conditionalFields"] = [
            {"field": cf.get("field", cf) if isinstance(cf, dict) else cf,
             "condition": cf.get("condition", "") if isinstance(cf, dict) else ""}
            for cf in conditional_fields
        ]

        report["steps"].append(entry)

    return report


def print_report(report: dict) -> None:
    meta = report["meta"]
    crc_label = f", CRC: {meta['crc']}" if meta["crc"] else ""
    print(f"\nION Required Fields — {meta['sector'].upper()} / {meta['pattern']}{crc_label}")
    print(f"Spec: {meta['spec']}  |  Tool: v{meta['version']}")
    print("=" * 72)

    SOURCE_WIDTH = 24
    FIELD_WIDTH = 44

    for step_data in report["steps"]:
        print(f"\nStep: {step_data['step']}  ({step_data['phase']})")
        print(f"  Direction: {step_data['direction']}")

        fields = step_data["fields"]
        if not fields:
            print("  (no required fields for this step)")
        else:
            for f in fields:
                source_tag = f"[{f['source']}]"
                field_str = f["field"]
                if f.get("schema"):
                    field_str = f"{f['schema']}.{f['field']}" if "." not in f["field"] else f["field"]
                note = f"  ← {f['note']}" if f.get("note") else ""
                print(f"  {source_tag:<{SOURCE_WIDTH}} {field_str:<{FIELD_WIDTH}}{note}")

        cond = step_data.get("conditionalFields", [])
        if cond:
            print(f"  --- Conditional ---")
            for cf in cond:
                print(f"  [conditional]           {cf['field']}")
                if cf.get("condition"):
                    print(f"  {'':24}  ↳ {cf['condition']}")

    print()


def main():
    parser = argparse.ArgumentParser(
        description="Query required fields for an ION integration scenario.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-food-bev --step confirm
  python tools/ion_required_fields.py --sector logistics --pattern parcel --crc LGC-lastmile
  python tools/ion_required_fields.py --sector trade --pattern storefront --crc TRC-fashion --json
        """,
    )
    parser.add_argument("--sector", help="Sector: trade, logistics, hospitality, finance")
    parser.add_argument("--pattern", help="Pattern name: storefront, parcel, delivery-order, etc.")
    parser.add_argument("--crc", help="CRC code: TRC-fashion, TRC-food-bev, LGC-lastmile, etc.", default=None)
    parser.add_argument("--step", help="Filter to a single step: select, confirm, etc.", default=None)
    parser.add_argument("--json", action="store_true", help="Output as JSON (for AI agent consumption)")
    parser.add_argument("--version", action="store_true", help="Print tool version and exit")
    args = parser.parse_args()

    if args.version:
        print(f"ion_required_fields v{VERSION} — {SPEC_VERSION}")
        sys.exit(0)

    if not args.sector or not args.pattern:
        parser.print_help()
        sys.exit(1)

    report = build_report(
        sector=args.sector,
        pattern=args.pattern,
        crc=args.crc,
        step_filter=args.step,
        as_json=args.json,
    )

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_report(report)


if __name__ == "__main__":
    main()
