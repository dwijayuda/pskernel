#!/usr/bin/env python3
"""Diagnostic-only, SHA-locked Lean 4.35 source/kernel resource root triage.

This does not alter original Arena inputs or the C0 checker. On verified old
Arena 3.1.0 inputs, change ONLY first-line Lean provenance in a temporary copy;
the body bytes are byte-identical. Require an independent official 4.35 verdict
and run unchanged native C0 fuel 4096 on the same adapted bytes. Separately
record returned resource-exhaustion reason and actual active declaration.

The 90-second *diagnostic* host horizon is not the existing official 20-second
Arena benchmark; no timeout or higher host limit counts as a success verdict.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import subprocess
import sys
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parent))
from arena_conformance import check_archive
from arena_lean435_compat import adapt_legacy_envelope, official_reference

TARGETS = (
    "perf/beta-ladder.ndjson",
    "perf/church-numerals.ndjson",
    "perf/magma-list-deep-n36.ndjson",
)

def run(checker: Path, path: Path, name: str, horizon: int) -> None:
    cmd = [
        str(checker), "--require-accepted", "--trace-declarations",
        str(path), "4096",
    ]
    try:
        completed = subprocess.run(
            cmd, capture_output=True, text=True,
            errors="replace", check=False, timeout=horizon,
        )
    except subprocess.TimeoutExpired:
        print(f"C0_ARENA193_FUEL_ROOT name={name} result=UNQUALIFIED_HOST_TIMEOUT horizon={horizon} fuel=4096", flush=True)
        return
    output = completed.stdout + "\n" + completed.stderr
    summaries = [
        line for line in output.splitlines()
        if any(s in line for s in (
            "C0_REAL_EXPORT replay_outcome=",
            "resourceExhausted",
            "C0_REAL_EXPORT_ERROR",
            "C0_REAL_EXPORT_FAILURE",
            "kernel ",
        ))
    ]
    declarations = [
        line for line in output.splitlines()
        if line.startswith("C0_REAL_EXPORT_DECL_BEGIN ")
    ]
    print(f"C0_ARENA193_FUEL_ROOT name={name} process_exit={completed.returncode} "
          f"source_fuel=4096 native_verdicts={len(summaries)} "
          f"last_declaration={declarations[-1] if declarations else 'none'}",
          flush=True)
    for msg in summaries[-12:]:
        print("C0_ARENA193_FUEL_DETAIL " + msg[:450], flush=True)
    if completed.returncode == 0 and "C0ExportVerdict.accepted" in output:
        print(f"C0_ARENA193_FUEL_ROOT_CHECKED_ACCEPT name={name} actual_c0_accepted=true", flush=True)
    else:
        print(f"C0_ARENA193_FUEL_ROOT_UNQUALIFIED name={name} checked_acceptance=false", flush=True)

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--archive", type=Path, required=True)
    ap.add_argument("--checker", type=Path, required=True)
    ap.add_argument("--official-project", type=Path, required=True)
    args = ap.parse_args()
    checker = args.checker.resolve(strict=True)
    project = args.official_project.resolve(strict=True)
    original = {name: (label, raw)
                for label, name, raw in check_archive(args.archive)}
    with TemporaryDirectory(prefix="arena435-fuel-research-") as root:
        for name in TARGETS:
            label, source = original[name]
            if label != "good":
                raise ValueError("target is not an archival positive: " + name)
            adapted, evidence = adapt_legacy_envelope(source)
            assert evidence["body_bytes_identical"]
            test = Path(root) / name.split("/")[-1]
            test.write_bytes(adapted)
            # The large magma test may exceed 20s even in official Lean.
            # This 120s oracle is diagnostic-only; it is not a reclassified
            # benchmark result, and it must produce a genuine decision.
            official = official_reference(project, test, 120)
            print(f"C0_ARENA193_OFFICIAL_EXTENDED name={name} "
                  f"verdict={official['verdict']} "
                  f"original_body_sha256={evidence['original_body_sha256']} "
                  f"adapted_body_sha256={evidence['adapted_body_sha256']}",
                  flush=True)
            if official["verdict"] != "accepted":
                print(f"C0_ARENA193_ORACLE_UNQUALIFIED name={name}", flush=True)
                continue
            run(checker, test, name, horizon=90)
    print("C0_ARENA193_FUEL_DIAGNOSTIC completed=true no_admission_from_driver=true",
          flush=True)

if __name__ == "__main__":
    main()
