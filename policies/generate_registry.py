#!/usr/bin/env python3
"""Generate policies/registry.json from per-category YAML terms documents.

Directory convention:
  policies/{category}/v1/{file}.yaml            Cross-sector or single-sector policies
  policies/{category}/v1/trade/{file}.yaml      Trade-sector variants of a cross-sector category
  policies/{category}/v1/logistics/{file}.yaml  Logistics-sector variants
  policies/{category}/v1/finance/{file}.yaml    Finance-sector variants

All policies use the same document format:
  iri:          ion://policy/{category}.{sector-or-scope}.{name}
  version:      semantic version string
  category:     SCREAMING_SNAKE_CASE category label
  status:       ratified | draft | deprecated
  displayText:
    id:         Bahasa Indonesia display text (always required)
    en:         English display text
  versionEffectiveFrom: ISO date
  supersededBy: null or replacement IRI
  deprecatedAt: null or deprecation date

Run after adding or modifying any policy file.
Duplicated IRIs cause a non-zero exit. Wire into CI as pre-merge gate.

Scheme:
  ion://policy/{category}.{sector-or-scope}.{variant-name}
    category:        return | cancel | warranty | dispute | grievance-sla |
                     payment-terms | penalty | sla | evidence | re-attempt |
                     weight-dispute | liability | incident | rts-handoff |
                     insurance | collateral | kyc | finance.* | ...
    sector-or-scope: trade | logistics | finance | consumer | commercial |
                     b2b | b2g | standard | enterprise | network
    variant-name:    slug identifying the specific variant
"""

import yaml
import json
import sys
from pathlib import Path

POLICY_ROOT = Path(__file__).parent
OUTPUT = POLICY_ROOT / "registry.json"

# Category directories to scan (determines CATEGORY label in registry entry)
CATEGORIES = [
    # Trade sector
    "return", "warranty",
    # Cross-sector (with sector sub-folders for variants)
    "cancellation", "dispute", "grievance-sla", "payment-terms", "penalty", "insurance",
    # Logistics sector
    "evidence", "sla", "re-attempt", "weight-dispute", "liability",
    "incident", "rts-handoff", "logistics-fwa",
    # Finance sector (all sub-categories under finance/ are finance-sector)
    "collateral", "collections-conduct", "credit-assessment", "disbursement",
    "interest-rate-cap", "kyc", "ltv-cap", "prepayment", "restructure", "slik-reporting",
]

REQUIRED_FIELDS = ["iri", "version", "status", "displayText"]


# Explicit sector assignment for pure-sector category directories
CATEGORY_SECTOR = {
    "return": "trade", "warranty": "trade",
    "collateral": "finance", "collections-conduct": "finance",
    "credit-assessment": "finance", "disbursement": "finance",
    "interest-rate-cap": "finance", "kyc": "finance",
    "ltv-cap": "finance", "prepayment": "finance",
    "restructure": "finance", "slik-reporting": "finance",
    "evidence": "logistics", "sla": "logistics",
    "re-attempt": "logistics", "weight-dispute": "logistics",
    "liability": "logistics", "incident": "logistics",
    "rts-handoff": "logistics", "logistics-fwa": "logistics",
}


def category_dir_name(yaml_file):
    """Get the policy category directory name (e.g. 'cancellation', 'return')."""
    # Walk up to find the directory directly under policies/
    p = yaml_file.parent
    while p.parent.name != "policies" and p.parent != p:
        p = p.parent
    return p.name


