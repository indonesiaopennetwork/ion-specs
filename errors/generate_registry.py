#!/usr/bin/env python3
"""
Generate errors/registry.json — unified ION error registry.

Reads all category YAML files (trade/core + logistics + finance) and writes
a single unified registry.json plus sector-specific views.

Usage: python errors/generate_registry.py

Code naming scheme:
  ION-1xxx .. ION-9xxx   Cross-sector (transport, catalog, transaction,
                          fulfillment, post-order, settlement, network,
                          schema, system)
  ION-Bxxx               Logistics sector
  ION-Fxxx               Finance sector

Run after adding or modifying any error entry.
Exits non-zero on duplicate codes, malformed entries, or missing required fields.
"""

import json
import yaml
import sys
from pathlib import Path

# Cross-sector (trade / core) files — code format ION-Nxxx
CORE_FILES = [
    "transport.yaml",
    "catalog.yaml",
    "transaction.yaml",
    "fulfillment.yaml",
    "post-order.yaml",
    "settlement.yaml",
    "network.yaml",
    "schema.yaml",
    "system.yaml",
]

# Sector-specific files — normalised to same schema as core
SECTOR_FILES = [
    "trade.yaml",       # ION-Axxx (trade-sector-specific)
    "logistics.yaml",   # ION-Bxxx
    "finance.yaml",     # ION-Fxxx
]

ALL_FILES = CORE_FILES + SECTOR_FILES

REQUIRED_FIELDS = ["code", "http_status", "category", "title", "description", "resolution"]


def validate_and_load(errors_dir: Path) -> tuple[list[dict], list[str]]:
    all_errors = []
    seen_codes = {}
    fatal_errors = []

    for filename in ALL_FILES:
        filepath = errors_dir / filename
        if not filepath.exists():
            fatal_errors.append(f"{filename}: file missing")
            continue

        with open(filepath) as f:
            try:
                raw = yaml.safe_load(f) or []
            except yaml.YAMLError as e:
                fatal_errors.append(f"{filename}: YAML parse error — {e}")
                continue

        if not isinstance(raw, list):
            fatal_errors.append(f"{filename}: top-level must be a list of error objects")
            continue

        for i, entry in enumerate(raw):
            if not isinstance(entry, dict):
                fatal_errors.append(f"{filename}[{i}]: entry is not an object")
                continue

            code = entry.get("code")
            if not code:
                fatal_errors.append(f"{filename}[{i}]: missing 'code' field")
                continue

            # Validate code format: ION-Nxxx, ION-Bxxx, ION-Fxxx, or ION-BNxxxx
            import re
            if not re.match(r'^ION-[A-Z]?\d{4,}$', code) and not re.match(r'^ION-[A-Z]\d{4,}$', code):
                fatal_errors.append(
                    f"{code} in {filename}: malformed code "
                    f"(expected ION-Nxxx, ION-BNxxx, or ION-FNxxx)"
                )
                continue

            # Check required fields
            missing = [k for k in REQUIRED_FIELDS if k not in entry]
            if missing:
                fatal_errors.append(f"{code} in {filename}: missing required fields — {missing}")
                continue

            # Duplicates are hard failures
            if code in seen_codes:
                fatal_errors.append(
                    f"DUPLICATE: {code} in {filename} — first seen in {seen_codes[code]}"
                )
                continue
            seen_codes[code] = filename

            # title / description / resolution must have 'en'
            for field in ("title", "description", "resolution"):
                val = entry.get(field)
                if not isinstance(val, dict) or "en" not in val:
                    fatal_errors.append(
                        f"{code} in {filename}: '{field}' must be a dict with at least 'en' key"
                    )

            all_errors.append(entry)

    return all_errors, fatal_errors


def generate():
    errors_dir = Path(__file__).parent
    all_errors, fatal_errors = validate_and_load(errors_dir)

    if fatal_errors:
        print("ERROR: Error registry validation failed:", file=sys.stderr)
        for err in fatal_errors:
            print(f"  - {err}", file=sys.stderr)
        print(f"\n{len(fatal_errors)} error(s) — registry NOT regenerated", file=sys.stderr)
        sys.exit(1)

    # Sort: core codes first (ION-[0-9]), then logistics (ION-B), then finance (ION-F)
    def sort_key(e):
        code = e.get("code", "")
        if code.startswith("ION-A"):
            prefix = "1"  # trade sector
        elif code.startswith("ION-B"):
            prefix = "2"  # logistics sector
        elif code.startswith("ION-F"):
            prefix = "3"  # finance sector
        else:
            prefix = "0"  # core/cross-sector
        return prefix + code

    all_errors.sort(key=sort_key)

    # ── Unified registry ────────────────────────────────────────────
    registry = {
        "_generated": "Do not edit directly. Run errors/generate_registry.py.",
        "_source": "errors/*.yaml (trade/core + logistics + finance)",
        "_scheme": (
            "ION-1xxx..ION-9xxx = cross-sector/universal | "
            "ION-Axxx = trade | "
            "ION-Bxxx = logistics | "
            "ION-Fxxx = finance"
        ),
        "version": "2.0.0",
        "count": len(all_errors),
        "sectors": {
            "core": sum(1 for e in all_errors if not e["code"][4].isalpha()),
            "trade": sum(1 for e in all_errors if e["code"].startswith("ION-A")),
            "logistics": sum(1 for e in all_errors if e["code"].startswith("ION-B")),
            "finance": sum(1 for e in all_errors if e["code"].startswith("ION-F")),
        },
        "errors": all_errors,
    }

    unified_out = errors_dir / "registry.json"
    with open(unified_out, "w") as f:
        json.dump(registry, f, indent=2, ensure_ascii=False)
    print(
        f"Generated registry.json: {len(all_errors)} total errors "
        f"({registry['sectors']['core']} core, "
        f"{registry['sectors']['logistics']} logistics, "
        f"{registry['sectors']['finance']} finance)"
    )

    # ── Sector views ────────────────────────────────────────────────
    for sector_name, predicate, out_name in [
        ("trade",     lambda e: e["code"].startswith("ION-A"), "trade-registry.json"),
        ("logistics", lambda e: e["code"].startswith("ION-B"), "logistics-registry.json"),
        ("finance",   lambda e: e["code"].startswith("ION-F"), "finance-registry.json"),
    ]:
        sector_errors = [e for e in all_errors if predicate(e)]
        sector_reg = {
            "_generated": "Do not edit directly. Run errors/generate_registry.py.",
            "_source": f"errors/{sector_name}.yaml",
            "version": "2.0.0",
            "sector": sector_name,
            "count": len(sector_errors),
            "errors": sector_errors,
        }
        out = errors_dir / out_name
        with open(out, "w") as f:
            json.dump(sector_reg, f, indent=2, ensure_ascii=False)
        print(f"Generated {out_name}: {len(sector_errors)} {sector_name} errors")


if __name__ == "__main__":
    generate()
