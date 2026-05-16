#!/usr/bin/env python3
"""
build_ion_full.py — Build a single merged OpenAPI 3.1.1 spec for ONIX validation.

Usage:
    python3 tools/build_ion_full.py
    python3 tools/build_ion_full.py --out schema/dist/ion-full.yaml

Output: schema/dist/ion-full.yaml (gitignored — generated artifact)

What it does:
    1. Takes beckn.yaml (30 Beckn core paths + all Beckn schemas)
    2. Merges ion.yaml (8 ION paths + 50 ION schemas + x-ion-* extensions)
    3. Resolves all 'beckn.yaml#/...' $refs to '#/...' (everything inline)
    4. Writes a single self-contained OpenAPI 3.1.1 file

Why this is needed:
    ONIX's Schemav2Validator loads a single OpenAPI spec file and validates
    all incoming Beckn messages against it. ion.yaml intentionally does NOT
    duplicate beckn.yaml's 30 core paths — it only defines the 8 additional
    ION endpoints. This build tool produces the merged file ONIX needs.

The source files (beckn.yaml + ion.yaml) remain the canonical reference.
Do not edit schema/dist/ion-full.yaml directly — regenerate instead.
"""
import argparse, copy, sys
import yaml
from pathlib import Path


def fix_refs(obj):
    if isinstance(obj, dict):
        return {
            k: ('#' + v[len('beckn.yaml#'):] if k == '$ref' and isinstance(v, str)
                and v.startswith('beckn.yaml#') else fix_refs(v))
            for k, v in obj.items()
        }
    if isinstance(obj, list):
        return [fix_refs(i) for i in obj]
    return obj


def build(beckn_path, ion_path, out_path):
    beckn = yaml.safe_load(beckn_path.read_text())
    ion   = yaml.safe_load(ion_path.read_text())

    merged = copy.deepcopy(beckn)
    merged['openapi']  = ion['openapi']
    merged['info']     = ion['info']
    merged['servers']  = ion['servers']
    merged['security'] = ion.get('security', [])

    merged.setdefault('paths', {})
    for path, item in ion.get('paths', {}).items():
        if path in merged['paths']:
            merged['paths'][path].update(item)
        else:
            merged['paths'][path] = item

    merged.setdefault('components', {}).setdefault('schemas', {}).update(
        ion.get('components', {}).get('schemas', {}))

    for key, val in ion.items():
        if key.startswith('x-ion'):
            merged[key] = val

    merged = fix_refs(merged)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        yaml.dump(merged, f, allow_unicode=True, default_flow_style=False,
                  sort_keys=False, width=120)

    doc = yaml.safe_load(out_path.read_text())
    p = len(doc.get('paths', {}))
    s = len(doc.get('components', {}).get('schemas', {}))
    kb = out_path.stat().st_size // 1024
    print(f"✅  {out_path}  |  {p} paths  |  {s} schemas  |  {kb} KB")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', default='schema/dist/ion-full.yaml')
    args = parser.parse_args()

    root     = Path(__file__).parent.parent
    api_dir  = root / 'schema' / 'core' / 'v2' / 'api' / 'v2.0.0'
    beckn    = api_dir / 'beckn.yaml'
    ion      = api_dir / 'ion.yaml'
    out      = root / args.out

    for p in (beckn, ion):
        if not p.exists():
            print(f"ERROR: {p} not found", file=sys.stderr)
            sys.exit(1)

    build(beckn, ion, out)


if __name__ == '__main__':
    main()
