#!/usr/bin/env python3
"""All 193 archived Arena bodies under the pinned official Lean 4.35 kernel.

Only the first metadata line is adapted, in separate temporary files. This is
not a native 4.35 re-export, not a verdict on the unmodified historical envelope,
and not PSKernel-Core qualification. Declaration body bytes remain identical.
"""
from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import pathlib
import os
import signal
import re
import subprocess
import sys
import tarfile
import tempfile
import time

ARCHIVE_SHA256 = "98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"
TARGET = {"version": "4.35.0", "githash": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"}
EXPECTED_CASES = 193
MAX_CASE_BYTES = 10 * 1024 * 1024
MAX_BODY_BYTES = 60 * 1024 * 1024


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_archive(path: pathlib.Path) -> list[tuple[str, str, bytes]]:
    raw = path.read_bytes()
    if len(raw) != 3497743 or digest(raw) != ARCHIVE_SHA256:
        raise ValueError("Arena archive size or SHA256 mismatch")
    cases, seen, total = [], set(), 0
    with tarfile.open(path, "r:gz") as archive:
        for member in archive:
            if not (member.isfile() or member.isdir()):
                raise ValueError(f"unsupported archive member: {member.name}")
            if not member.isfile():
                continue
            parts = pathlib.PurePosixPath(member.name).parts
            if member.name.startswith("/") or ".." in parts:
                raise ValueError(f"unsafe archive identity: {member.name}")
            if not member.name.endswith(".ndjson"):
                continue
            labels = [part for part in parts if part in ("good", "bad")]
            if len(labels) != 1:
                raise ValueError(f"unclassified NDJSON case: {member.name}")
            label = labels[0]
            name = "/".join(parts[parts.index(label) + 1:])
            identity = (label, name)
            if not name or identity in seen:
                raise ValueError(f"duplicate or empty case identity: {identity}")
            if member.size > MAX_CASE_BYTES:
                raise ValueError(f"case exceeds pinned corpus bound: {member.name}")
            stream = archive.extractfile(member)
            if stream is None:
                raise ValueError(f"missing corpus bytes: {member.name}")
            payload = stream.read(MAX_CASE_BYTES + 1)
            if len(payload) != member.size:
                raise ValueError(f"incomplete corpus bytes: {member.name}")
            total += len(payload)
            if total > MAX_BODY_BYTES:
                raise ValueError("unexpected corpus expansion")
            seen.add(identity)
            cases.append((label, name, payload))
    if len(cases) != EXPECTED_CASES or {case[0] for case in cases} != {"good", "bad"}:
        raise ValueError(f"expected every one of {EXPECTED_CASES} labeled cases, got {len(cases)}")
    return sorted(cases)


def adapt_header(original: bytes) -> tuple[bytes, dict]:
    prefix, newline, body = original.partition(b"\n")
    if newline != b"\n" or not body:
        raise ValueError("missing complete metadata line or declaration body")
    record = json.loads(prefix.decode("utf-8"))
    if not isinstance(record, dict) or set(record) != {"meta"}:
        raise ValueError("initial record is not standalone metadata")
    meta = record["meta"]
    if not isinstance(meta, dict) or meta.get("format", {}).get("version") != "3.1.0":
        raise ValueError("unsupported export wire format")
    old_lean = meta.get("lean")
    exporter = meta.get("exporter")
    if (not isinstance(old_lean, dict) or set(old_lean) != {"version", "githash"}
            or any(not isinstance(value, str) for value in old_lean.values())
            or not isinstance(exporter, dict)
            or not isinstance(exporter.get("name"), str)
            or not isinstance(exporter.get("version"), str)):
        raise ValueError("invalid source provenance")
    meta["lean"] = dict(TARGET)
    adapted = json.dumps(record, ensure_ascii=False, separators=(",", ":")).encode() + b"\n" + body
    adapted_body = adapted.partition(b"\n")[2]
    if adapted_body != body:
        raise AssertionError("declaration body changed")
    return adapted, {
        "method": "header_only_compatibility_NOT_native_435_reexport",
        "original_lean": old_lean, "target_lean": TARGET,
        "original_sha256": digest(original), "adapted_sha256": digest(adapted),
        "original_body_sha256": digest(body), "adapted_body_sha256": digest(adapted_body),
        "body_bytes_identical": True,
    }


def parse_verdict(output: str, status: int) -> dict:
    accepts = output.count("Lean default kernel accepts the solution")
    rejects = output.count("Lean default kernel rejects the solution")
    quot_rejects = output.count("Quotient post-check rejects the solution")
    if accepts == 1 and rejects == 0 and quot_rejects == 0 and status == 0:
        return {"verdict": "accepted", "reason": "official_kernel_verdict"}
    if accepts == 0 and rejects == 1 and quot_rejects == 0 and status != 0:
        return {"verdict": "rejected", "reason": "official_kernel_verdict"}
    if accepts == 1 and rejects == 0 and quot_rejects == 1 and status != 0:
        return {"verdict": "rejected", "reason": "official_quotient_postcheck_rejection"}
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    if (status != 0 and accepts == 0 and rejects == 0 and len(lines) == 1
            and re.fullmatch(r"uncaught exception: Duplicate declaration: \S+", lines[0])):
        return {"verdict": "rejected", "reason": "official_kernel_duplicate_declaration"}
    return {"verdict": "driver_error", "reason": "no unambiguous official kernel verdict"}


def official(project: pathlib.Path, path: pathlib.Path, timeout: int, log: pathlib.Path) -> dict:
    start = time.monotonic()
    try:
        with subprocess.Popen(["lake", "env", "leanchecker", "--from-export", str(path)],
                              cwd=project, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, encoding="utf-8", errors="replace",
                              start_new_session=True) as process:
            try:
                stdout, stderr = process.communicate(timeout=timeout)
                output = stdout + "\n" + stderr
                result = {**parse_verdict(output, process.returncode), "returncode": process.returncode}
            except subprocess.TimeoutExpired:
                # lake may launch leanchecker as a child: terminate and reap the
                # complete isolated group before the next case is evaluated.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                stdout, stderr = process.communicate()
                output = stdout + "\n" + stderr
                result = {"verdict": "timeout", "returncode": None}
    except OSError as exc:
        output = str(exc)
        result = {"verdict": "driver_error", "returncode": None}
    log.write_text(output, encoding="utf-8")
    return {**result, "elapsed_seconds": time.monotonic() - start,
            "log": log.name, "output_sha256": digest(output.encode())}


def control_bytes(valid: bool) -> bytes:
    # Hand-authored controls of the published 3.1.0 wire format, not exports.
    records = [
        {"meta": {"exporter": {"name": "pskernel-oracle-control", "version": "3.1.0"},
                  "format": {"version": "3.1.0"}, "lean": TARGET}},
        {"in": 1, "str": {"pre": 0, "str": "PsKernelArenaOracleControl"}},
        {"il": 1, "succ": 0}, {"ie": 0, "sort": 0}, {"ie": 1, "sort": 1},
        {"def": {"all": [1], "hints": "abbrev", "levelParams": [], "name": 1,
                 "safety": "safe", "type": 1 if valid else 0, "value": 0}},
    ]
    return ("\n".join(json.dumps(record, separators=(",", ":")) for record in records) + "\n").encode()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--official-project", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()
    if args.timeout < 1 or not 1 <= args.workers <= 4:
        parser.error("positive timeout and 1..4 workers are required")
    project = args.official_project.resolve(strict=True)
    args.out = args.out.resolve()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    logs = args.out.parent / "case-logs"
    logs.mkdir(exist_ok=True)
    cases = read_archive(args.archive)
    controls, results = [], []
    with tempfile.TemporaryDirectory(prefix="psc1-arena435-reference-") as folder:
        work = pathlib.Path(folder)
        # These run serially first, also initializing lake's environment once.
        for valid in (True, False):
            expected = "accepted" if valid else "rejected"
            path = work / f"control-{expected}.ndjson"
            path.write_bytes(control_bytes(valid))
            result = official(project, path, args.timeout, logs / f"control-{expected}.txt")
            controls.append({"expected": expected, **result})
            print(f"PSC1_ARENA435_ORACLE_CONTROL expected={expected} observed={result['verdict']}", flush=True)

        def evaluate(index: int, case: tuple[str, str, bytes]) -> dict:
            label, name, original = case
            expected = "accepted" if label == "good" else "rejected"
            record = {"index": index, "label": label, "name": name, "historical_expected": expected}
            try:
                adapted, receipt = adapt_header(original)
                path = work / f"case-{index}.ndjson"
                path.write_bytes(adapted)
                observation = official(project, path, args.timeout, logs / f"case-{index:03d}.txt")
                record.update({"adaptation": receipt, "official": observation,
                               "classification": observation["verdict"],
                               "historical_label_matches_official": observation["verdict"] == expected})
            except (ValueError, TypeError, KeyError, AttributeError, UnicodeError) as exc:
                record.update({"classification": "adaptation_error", "error": f"{type(exc).__name__}: {exc}"})
            return record

        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = [executor.submit(evaluate, index, case) for index, case in enumerate(cases)]
            for future in as_completed(futures):
                record = future.result()
                results.append(record)
                print(f"PSC1_ARENA435_REFERENCE case={record['index'] + 1}/{len(cases)} "
                      f"label={record['label']} name={record['name']} verdict={record['classification']}", flush=True)
    results.sort(key=lambda record: record["index"])
    counts = Counter(record["classification"] for record in results)
    matched_controls = all(record["expected"] == record["verdict"] for record in controls)
    complete = (len(results) == EXPECTED_CASES and
                counts["accepted"] + counts["rejected"] == EXPECTED_CASES and
                all(record.get("adaptation", {}).get("body_bytes_identical") is True for record in results))
    report = {
        "suite": "Lean Kernel Arena round-2026-09 official reference",
        "archive_sha256": ARCHIVE_SHA256, "target_lean": TARGET,
        "scope": "all 193 archived 3.1.0 declaration bodies, header-only provenance adaptation",
        "native_435_reexport": False, "historical_envelope_checked_unchanged": False,
        "pskernel_core_comparison_performed": False,
        "pskernel_core_qualification": "NOT_ESTABLISHED_BY_THIS_ORACLE_RUN",
        "excluded_cases": [], "total": len(results), "controls": controls,
        "counts": dict(sorted(counts.items())), "official_reference_complete": complete,
        "historical_label_drift": sum(record.get("official", {}).get("verdict") in ("accepted", "rejected")
                                     and record.get("historical_label_matches_official") is False for record in results),
        "tests": results,
    }
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PSC1_ARENA435_REFERENCE_SUMMARY total={len(results)} counts={dict(sorted(counts.items()))} "
          f"controls_pass={matched_controls} complete={complete} independent_kernel_qualified=false", flush=True)
    return 0 if complete and matched_controls else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, tarfile.TarError) as exc:
        print(f"PSC1_ARENA435_REFERENCE_DRIVER_ERROR {exc}", file=sys.stderr)
        sys.exit(1)
