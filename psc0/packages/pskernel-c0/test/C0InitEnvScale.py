#!/usr/bin/env python3
"""Diagnostic-only checked-environment scaling test from a pinned Lean closure.

Inject fresh *safe definitions* with types/values Sort 1 := Sort 0 before the
original last theorem. Both official Lean and C0 MUST check the output.
The augmented export is synthetic; it is NOT an official real-Init witness.
"""
import argparse
import hashlib
import json
from pathlib import Path

COOPER_RECORDS = 114487
COOPER_SHA = "2e57b983242e47f7dd1c95679ee0697b21aae688bfd38b6039d95c23b49100c1"


def line(obj):
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False) + "\n"


def enlarge(source: Path, destination: Path, count: int):
    if not 0 <= count <= 40000:
        raise ValueError("unbounded diagnostic declaration count")
    raw = source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != COOPER_SHA:
        raise ValueError("pinned official dependency closure SHA-256 mismatch")
    records = raw.decode("utf-8").splitlines()
    if len(records) != COOPER_RECORDS:
        raise ValueError(f"source records mismatch: {len(records)}")
    latest_name = 0
    latest_level = 0
    latest_expr = -1
    names = {0: ""}
    has_sort0, has_sort1 = None, None
    first_succ0 = None
    for index, record in enumerate(records, 1):
        obj = json.loads(record)
        if "in" in obj:
            nameidx = obj["in"]
            if nameidx != latest_name + 1:
                raise ValueError(f"nonsequential name at physical record {index}")
            latest_name = nameidx
            spec = obj["str"] if "str" in obj else obj.get("num")
            if spec is None:
                raise ValueError("unknown name representation")
            parent = names[spec["pre"]]
            suffix = str(spec["str"]) if "str" in obj else str(spec["i"])
            names[nameidx] = parent + ("." if parent else "") + suffix
        if "il" in obj:
            levelidx = obj["il"]
            if levelidx != latest_level + 1:
                raise ValueError(f"nonsequential level at physical record {index}")
            latest_level = levelidx
            if obj.get("succ") == 0:
                first_succ0 = first_succ0 or levelidx
        if "ie" in obj:
            expridx = obj["ie"]
            if expridx != latest_expr + 1:
                raise ValueError(f"nonsequential expression at physical record {index}")
            latest_expr = expridx
            if obj.get("sort") == 0:
                has_sort0 = expridx
            elif first_succ0 is not None and obj.get("sort") == first_succ0:
                has_sort1 = expridx
    target = json.loads(records[-1])
    if list(target) != ["thm"] or names[target["thm"]["name"]] != "Int.Internal.Linear.cooper_dvd_right":
        raise ValueError("last declaration is not the pinned Cooper theorem")
    added = []
    if has_sort0 is None:
        latest_expr += 1
        has_sort0 = latest_expr
        added.append({"ie": has_sort0, "sort": 0})
    if first_succ0 is None:
        latest_level += 1
        first_succ0 = latest_level
        added.append({"il": first_succ0, "succ": 0})
    if has_sort1 is None:
        latest_expr += 1
        has_sort1 = latest_expr
        added.append({"ie": has_sort1, "sort": first_succ0})
    with destination.open("w", encoding="utf8", newline="\n") as out:
        for record in records[:-1]:
            out.write(record + "\n")
        for obj in added:
            out.write(line(obj))
        first_name = latest_name + 1
        for i in range(count):
            out.write(line({
                "in": first_name + i,
                "str": {"pre": 0, "str": f"C0DiagnosticSizedEnvironment_{i:05d}"}
            }))
        for i in range(count):
            handle = first_name + i
            out.write(line({"def": {
                "name": handle, "levelParams": [], "type": has_sort1,
                "value": has_sort0, "hints": "abbrev",
                "safety": "safe", "all": [handle]
            }}))
        out.write(records[-1] + "\n")
    return {
        "diagnostic_only": True,
        "synthetic_safe_definitions": count,
        "records": COOPER_RECORDS + len(added) + 2 * count,
        "target": "Int.Internal.Linear.cooper_dvd_right",
        "source_sha256": COOPER_SHA,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--definitions", type=int, required=True)
    args = parser.parse_args()
    print(json.dumps(enlarge(args.source, args.output, args.definitions), sort_keys=True))


if __name__ == "__main__":
    main()
