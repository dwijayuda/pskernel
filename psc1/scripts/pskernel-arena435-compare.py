#!/usr/bin/env python3
"""Compare all pinned Arena cases with the actual generated PSC1 DAG ingress.

Every case receives an outcome. Unsupported/resource outcomes are not matches;
no incomplete corpus run can establish full independent-kernel qualification.
"""
from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_oracle", HERE / "pskernel-arena435-oracle.py")
ORACLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ORACLE)
PREFIX = "PSC1_ARENA_REPLAY "
VERDICTS = {"accepted", "rejected", "malformed", "unsupported", "resource_exhausted", "internal_error", "driver_error"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def process_case(node: pathlib.Path, runner: pathlib.Path, kernel: pathlib.Path,
                 case: pathlib.Path, timeout: int, logs: pathlib.Path, index: int) -> dict:
    stdout_path = logs / f"case-{index:03d}-stdout.txt"
    stderr_path = logs / f"case-{index:03d}-stderr.txt"
    time_path = logs / f"case-{index:03d}-time.txt"
    command = ["/usr/bin/time", "-v", "-o", str(time_path), str(node),
               "--max-old-space-size=2048", str(runner), str(kernel), str(case)]
    started = time.monotonic()
    env = dict(os.environ, PATH="", LC_ALL="C")
    try:
        process = subprocess.Popen(command, cwd=kernel.parent, env=env, start_new_session=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, encoding="utf-8", errors="replace")
    except OSError as exc:
        return {"verdict": "driver_error", "stage": "launch", "reason": str(exc)}
    timed_out = False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
    stdout_path.write_text(stdout, encoding="utf-8")
    stderr_path.write_text(stderr, encoding="utf-8")
    measurement = {"elapsed_seconds": time.monotonic() - started,
                   "returncode": process.returncode, "stdout": stdout_path.name,
                   "stderr": stderr_path.name, "time_log": time_path.name}
    if time_path.exists():
        match = re.search(r"Maximum resident set size \(kbytes\):\s*(\d+)", time_path.read_text())
        if match:
            measurement["peak_rss_kib"] = int(match.group(1))
    if timed_out:
        return {**measurement, "verdict": "timeout", "stage": "host-wall-time", "timeout_seconds": timeout}
    matches = [line[len(PREFIX):] for line in stdout.splitlines() if line.startswith(PREFIX)]
    if len(matches) != 1:
        if re.search(r"FATAL ERROR:.*JavaScript heap out of memory", stderr):
            return {**measurement, "verdict": "resource_exhausted", "stage": "host-heap",
                    "reason": "Node reported JavaScript heap exhaustion", "host_heap_mib": 2048}
        return {**measurement, "verdict": "driver_error", "stage": "report",
                "reason": "missing or duplicate generated-kernel verdict"}
    try:
        result = json.loads(matches[0])
    except (ValueError, TypeError) as exc:
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": str(exc)}
    if (result.get("format") != "psc1-arena-replay-v1" or result.get("verdict") not in VERDICTS
            or result.get("fuel") != "4096"
            or process.returncode != (2 if result.get("verdict") == "driver_error" else 0)):
        return {**measurement, "verdict": "driver_error", "stage": "report",
                "reason": "invalid verdict envelope, exit status, or kernel fuel"}
    if result.get("sourceSha256") != sha256(case.read_bytes()):
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": "input hash mismatch"}
    if result["verdict"] == "accepted" and (result.get("metadataValidated") is not True or result.get("coreInvoked") is not True):
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": "acceptance omitted metadata validation"}
    return {**result, **measurement}


def classify(reference: dict, observed: dict) -> str:
    official, current = reference.get("verdict"), observed.get("verdict")
    if official not in ("accepted", "rejected"):
        return "official_" + str(official or "missing")
    if current not in ("accepted", "rejected", "malformed"):
        return "pskernel_" + str(current or "missing")
    if current == "accepted" and official == "rejected":
        return "false_accept"
    if current in ("rejected", "malformed") and official == "accepted":
        return "false_reject"
    if observed.get("containsUnsafeOrPartial") is True:
        return "agreement_with_unsafe_or_partial_contract_difference"
    if current == "accepted":
        return "matched_acceptance"
    if current == "malformed":
        return "matched_transport_rejection"
    return "matched_metadata_rejection" if observed.get("stage") == "metadata" else "matched_kernel_rejection"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--oracle-report", type=pathlib.Path, required=True)
    parser.add_argument("--kernel", type=pathlib.Path, required=True)
    parser.add_argument("--runner", type=pathlib.Path, default=HERE / "pskernel-arena-replay.mjs")
    parser.add_argument("--node", type=pathlib.Path, default=pathlib.Path(shutil.which("node") or "/usr/bin/node"))
    parser.add_argument("--out", type=pathlib.Path, required=True)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--workers", type=int, default=2)
    args = parser.parse_args()
    if args.timeout < 1 or not 1 <= args.workers <= 2:
        parser.error("positive timeout and 1..2 workers are required")
    node, runner, kernel = (item.resolve(strict=True) for item in (args.node, args.runner, args.kernel))
    cases = ORACLE.read_archive(args.archive)
    reference = json.loads(args.oracle_report.read_text(encoding="utf-8"))
    if reference.get("archive_sha256") != ORACLE.ARCHIVE_SHA256 or reference.get("target_lean") != ORACLE.TARGET:
        raise ValueError("official reference provenance does not match the pinned corpus and Lean commit")
    references = {(record["label"], record["name"]): record for record in reference["tests"]}
    if (len(reference["tests"]) != ORACLE.EXPECTED_CASES or len(references) != ORACLE.EXPECTED_CASES
            or set(references) != {(label, name) for label, name, _raw in cases}):
        raise ValueError("official reference does not enumerate all 193 unique source identities")
    controls = reference.get("controls", [])
    controls_valid = (len(controls) == 2 and {item.get("expected") for item in controls} == {"accepted", "rejected"}
                      and all(item.get("expected") == item.get("verdict") for item in controls))
    args.out = args.out.resolve()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    logs = args.out.parent / "case-logs"
    logs.mkdir(exist_ok=True)
    results = []
    with tempfile.TemporaryDirectory(prefix="psc1-arena-independent-") as folder:
        work = pathlib.Path(folder)
        detached_kernel, detached_runner = work / "kernel.mjs", work / "replay.mjs"
        shutil.copyfile(kernel, detached_kernel)
        shutil.copyfile(runner, detached_runner)
        kernel_hash = sha256(detached_kernel.read_bytes())

        def evaluate(index: int, case: tuple[str, str, bytes]) -> dict:
            label, name, original = case
            record = {"index": index, "label": label, "name": name,
                      "historical_expected": "accepted" if label == "good" else "rejected"}
            source_reference = references[(label, name)]
            try:
                adapted, receipt = ORACLE.adapt_header(original)
                record["adaptation"] = receipt
                reference_receipt = source_reference.get("adaptation", {})
                provenance_ok = all(reference_receipt.get(field) == receipt[field] for field in
                                    ("original_sha256", "adapted_sha256", "original_body_sha256",
                                     "adapted_body_sha256", "body_bytes_identical"))
                record["official_provenance_matches"] = provenance_ok
                record["official"] = source_reference.get("official", {"verdict": "missing"})
                path = work / f"case-{index}.ndjson"
                path.write_bytes(adapted)
                observed = process_case(node, detached_runner, detached_kernel, path, args.timeout, logs, index)
                record["pskernel"] = observed
                record["classification"] = classify(record["official"], observed) if provenance_ok else "official_provenance_mismatch"
            except (ValueError, TypeError, KeyError, UnicodeError) as exc:
                record.update({"classification": "adaptation_error", "reason": f"{type(exc).__name__}: {exc}"})
            return record

        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = [executor.submit(evaluate, index, case) for index, case in enumerate(cases)]
            for future in as_completed(futures):
                record = future.result()
                results.append(record)
                print(f"PSC1_ARENA435_COMPARE case={record['index'] + 1}/{len(cases)} "
                      f"label={record['label']} name={record['name']} "
                      f"official={record.get('official', {}).get('verdict', 'none')} "
                      f"pskernel={record.get('pskernel', {}).get('verdict', 'none')} "
                      f"class={record['classification']}", flush=True)
                if not record["classification"].startswith("matched_"):
                    observation = record.get("pskernel", {})
                    diagnostic = {key: observation.get(key) for key in
                                  ("verdict", "stage", "reason", "coreInvoked",
                                   "exportedDeclarations", "admissionCommands", "arenaNodes",
                                   "elapsed_seconds", "peak_rss_kib")}
                    diagnostic.update(index=record["index"], name=record["name"],
                                      label=record["label"], classification=record["classification"])
                    print("PSC1_ARENA435_DIAGNOSTIC " +
                          json.dumps(diagnostic, ensure_ascii=False), flush=True)
    results.sort(key=lambda record: record["index"])
    counts = Counter(record["classification"] for record in results)
    observed_counts = Counter(record.get("pskernel", {}).get("verdict", "not_run") for record in results)
    matched = sum(record["classification"].startswith("matched_") for record in results)
    complete = len(results) == ORACLE.EXPECTED_CASES and matched == ORACLE.EXPECTED_CASES and controls_valid
    report = {
        "suite": "all 193 Lean Arena round-2026-09 bodies, current generated PSC1 DAG ingress",
        "archive_sha256": ORACLE.ARCHIVE_SHA256, "target_lean": ORACLE.TARGET,
        "kernel_module_sha256": kernel_hash, "kernel_fuel": 4096,
        "host_timeout_seconds_per_case": args.timeout, "node_heap_limit_mib": 2048,
        "host_workers": args.workers, "runtime_path_empty": True,
        "runtime_working_directory_contains_no_Lean_or_repository_sources": True,
        "native_435_reexport": False, "declaration_body_bytes_unchanged": True,
        "total": len(results), "excluded_cases": [], "official_controls_valid": controls_valid,
        "all_cases_recorded": len(results) == ORACLE.EXPECTED_CASES,
        "actual_matched_cases": matched, "arena_comparison_complete": complete,
        "full_expression_v2_replacement_established": False,
        "counts": dict(sorted(counts.items())), "pskernel_verdicts": dict(sorted(observed_counts.items())),
        "tests": results,
    }
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PSC1_ARENA435_COMPARE_SUMMARY total={len(results)} matched={matched} "
          f"counts={dict(sorted(counts.items()))} complete={complete} fuel=4096", flush=True)
    # A partial report is evidence of remaining work, not a successful full gate.
    return 0 if complete else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError) as exc:
        print(f"PSC1_ARENA435_COMPARE_DRIVER_ERROR {exc}", file=sys.stderr)
        sys.exit(1)