def normalize_entry(doc, yaml_file):
    """Return a registry entry or None."""
    iri = doc.get("iri")
    if not iri:
        return None
    
    dt = doc.get("displayText", {})
    if not isinstance(dt, dict):
        dt = {}
    
    # Derive category directory name
    cat_dir = category_dir_name(yaml_file)
    
    # Derive sector: explicit in doc > sub-folder name > category-level default
    path_parts = yaml_file.parts
    try:
        v1_idx = path_parts.index("v1")
        sub = path_parts[v1_idx + 1] if v1_idx + 1 < len(path_parts) - 1 else None
        sector_from_path = sub if sub in ("trade", "logistics", "finance") else None
    except ValueError:
        sector_from_path = None
    
    sector = (doc.get("sector") or sector_from_path or 
              CATEGORY_SECTOR.get(cat_dir) or "cross-sector")
    
    # Category label: from doc or from the category directory name
    category = doc.get("category") or cat_dir.upper().replace("-", "_")
    
    return {
        "iri": iri,
        "category": category,
        "subCategory": doc.get("subCategory"),
        "version": doc.get("version", "1.0.0"),
        "status": doc.get("status", "ratified"),
        "versionEffectiveFrom": doc.get("versionEffectiveFrom"),
        "displayText": {
            "id": dt.get("id", ""),
            "en": dt.get("en", ""),
        },
        "applicableCategories": doc.get("applicableCategories", []),
        "applicableResourceTypes": doc.get("applicableResourceTypes", []),
        "regulatoryBasis": doc.get("regulatoryBasis", []),
        "supersededBy": doc.get("supersededBy"),
        "deprecatedAt": doc.get("deprecatedAt"),
        "sector": sector,
        "docPath": str(yaml_file.relative_to(POLICY_ROOT.parent)),
    }


def iter_docs(yaml_file):
    """Yield all YAML documents in a file."""
    try:
        for doc in yaml.safe_load_all(yaml_file.read_text(encoding="utf-8")):
            if doc is not None:
                yield doc
    except yaml.YAMLError as e:
        print(f"  YAML error in {yaml_file}: {str(e)[:120]}", file=sys.stderr)


def main():
    policies = []
    seen_iris = {}
    errors = []

    for category in CATEGORIES:
        version_dir = POLICY_ROOT / category / "v1"
        if not version_dir.exists():
            continue
        # Scan root of v1/ AND all sector sub-folders (trade/, logistics/, finance/)
        for yaml_file in sorted(version_dir.rglob("*.yaml")):
            if yaml_file.name == "_schema.yaml":
                continue
            for doc in iter_docs(yaml_file):
                entry = normalize_entry(doc, yaml_file)
                if entry is None:
                    errors.append(f"{yaml_file}: no 'iri' field — skipped")
                    continue
                iri = entry["iri"]
                if iri in seen_iris:
                    errors.append(f"DUPLICATE IRI: {iri} in {yaml_file} — first seen in {seen_iris[iri]}")
                    continue
                seen_iris[iri] = str(yaml_file)
                # Validate displayText.id present
                if not entry["displayText"].get("id"):
                    errors.append(f"{iri}: missing displayText.id (Bahasa Indonesia)")
                policies.append(entry)

    # Fatal on duplicates; warn on others
    fatal = [e for e in errors if e.startswith("DUPLICATE")]
    warnings = [e for e in errors if not e.startswith("DUPLICATE")]
    
    if warnings:
        print("Warnings:", file=sys.stderr)
        for w in warnings:
            print(f"  {w}", file=sys.stderr)
    
    if fatal:
        print("\nFATAL — duplicate IRIs found:", file=sys.stderr)
        for f in fatal:
            print(f"  {f}", file=sys.stderr)
        sys.exit(1)

    # Sort by IRI
    policies.sort(key=lambda p: p["iri"])

    by_category = {}
    by_sector = {}
    for p in policies:
        c = p.get("category", "UNKNOWN")
        s = p.get("sector") or "cross-sector"
        by_category[c] = by_category.get(c, 0) + 1
        by_sector[s] = by_sector.get(s, 0) + 1

    registry = {
        "_generated": "Do not edit directly. Run policies/generate_registry.py.",
        "_scheme": "ion://policy/{category}.{sector-or-scope}.{variant-name}",
        "_sectorFolders": {
            "trade":      "policies/{category}/v1/trade/",
            "logistics":  "policies/{category}/v1/logistics/",
            "finance":    "policies/{category}/v1/finance/",
            "cross-sector": "policies/{category}/v1/ (root)",
        },
        "version": "2.0.0",
        "totalPolicies": len(policies),
        "byCategory": by_category,
        "bySector": by_sector,
        "policies": policies,
    }

    OUTPUT.write_text(json.dumps(registry, indent=2, ensure_ascii=False))
    print(
        f"Generated registry.json: {len(policies)} policies "
        f"({by_sector})"
    )


if __name__ == "__main__":
    main()
