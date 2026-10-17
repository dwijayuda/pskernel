#!/usr/bin/env python3
"""Prepare one immutable archived Lean Kernel Arena performance case under 4.35.

Only the first-line Lean identity metadata is adapted; all declaration body
bytes remain EXACTLY the original September 2026 source. The unchanged
official Lean 4.35 checker must independently accept the same adapted bytes.
This tool is diagnostic; it produces no C0 kernel admission receipt.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from arena_conformance import check_archive
from arena_lean435_compat import adapt_legacy_envelope, official_reference, TARGET

CASES = {
    "app-lam": "perf/app-lam.ndjson",
    "beta-ladder": "perf/beta-ladder.ndjson",
    "let-ladder": "perf/let-ladder.ndjson",
    "shared-subterm": "perf/shared-subterm.ndjson",
}

def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--archive",type=Path,required=True)
    p.add_argument("--case",choices=sorted(CASES),required=True)
    p.add_argument("--output",type=Path,required=True)
    p.add_argument("--info",type=Path,required=True)
    p.add_argument("--official-project",type=Path,required=True)
    a=p.parse_args()
    cases=check_archive(a.archive)
    assert len(cases)==193, "frozen archive identity changed"
    selected=[(label,raw) for label,name,raw in cases if name==CASES[a.case]]
    assert len(selected)==1 and selected[0][0]=="good", "case must be unique official-positive"
    adapted,proof=adapt_legacy_envelope(selected[0][1])
    assert proof["body_bytes_identical"]
    a.output.write_bytes(adapted)
    official=official_reference(a.official_project,a.output.resolve(),120)
    if official["verdict"]!="accepted":
        raise RuntimeError(f"official Lean 4.35 could not accept target case: {official}")
    decls=[]
    for i,line in enumerate(adapted.splitlines(),start=1):
        try:
            record=json.loads(line)
        except ValueError:
            raise RuntimeError(f"invalid archived line {i}")
        kind=next((x for x in ("thm","def","opaque","axiom","inductive","quot") if x in record),None)
        if kind:
            decls.append({"line":i,"kind":kind})
    assert decls, "no exported declarations"
    # The final exported declaration is the performance target; all earlier
    # dependencies are fully replayed using the genuine source checker.
    target=decls[-1]
    info={
        "case":a.case,"arena_name":CASES[a.case],
        "original_sha256":proof["original_sha256"],
        "adapted_sha256":proof["adapted_sha256"],
        "body_sha256":proof["original_body_sha256"],
        "body_exact":True,
        "target_lean":TARGET,
        "official_435":official,
        "records":len(adapted.splitlines()),
        "decl_count":len(decls),
        "target_decl":target,
        "wait_for":f"C0_REAL_EXPORT_DECL_BEGIN record={target['line']}",
        "semantic_scope":"diagnostic only; no target check claimed by sampler",
    }
    a.info.write_text(json.dumps(info,indent=2)+"\n")
    print("C0_ARENA_HOT_SOURCE "+json.dumps({k:v for k,v in info.items() if k!="official_435"}),flush=True)
    print(f"C0_ARENA_HOT_OFFICIAL case={a.case} verdict=accepted exact_pinned_lean_435=true",flush=True)

if __name__=="__main__":
    main()
