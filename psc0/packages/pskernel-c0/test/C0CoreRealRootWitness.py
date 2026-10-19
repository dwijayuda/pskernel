#!/usr/bin/env python3
"""Require a source-typed PSC0 compiler dependency witness before a kernel replay.

This is evidence provenance, not a kernel admission decision.
"""
import json
import pathlib
import sys

def main(argv):
    if len(argv) != 4:
        raise ValueError("usage: witness.json ROOT SOURCE SOURCE_MODULE")
    file, root, source, module = argv
    doc = json.loads(pathlib.Path(file).read_text(encoding="utf-8"))
    if not isinstance(doc.get("assumptions"), list):
        raise ValueError("missing native assumption-path witness inventory")
    matched = [
        sample.get("sourceWitness", {})
        for a in doc["assumptions"]
        for sample in a.get("samples", [])
        if sample.get("sourceWitness", {}).get("root", {}).get("display") == root
        and sample.get("sourceWitness", {}).get("source", {}).get("display") == source
        and sample.get("sourceWitness", {}).get("sourceModule", {}).get("display") == module
    ]
    if not matched:
        raise ValueError(f"not a measured compiler dependency: {module}.{source} -> {root}")
    if not module.startswith("Ps.") or not root or not source:
        raise ValueError("invalid source ownership")
    if any(item.get("edge") not in ("type", "value", "family-or-rule") for item in matched):
        raise ValueError("unknown native compiler reference edge")
    print(json.dumps({"schema": "c0-real-native-root-witness/1", "root": root,
                      "compilerModule": module, "compilerDeclaration": source,
                      "witnessCount": len(matched), "pinnedMeasured": True,
                      "c0Accepted": False}, sort_keys=True))

if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (ValueError, KeyError, TypeError, OSError) as ex:
        print(f"C0_CORE_WITNESS_REFUSAL: {ex}", file=sys.stderr)
        sys.exit(1)
