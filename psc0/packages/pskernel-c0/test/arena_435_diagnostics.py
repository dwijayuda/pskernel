#!/usr/bin/env python3
"""Strict non-admitting classification diagnostics of target Lean 4.35 Arena debt.

This never creates kernel approvals or converts adapter rejections into checked
judgments. It preserves original source bytes and uses the same explicit
header-only 4.35 adaptation as the full dual-check harness.
"""
import argparse
import json
import pathlib
import subprocess
import sys
from tempfile import TemporaryDirectory

from arena_conformance import check_archive
from arena_lean435_compat import adapt_legacy_envelope, official_reference, TARGET

def run_diag(exe: pathlib.Path, file: pathlib.Path, timeout: int) -> dict:
    try:
        p=subprocess.run(
            [str(exe), "--trace-declarations", str(file), "4096"],
            text=True, capture_output=True, encoding="utf-8", errors="replace",
            timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        return {"status":"host_timeout"}
    lines=(p.stdout+"\n"+p.stderr).splitlines()
    wanted=tuple("C0_REAL_EXPORT_"+k for k in (
       "PARSE_ERROR=", "INPUT_REASON=", "DECLINED_REASON=",
       "REJECT_MESSAGE=", "RESOURCE_REASON=", "INTERNAL_REASON=",
       "DECL_BEGIN", "replay_outcome="))
    markers=[l for l in lines if any(k in l for k in wanted)]
    return {
       "status":"observed", "exit_code":p.returncode,
       "markers":markers[-16:], "output_tail":lines[-6:]}

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive",required=True,type=pathlib.Path)
    parser.add_argument("--checker",required=True,type=pathlib.Path)
    parser.add_argument("--official-project",required=True,type=pathlib.Path)
    parser.add_argument("--ledger",required=True,type=pathlib.Path)
    parser.add_argument("--output",required=True,type=pathlib.Path)
    args=parser.parse_args()
    ledger=json.loads(args.ledger.read_text())
    expected={x["name"] for x in ledger["known_gaps"] if x["class"] in (
       "unqualified_negative_inductive_or_safety_metadata",
       "unqualified_negative_raw_declaration_format",
       "unqualified_official_duplicate_declaration_driver")}
    if len(expected)>25:
        raise ValueError(f"invalid remaining negative diagnostic scope: {len(expected)}")
    tests=check_archive(args.archive)
    if len(tests)!=193:
        raise ValueError("the immutable 193-case Arena negative audit source changed")
    # Zero remaining negative semantic debts is a successful, checkable
    # terminal inventory state, not a reason to fail diagnostics. The 16
    # separate resource/reference items are tracked in the full suite.
    seen=[]
    with TemporaryDirectory() as d:
        for kind,name,original in tests:
            if name not in expected:continue
            adapted,proof=adapt_legacy_envelope(original)
            path=pathlib.Path(d)/(str(len(seen))+".ndjson")
            path.write_bytes(adapted)
            official=official_reference(args.official_project,path,30)
            c0=run_diag(args.checker,path,30)
            row={"name":name,"original_label":kind,
                 "byte_exact":proof["body_bytes_identical"],
                 "original_hash":proof["original_sha256"],
                 "official":official,"c0":c0}
            seen.append(row)
            print("C0_ARENA_435_DEBT "+json.dumps(row,ensure_ascii=False),flush=True)
    if {x["name"] for x in seen}!=expected or not all(x["byte_exact"] for x in seen):
        raise ValueError("incomplete focused archived identity coverage")
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps({"lean":TARGET,"cases":seen},indent=2,ensure_ascii=False)+"\n")
    print(f"C0_ARENA_435_DEBT_RESULT exactly_{len(seen)}_remaining_cases_diagnosed=true "
          "admitted_anything=false",flush=True)
    return 0

if __name__=="__main__":
    sys.exit(main())
