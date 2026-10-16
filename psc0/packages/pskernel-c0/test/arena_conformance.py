#!/usr/bin/env python3
"""External Lean Kernel Arena corpus differential gate for the NATIVE Lean C0.

The arena tarball's exact published bytes are mandatory: no header rewriting,
version spoofing, silent skips, foreign acceptance, or Rust experiment.

Official 2026-09 inputs may have a Lean pin other than C0's 4.35.0. C0 must
DECLINE these (not pretend they were checked), and the report distinguishes
this outcome from an actual soundness/completeness pass.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import pathlib
import re
import subprocess
import sys
import tarfile
from collections import Counter
from tempfile import TemporaryDirectory

ARCHIVE_SHA256 = "98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"
ARENA_ROUND = "2026-09"
VERDICT = re.compile(r"^C0_REAL_EXPORT replay_outcome=C0ExportVerdict\.([A-Za-z]+) consumed_records=(\d+) fuel=(\d+)$", re.M)
OUTCOMES = {"accepted", "rejected", "unsupported", "malformed", "resourceExhausted", "inconclusive"}
# Controls are NOT Arena results. They are separately pinned Lean 4.35
# examples to prove that the runner can observe real positives and negatives.
CONTROLS = {
    "C0OfficialAccept.ndjson": "accept",
    "C0OfficialReject.ndjson": "reject",
    "C0OfficialTheoremAccept.ndjson": "accept",
    "C0OfficialTheoremReject.ndjson": "reject",
    "C0OfficialInitSubtypeAccept.ndjson": "accept",
    "C0OfficialInitSubtypeReject.ndjson": "reject",
    "C0OfficialInitThreeInductivesAccept.ndjson": "accept",
}
MAX_CASE_BYTES = 10 * 1024 * 1024
MAX_ARCHIVE_BYTES = 60 * 1024 * 1024
MAX_CASES = 500


def arena_member(name: str) -> tuple[str, str] | None:
    """Require a path under good/ or bad/ and preserve its complete identity."""
    parts = pathlib.PurePosixPath(name).parts
    if any(part in ("", ".", "..") for part in parts) or name.startswith("/"):
        raise ValueError(f"unsafe archive member name: {name!r}")
    if name.endswith(".ndjson") and (parts.count("good") + parts.count("bad")) == 1:
        index = next(i for i, p in enumerate(parts) if p in ("good", "bad"))
        if index + 1 >= len(parts):
            raise ValueError(f"malformed labeled path: {name}")
        return (parts[index], "/".join(parts[index + 1:]))
    return None


def decode_source_pin(payload: bytes) -> dict:
    """Observe declared provenance only; never rewrite it."""
    first = payload.split(b"\n", 1)[0]
    try:
        meta = json.loads(first.decode("utf-8"))["meta"]
        return {"lean": meta["lean"]["version"],
                "githash": meta["lean"]["githash"],
                "exporter": meta["exporter"]["version"],
                "format": meta["format"]["version"]}
    except (UnicodeError, json.JSONDecodeError, KeyError, TypeError) as exc:
        return {"metadata_error": type(exc).__name__}


def run_one(executable: pathlib.Path, path: pathlib.Path, *, timeout: int, fuel: int) -> dict:
    try:
        completed = subprocess.run([str(executable), str(path), str(fuel)],
                                   text=True, capture_output=True, timeout=timeout,
                                   check=False, encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return {"result": "timeout", "exit_code": None, "verdict": None}
    except OSError as exc:
        return {"result": "error", "exit_code": None, "verdict": None,
                "reason": f"{type(exc).__name__}: {exc}"}
    all_hits = VERDICT.findall(completed.stdout)
    if completed.returncode != 0 or len(all_hits) != 1 or all_hits[0][0] not in OUTCOMES:
        return {"result": "error", "exit_code": completed.returncode, "verdict": None,
                "reason": "missing/multiple verdicts or unexpected CLI exit",
                "stderr_tail": completed.stderr[-300:]}
    observed, records, reported_fuel = all_hits[0]
    if int(reported_fuel) != fuel:
        return {"result": "error", "exit_code": completed.returncode,
                "verdict": None, "reason": "checker silently changed input fuel"}
    return {"result": "verdict", "exit_code": completed.returncode,
            "verdict": observed, "consumed_records": int(records)}


def classify(expected: str, observed: dict) -> str:
    if observed["result"] == "timeout":
        return "timeout"
    if observed["result"] == "error":
        return "error"
    value = observed["verdict"]
    if value == "accepted":
        return "correct" if expected == "accept" else "false_accept"
    if value == "rejected":
        return "correct" if expected == "reject" else "false_reject"
    return "declined"


def check_archive(archive: pathlib.Path) -> list[tuple[str, str, bytes]]:
    got = hashlib.sha256(archive.read_bytes()).hexdigest()
    if got != ARCHIVE_SHA256:
        raise ValueError(f"arena archive SHA256 mismatch: {got}")
    cases: list[tuple[str, str, bytes]] = []
    seen: set[tuple[str, str]] = set()
    total_bytes = 0
    with tarfile.open(archive, "r:gz") as tar:
        for member in tar:
            # Explicitly forbid files with unsafe filesystem semantics. We
            # never extract the archive's paths onto the host filesystem.
            if not (member.isfile() or member.isdir()):
                raise ValueError(f"unsupported archive member type: {member.name}")
            if not member.isfile():
                continue
            label = arena_member(member.name)
            if label is None:
                continue
            if label in seen:
                raise ValueError(f"duplicate arena test: {label}")
            seen.add(label)
            if member.size > MAX_CASE_BYTES:
                raise ValueError(f"unexpected overlarge small-suite case: {member.name}")
            stream = tar.extractfile(member)
            if stream is None:
                raise ValueError(f"missing file contents: {member.name}")
            payload = stream.read(MAX_CASE_BYTES + 1)
            if len(payload) != member.size:
                raise ValueError(f"truncated test file: {member.name}")
            total_bytes += len(payload)
            if total_bytes > MAX_ARCHIVE_BYTES or len(seen) > MAX_CASES:
                raise ValueError("unexpected external arena corpus size")
            cases.append((label[0], label[1], payload))
    if not cases or not any(c[0] == "good" for c in cases) or not any(c[0] == "bad" for c in cases):
        raise ValueError("labeled Arena accept/reject test files missing")
    return sorted(cases)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--checker", type=pathlib.Path, required=True)
    parser.add_argument("--controls", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--fuel", type=int, default=4096)
    args = parser.parse_args()
    if args.timeout < 1 or args.fuel < 1:
        parser.error("timeout and fuel must be positive")
    checker = args.checker.resolve(strict=True)
    cases = check_archive(args.archive)
    print(f"C0_ARENA archive=2026-09 sha256=verified cases={len(cases)}", flush=True)

    reports: list[dict] = []
    controls: list[dict] = []
    with TemporaryDirectory(prefix="c0-arena-native-") as tmp:
        work = pathlib.Path(tmp)
        for name, expected in CONTROLS.items():
            path = args.controls / name
            observation = run_one(checker, path.resolve(strict=True),
                                  timeout=args.timeout, fuel=args.fuel)
            verdict = classify(expected, observation)
            item = {"name": name, "expected": expected, "classification": verdict, **observation}
            controls.append(item)
            print(f"C0_ARENA_CONTROL name={name} expected={expected} classification={verdict}", flush=True)
        for i, (label, name, source) in enumerate(cases):
            path = work / f"case-{i}.ndjson"
            path.write_bytes(source)
            expected = "accept" if label == "good" else "reject"
            observation = run_one(checker, path, timeout=args.timeout, fuel=args.fuel)
            verdict = classify(expected, observation)
            item = {"name": name, "expected": expected, "classification": verdict,
                    "source_pin": decode_source_pin(source), **observation}
            reports.append(item)
            print(f"C0_ARENA_CASE name={name} expected={expected} classification={verdict} "
                  f"native_verdict={observation.get('verdict')}", flush=True)

    counts = Counter(x["classification"] for x in reports)
    native_counts = Counter(x["classification"] for x in controls)
    summary = {
        "suite": "Lean Kernel Arena",
        "round": ARENA_ROUND,
        "archive_sha256": ARCHIVE_SHA256,
        "checker": "PSKernel-C0 native Lean 4.35.0, original admitting NDJSON replay",
        "fuel": args.fuel,
        "total": len(reports),
        "expected_accept": sum(x["expected"] == "accept" for x in reports),
        "expected_reject": sum(x["expected"] == "reject" for x in reports),
        "counts": dict(sorted(counts.items())),
        "native_controls": dict(sorted(native_counts.items())),
        "verified_arena_accepts": sum(x["expected"] == "accept" and x["classification"] == "correct" for x in reports),
        "verified_arena_rejects": sum(x["expected"] == "reject" and x["classification"] == "correct" for x in reports),
        "historical_version_declines_are_not_passes": True,
        "production_parser_not_relaxed": True,
        "tests": reports,
        "controls": controls,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"C0_ARENA_SUMMARY total={len(reports)} correct={counts['correct']} "
          f"false_accept={counts['false_accept']} false_reject={counts['false_reject']} "
          f"declined={counts['declined']} timeout={counts['timeout']} error={counts['error']} "
          f"native_controls_correct={native_counts['correct']}/{len(controls)}", flush=True)
    if native_counts["correct"] != len(controls):
        print("C0_ARENA_GATE native 4.35 controls failed", file=sys.stderr)
        return 1
    if counts["false_accept"] or counts["false_reject"] or counts["error"]:
        print("C0_ARENA_GATE invalid C0 verdict or unchecked runner error", file=sys.stderr)
        return 1
    print("C0_ARENA_GATE no_wrong_verdicts=yes full_coverage=NOT_ESTABLISHED", flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, tarfile.TarError) as exc:
        print(f"C0_ARENA_GATE corpus_or_driver_error={exc}", file=sys.stderr)
        sys.exit(1)
