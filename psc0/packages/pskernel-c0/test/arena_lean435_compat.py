#!/usr/bin/env python3
"""Differentially check archived Lean Kernel Arena declaration *bodies* under Lean 4.35.

This is an EXPLICIT legacy-envelope compatibility experiment, NOT a native
Lean-4.35 re-export and NOT verification of the original archived bytes.

The immutable September 2026 archive is verified first. The importer/exporter
wire format must already be 3.1.0. Only the first-line metadata Lean version and
githash are changed in a separate temp file; the entire declaration-body byte
suffix is proved identical by SHA-256 and direct equality. Both independently
running official Lean 4.35 and C0 check exactly that temp file.

The official 4.35 verdict, not the old Arena label, is authoritative for this
explicitly adapted test. Original labels and original bytes remain recorded.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from tempfile import TemporaryDirectory

from arena_conformance import ARCHIVE_SHA256, check_archive, decode_source_pin, run_one

TARGET = {"version": "4.35.0", "githash": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"}
FORMAT = "3.1.0"
EXPECTED_ARCHIVE_SIZE = 193
ERROR_LIMIT = 900


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def adapt_legacy_envelope(original: bytes) -> tuple[bytes, dict]:
    """Exact-body transition with explicit immutable original provenance."""
    prefix, sep, body = original.partition(b"\n")
    if sep != b"\n" or not body:
        raise ValueError("no complete NDJSON header and declaration body")
    source = json.loads(prefix.decode("utf-8"))
    if not isinstance(source, dict) or set(source) != {"meta"}:
        raise ValueError("metadata record is not a standalone meta object")
    meta = source["meta"]
    if not isinstance(meta, dict) or not isinstance(meta.get("lean"), dict):
        raise ValueError("missing Lean source provenance")
    if meta.get("format", {}).get("version") != FORMAT:
        raise ValueError("source export format is incompatible with 3.1.0")
    exporter = meta.get("exporter")
    if not isinstance(exporter, dict) or not isinstance(exporter.get("name"), str) or not isinstance(exporter.get("version"), str):
        raise ValueError("unrecognized original exporter identity")
    # The export format, not the producer's own version number, defines the
    # wire schema. Arena includes deliberate hand-crafted 3.1.0 exports.
    original_lean = dict(meta["lean"])
    if sorted(original_lean) != ["githash", "version"]:
        raise ValueError("unexpected Lean metadata fields")
    if not isinstance(original_lean["githash"], str) or not isinstance(original_lean["version"], str):
        raise ValueError("invalid original Lean version metadata")
    if any(not isinstance(x, str) for x in [original_lean["githash"], original_lean["version"]]):
        raise ValueError("invalid Lean identity")
    # A source whose Lean pin is already current still receives a separate
    # transparent adapter receipt; never overwrite the archived bytes.
    meta["lean"] = dict(TARGET)
    header = json.dumps(source, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    adapted = header + b"\n" + body
    if adapted.partition(b"\n")[2] != original.partition(b"\n")[2]:
        raise AssertionError("declaration bytes changed")
    return adapted, {
        "type": "header_only_provenance_adaptation_NOT_native_435_export",
        "original_lean": original_lean,
        "target_lean": TARGET,
        "original_sha256": sha256(original),
        "adapted_sha256": sha256(adapted),
        "original_body_sha256": sha256(body),
        "adapted_body_sha256": sha256(adapted.partition(b"\n")[2]),
        "body_bytes_identical": True,
    }


def parse_official_reference_result(output: str, returncode: int) -> dict:
    """Distinguish a real native kernel duplicate from arbitrary driver crashes.

    Lean 4.35 environment::check_name raises already_declared_exception.
    leanchecker prints exactly one 'uncaught exception: Duplicate declaration'
    line (without its usual rejection marker). Never use a generic exception
    as evidence of a kernel rejection.
    """
    ok = "Lean default kernel accepts the solution" in output
    bad = "Lean default kernel rejects the solution" in output
    if ok != bad and ((ok and returncode == 0) or (bad and returncode != 0)):
        return {"verdict": "accepted" if ok else "rejected",
                "returncode": returncode, "reason": "official_leanchecker_verdict"}
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    if (returncode != 0 and not ok and not bad and len(lines) == 1 and
        re.fullmatch(r"uncaught exception: Duplicate declaration: \S+", lines[0])):
        return {"verdict": "rejected", "returncode": returncode,
                "reason": "official_kernel_duplicate_declaration"}
    return {"verdict": "driver_error", "returncode": returncode,
            "detail": output[-ERROR_LIMIT:]}


def official_reference(project: pathlib.Path, path: pathlib.Path, timeout: int) -> dict:
    try:
        done = subprocess.run(
            ["lake", "env", "leanchecker", "--from-export", str(path)],
            cwd=project, text=True, capture_output=True,
            encoding="utf-8", errors="replace", timeout=timeout, check=False,
        )
    except subprocess.TimeoutExpired:
        return {"verdict": "timeout"}
    except OSError as e:
        return {"verdict": "driver_error", "error": str(e)[:ERROR_LIMIT]}
    return parse_official_reference_result(done.stdout + "\n" + done.stderr, done.returncode)

def classify(official: dict, c0: dict) -> str:
    ov = official["verdict"]
    if ov not in ("accepted", "rejected"):
        return "official_" + ov
    if c0["result"] != "verdict":
        return "c0_" + c0["result"]
    cv = c0["verdict"]
    if cv in ("accepted", "rejected"):
        if ov == cv:
            return "correct"
        return "false_accept" if cv == "accepted" else "false_reject"
    return "c0_" + cv


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--archive", type=pathlib.Path, required=True)
    ap.add_argument("--checker", type=pathlib.Path, required=True)
    ap.add_argument("--official-project", type=pathlib.Path, required=True)
    ap.add_argument("--out", type=pathlib.Path, required=True)
    ap.add_argument("--fuel", type=int, default=4096)
    ap.add_argument("--timeout", type=int, default=20)
    ap.add_argument("--per-label", type=int, default=0,
                    help="diagnostic pilot: N bad + N good; 0 processes all 193")
    ap.add_argument("--known-gaps", type=pathlib.Path,
                    help="allow only exact reviewed unqualified cases, never wrong kernel verdicts")
    ap.add_argument("--shard-index", type=int, default=0)
    ap.add_argument("--shard-count", type=int, default=1)
    ap.add_argument("--require-complete", action="store_true",
                    help="fail if any C0 outcome is unqualified, not just false accepts")
    args = ap.parse_args()
    if args.fuel < 1 or args.timeout < 1 or args.per_label < 0:
        ap.error("fuel, timeout and per-label bounds must be valid")
    if args.shard_count < 1 or not 0 <= args.shard_index < args.shard_count:
        ap.error("invalid deterministic shard index/count")
    if args.per_label and args.shard_count != 1:
        ap.error("per-label pilot cannot be combined with full sharding")
    checker = args.checker.resolve(strict=True)
    project = args.official_project.resolve(strict=True)
    all_cases = check_archive(args.archive)
    if len(all_cases) != EXPECTED_ARCHIVE_SIZE:
        raise ValueError(f"expected {EXPECTED_ARCHIVE_SIZE} immutable Arena cases, got {len(all_cases)}")
    if args.per_label:
        cases = ([x for x in all_cases if x[0] == "bad"][:args.per_label] +
                 [x for x in all_cases if x[0] == "good"][:args.per_label])
    else:
        cases = [case for index, case in enumerate(all_cases)
                 if index % args.shard_count == args.shard_index]
    if not cases:
        raise ValueError("no Arena cases selected")

    known_by_name = {}
    required_correct = set()
    if args.known_gaps:
        ledger = json.loads(args.known_gaps.read_text())
        if (ledger.get("archive_sha256") != ARCHIVE_SHA256 or
            ledger.get("lean_target") != TARGET["version"] or
            ledger.get("pinned_lean_git") != TARGET["githash"]):
            raise ValueError("known-gap ledger does not match the pinned source")
        required_correct = set(ledger["required_correct_cases"])
        for row in ledger["known_gaps"]:
            if row["name"] in known_by_name or "correct" not in row["allowed"]:
                raise ValueError("invalid or duplicated known-gap entry")
            known_by_name[row["name"]] = set(row["allowed"])
        if len(known_by_name) != 21:
            raise ValueError("unexpected known-gap ledger size")

    results = []
    with TemporaryDirectory(prefix="c0-arena-435-compat-") as tmp:
        work = pathlib.Path(tmp)
        for i, (label, name, raw) in enumerate(cases):
            expected = "accepted" if label == "good" else "rejected"
            record = {"name": name, "original_expected": expected,
                      "source_pin": decode_source_pin(raw)}
            try:
                adapted, provenance = adapt_legacy_envelope(raw)
                record["adaptation"] = provenance
                path = work / f"compatible-{i}.ndjson"
                path.write_bytes(adapted)
                official = official_reference(project, path, args.timeout)
                observed = run_one(checker, path, timeout=args.timeout, fuel=args.fuel)
                record["official"] = official
                record["c0"] = observed
                record["classification"] = classify(official, observed)
                record["legacy_expected_matches_official"] = (
                    official["verdict"] == expected)
            except (UnicodeError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
                record["classification"] = "adaptation_error"
                record["error"] = f"{type(exc).__name__}: {exc}"
                print(f"C0_ARENA_435_COMPAT_ADAPTATION_ERROR name={name} error={record['error']}", flush=True)
            results.append(record)
            print(f"C0_ARENA_435_COMPAT case={i+1}/{len(cases)} "
                  f"name={name} original={expected} "
                  f"official={record.get('official', {}).get('verdict', 'none')} "
                  f"c0={record.get('c0', {}).get('verdict', 'none')} "
                  f"class={record['classification']}", flush=True)

    counts = Counter(x["classification"] for x in results)
    correct_accept = sum(x["classification"] == "correct"
                         and x["official"]["verdict"] == "accepted" for x in results)
    correct_reject = sum(x["classification"] == "correct"
                         and x["official"]["verdict"] == "rejected" for x in results)
    changed = sum(x.get("legacy_expected_matches_official") is False for x in results)
    report = {
        "suite": "Arena 2026-09, explicitly adapted 3.1.0 header for independent Lean 4.35 testing",
        "is_genuine_native_435_reexport": False,
        "does_not_establish_historical_same_byte_compatibility": True,
        "declaration_body_bytes_are_never_rewritten": True,
        "archive_cases": len(all_cases),
        "selected_cases": len(cases),
        "full_suite": not args.per_label and args.shard_count == 1,
        "shard_index": args.shard_index,
        "shard_count": args.shard_count,
        "bounded_known_gap_ledger": bool(args.known_gaps),
        "counts": dict(sorted(counts.items())),
        "official_verified_accepts": correct_accept,
        "official_verified_rejects": correct_reject,
        "historical_expected_label_drift": changed,
        "tests": results,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"C0_ARENA_435_COMPAT_SUMMARY selected={len(cases)} official_accept={correct_accept} "
          f"official_reject={correct_reject} expected_drift={changed} "
          f"counts={dict(sorted(counts.items()))}", flush=True)
    # Explicit known limitations are not passing results. Reject any newly
    # unqualified case, false acceptance or false rejection.
    violations = []
    for item in results:
        cl = item["classification"]
        name = item["name"]
        if name in required_correct and cl != "correct":
            violations.append(f"mandatory positive must check: {name}: {cl}")
        elif cl in ("false_accept", "false_reject", "adaptation_error", "c0_error"):
            violations.append(f"unconditional invalidity: {name}: {cl}")
        elif cl != "correct":
            if args.known_gaps:
                if cl not in known_by_name.get(name, set()):
                    violations.append(f"new/unlisted unqualified case: {name}: {cl}")
            elif cl.startswith("official_"):
                violations.append(f"official reference failure: {name}: {cl}")
    if args.require_complete and counts.get("correct", 0) != len(cases):
        violations.append("complete C0 support is not qualified")
    if not counts.get("correct", 0):
        violations.append("zero independently matched cases")
    for issue in violations:
        print("C0_ARENA_435_COMPAT_VIOLATION " + issue, file=sys.stderr)
    print(f"C0_ARENA_435_COMPAT_GATE bounded_valid={not violations} "
          f"matched={counts.get('correct',0)}/{len(cases)} "
          f"unqualified={len(cases)-counts.get('correct',0)} "
          f"complete={counts.get('correct',0)==len(cases)}", flush=True)
    return 1 if violations else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as exc:
        print(f"C0_ARENA_435_COMPAT_GATE driver_error={exc}", file=sys.stderr)
        sys.exit(1)
