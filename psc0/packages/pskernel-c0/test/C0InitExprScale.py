#!/usr/bin/env python3
"""Diagnostic-only unused expression-DAG pressure on a real Lean closure.

Keep every original declaration and handle unchanged. Append a bounded-depth,
source-syntax-only expression graph immediately before the final theorem.
The graph is never referenced from any declaration and confers no checking
privilege. These synthetic exports are NOT original full Init witnesses.
"""
import argparse
import hashlib
import json
from pathlib import Path

SOURCE_SHA = "2e57b983242e47f7dd1c95679ee0697b21aae688bfd38b6039d95c23b49100c1"
SOURCE_RECORDS = 114487


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--expressions", type=int, required=True)
    args = parser.parse_args()
    if not 0 <= args.expressions <= 4500000:
        raise ValueError("diagnostic expression count outside bounded range")
    blob = args.source.read_bytes()
    if hashlib.sha256(blob).hexdigest() != SOURCE_SHA:
        raise ValueError("unexpected source SHA-256")
    rows = blob.decode("utf-8").splitlines()
    if len(rows) != SOURCE_RECORDS:
        raise ValueError("expected exact real Cooper source record count")
    expr_idx = -1
    sort_zero = None
    for record in rows:
        if record.startswith('{"ie":'):
            obj = json.loads(record)
            if obj["ie"] != expr_idx + 1:
                raise ValueError("nonsequential expression index")
            expr_idx += 1
            if obj.get("sort") == 0:
                sort_zero = expr_idx
    if sort_zero is None or not rows[-1].startswith('{"thm":'):
        raise ValueError("missing Sort0 atom or final theorem")
    with args.destination.open("w", encoding="utf8", buffering=4 * 1024 * 1024, newline="\n") as f:
        for record in rows[:-1]:
            f.write(record + "\n")
        previous = sort_zero
        for index in range(args.expressions):
            expr_idx += 1
            # No unbounded syntactic spine; keep depth <=64 while retaining
            # millions of distinct source syntax nodes and persistent entries.
            parent = sort_zero if index % 64 == 0 else previous
            f.write('{"ie":%d,"app":{"fn":%d,"arg":%d}}\n' %
                    (expr_idx, parent, sort_zero))
            previous = expr_idx
        f.write(rows[-1] + "\n")
    print(json.dumps({"diagnostic_only": True,
                      "synthetic_unused_expressions": args.expressions,
                      "total_records": SOURCE_RECORDS + args.expressions,
                      "original_declarations_unchanged": True,
                      "original_source_sha256": SOURCE_SHA}, sort_keys=True))


if __name__ == "__main__":
    main()
