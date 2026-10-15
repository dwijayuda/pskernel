#!/usr/bin/env python3
"""Diagnostic only: compute source expression DAG sharing without expansion.

The pinned lean4export stream assigns every expr node an ascending ID.
Compute saturated expanded-tree sizes and unique DAG reachability for the
last checked declaration's proof, without executing or admitting any proof.
"""
import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

CAP = 10**18
PINNED = {
    "WellFounded.partialExtrinsicFix₃": ("", None),
    "WellFounded.partialExtrinsicFix₃_eq_partialExtrinsicFix": (
        "1d97cdd876069322a27ab69b2a1607e615695c8c0be065bbbb0db476833b5abe",
        15758,
    ),
    "BitVec.msb_add": (
        "822e6b0d0904081cd3d8e0fee264dd8c95472496d63b79ed370dd7e32e3bf9db",
        121532,
    ),
}


def decode_expr(obj):
    for key in ("app", "lam", "forallE", "letE", "mdata", "proj"):
        if key in obj:
            p = obj[key]
            if key == "app":
                return key, [p["fn"], p["arg"]]
            if key in ("lam", "forallE"):
                return key, [p["type"], p["body"]]
            if key == "letE":
                return key, [p["type"], p["value"], p["body"]]
            if key == "mdata":
                return key, [p["expr"]]
            return key, [p["struct"]]
    return next((x for x in ("sort", "bvar", "fvar", "mvar", "const", "natVal", "strVal") if x in obj), "unknown"), []


def analyze(path: Path, target: str):
    blob = path.read_bytes()
    digest = hashlib.sha256(blob).hexdigest()
    known_digest, expected_records = PINNED[target]
    if known_digest and digest != known_digest:
        raise ValueError("pinned exporter digest mismatch")
    lines = blob.decode("utf-8").splitlines()
    if expected_records is not None and len(lines) != expected_records:
        raise ValueError("pinned record count mismatch")
    nodes = []
    counts, depths = [], []
    names = {0: ""}
    final = None
    for raw in lines:
        obj = json.loads(raw)
        if "in" in obj:
            idx = obj["in"]
            if idx != len(names):
                raise ValueError("nonsequential name handle")
            if "str" in obj:
                p = obj["str"]
                parent, part = names[p["pre"]], p["str"]
            elif "num" in obj:
                p = obj["num"]
                parent, part = names[p["pre"]], str(p["i"])
            else:
                raise ValueError("unexpected name tag")
            names[idx] = parent + ("." if parent else "") + part
        if "ie" in obj:
            idx = obj["ie"]
            if idx != len(nodes):
                raise ValueError("nonsequential expression handles")
            kind, children = decode_expr(obj)
            if kind == "unknown":
                raise ValueError("unknown expression constructor")
            if any(not 0 <= c < idx for c in children):
                raise ValueError("unresolved expression child")
            nodes.append((kind, children))
            counts.append(min(CAP, 1 + sum(counts[c] for c in children)))
            depths.append(1 + max((depths[c] for c in children), default=0))
        for k in ("thm", "def", "opaque"):
            if k in obj:
                p = obj[k]
                final = (k, names[p["name"]], p["type"], p["value"])
    if final is None or final[1] != target:
        raise ValueError(f"final declaration mismatch: {final}")
    def stats(root):
        visited = set()
        todo = [root]
        parents = Counter()
        while todo:
            cur = todo.pop()
            if cur in visited:
                continue
            visited.add(cur)
            for child in nodes[cur][1]:
                parents[child] += 1
                todo.append(child)
        kinds = Counter(nodes[i][0] for i in visited)
        return {
            "root_kind": nodes[root][0],
            "unique_nodes": len(visited),
            "expanded_size_capped": counts[root],
            "saturated_at_1e18": counts[root] >= CAP,
            "expanded_to_unique_lower_bound": counts[root] // max(1, len(visited)),
            "max_depth": depths[root],
            "shared_nodes": sum(1 for k, c in parents.items() if c > 1),
            "largest_direct_in_degree": max(parents.values(), default=0),
            "constructors": dict(kinds.most_common(12)),
        }
    return {
        "diagnostic_only": True,
        "source": str(path.name),
        "source_sha256": digest,
        "physical_records": len(lines),
        "decl_kind": final[0],
        "target": final[1],
        "all_export_expression_nodes": len(nodes),
        "type": stats(final[2]),
        "value": stats(final[3]),
        "no_kernel_admission_performed": True,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path", type=Path)
    ap.add_argument("target", choices=PINNED)
    args = ap.parse_args()
    print(json.dumps(analyze(args.path, args.target), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
