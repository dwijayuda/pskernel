#!/usr/bin/env python3
"""Deterministic actual-Core dependency frontier for kernel performance diagnosis.

All 418 selected roots remain in the complete-Core qualification corpus.
These shards are DIFFERENTIAL DIAGNOSTICS, not evidence of complete Core
checking or proof admission. Partition by source-graph transitive reachability
rather than inventing handpicked fast/easy Core test declarations.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

from C0CoreSelectedRoots import canonical, require, verify


def frontier(graph, comparison, digest, shard_count=4):
    receipt = verify(graph, comparison, digest)
    entries = graph["closureDeclarations"]
    adjacency = {
        canonical(row["name"]): {canonical(dep) for dep in row["dependencies"]}
        for row in entries
    }
    root_items = graph["externalRoots"]
    depths = {}
    for item in root_items:
        root = canonical(item)
        pending = [root]
        seen = set()
        while pending:
            name = pending.pop()
            if name in seen:
                continue
            require(name in adjacency, "open dependency in selected frontier")
            seen.add(name)
            pending.extend(adjacency[name] - seen)
        depths[root] = seen
    require(len(depths) == len(root_items) == 418, "missing roots in frontier")
    require(set.union(*depths.values()) == set(adjacency),
            "selected roots do not cover complete selected external closure")

    # Largest full dependency closures first. Stable original order resolves
    # equal costs, so the diagnostic plan is reproducible at the pinned graph.
    ordering = sorted(enumerate(root_items),
                      key=lambda pair: (-len(depths[canonical(pair[1])]), pair[0]))
    shards = [{"roots": [], "closure": set()} for _ in range(shard_count)]
    for original_index, item in ordering:
        closure = depths[canonical(item)]
        shard = min(range(shard_count),
                    key=lambda i: (len(shards[i]["closure"] | closure),
                                   len(shards[i]["roots"]), i))
        shards[shard]["roots"].append((original_index, item["display"]))
        shards[shard]["closure"].update(closure)
    output = []
    all_names = []
    for number, shard in enumerate(shards):
        roots = [label for _, label in sorted(shard["roots"])]
        all_names.extend(roots)
        output.append({
            "shard": number,
            "rootCount": len(roots),
            "externalClosureDeclarations": len(shard["closure"]),
            "roots": roots,
            "fullCoreAccepted": False,
        })
    require(len(all_names) == len(set(all_names)) == 418, "diagnostic roots duplicated")
    require(set(all_names) == set(receipt["externalRoots"]),
            "diagnostic sharding omitted original Core roots")
    require(len(set.union(*(s["closure"] for s in shards))) == 5619,
            "sharding lost external dependency family")
    return {
        "schema": "pskernel-c0-selected-core-frontier/1",
        "selectedGraphSHA256": digest,
        "sourceAuditCommit": receipt["compilerAuditCommit"],
        "fullSelectedRootCount": 418,
        "fullSelectedExternalClosure": 5619,
        "shardCount": shard_count,
        "shards": output,
        "fullCoreQualified": False,
        "disclaimer": "Diagnostic subsets overlap in dependencies. Only exact all-root same-byte replay and subsequent compiler-owned declaration checks can qualify Core.",
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--selected", required=True, type=Path)
    p.add_argument("--comparison", required=True, type=Path)
    p.add_argument("--out-dir", required=True, type=Path)
    a = p.parse_args()
    raw = a.selected.read_bytes()
    graph = json.loads(raw)
    comparison = json.loads(a.comparison.read_bytes())
    report = frontier(graph, comparison, hashlib.sha256(raw).hexdigest())
    a.out_dir.mkdir(parents=True, exist_ok=True)
    for shard in report["shards"]:
        (a.out_dir / f"roots-{shard['shard']}.txt").write_text(
            "\n".join(shard["roots"]) + "\n", encoding="utf-8")
    (a.out_dir / "selected-frontier.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    summary = [(v["shard"], v["rootCount"], v["externalClosureDeclarations"])
               for v in report["shards"]]
    print(f"C0_SELECTED_CORE_DIAGNOSTIC_FRONTIER={summary} "
          "four_shards_no_omission=true NOT_ACCEPTANCE")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"C0_SELECTED_CORE_FRONTIER_REFUSED: {exc}", file=sys.stderr)
        raise SystemExit(1)
