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
import pathlib
import re
import shutil
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_oracle", HERE / "pskernel-arena435-oracle.py")
ORACLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ORACLE)
HOST_PATH = HERE / "pskernel-arena435-generated-cgroup.py"
HOST_SPEC = importlib.util.spec_from_file_location("arena_generated_cgroup", HOST_PATH)
HOST = importlib.util.module_from_spec(HOST_SPEC)
HOST_SPEC.loader.exec_module(HOST)
PREFIX = "PSC1_ARENA_REPLAY "
VERDICTS = {"accepted", "rejected", "malformed", "unsupported", "resource_exhausted", "internal_error", "driver_error"}


PROGRESS_PREFIX = "PSC1_ARENA_PROGRESS "
PROGRESS_STAGES = {"source-decode", "module-load", "transport", "declaration-ordering",
                   "kernel-admission", "metadata-decode", "metadata-compare"}


def progress_evidence(stderr: str, source_sha256: str) -> dict:
    latest, count, invalid = None, 0, 0
    last_elapsed = -1.0
    for line in stderr.splitlines():
        if not line.startswith(PROGRESS_PREFIX):
            continue
        try:
            value = json.loads(line[len(PROGRESS_PREFIX):])
            if (not isinstance(value, dict)
                    or value.get("format") != "psc1-arena-progress-v2"
                    or value.get("sourceSha256") != source_sha256
                    or value.get("stage") not in PROGRESS_STAGES
                    or value.get("fuel") != "4096"
                    or type(value.get("coreInvoked")) is not bool):
                raise ValueError("invalid progress identity or phase")
            elapsed = value.get("elapsedMilliseconds")
            # Exact type excludes Boolean; the bounds also reject NaN/infinity
            # without converting arbitrary-size JSON integers to float.
            if (type(elapsed) not in (int, float)
                    or not 0 <= elapsed <= 9007199254740991
                    or elapsed < last_elapsed):
                raise ValueError("invalid or nonmonotonic progress time")
            for field in ("records", "exportedDeclarations", "admissionCommands"):
                if field in value and (type(value[field]) is not int or not 0 <= value[field] <= 9007199254740991):
                    raise ValueError("invalid progress counter")
            if "arenaNodes" in value and (not isinstance(value["arenaNodes"], str)
                    or re.fullmatch(r"0|[1-9][0-9]{0,30}", value["arenaNodes"]) is None):
                raise ValueError("invalid progress arena size")
            latest = {key: value[key] for key in
                      ("stage", "coreInvoked", "records", "exportedDeclarations",
                       "admissionCommands", "arenaNodes", "fuel", "sourceSha256",
                       "elapsedMilliseconds") if key in value}
            last_elapsed = elapsed
            count += 1
        except (ValueError, TypeError):
            invalid += 1
    # Full stderr is already an artifact. A progress snapshot is never a verdict.
    return {"progress_snapshots": count, "invalid_progress_snapshots": invalid,
            "last_progress": latest}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def host_failure(host: dict, stderr: str) -> dict | None:
    """Only incomplete host outcomes; this function can never return acceptance."""
    if not isinstance(host, dict):
        return {"verdict": "driver_error", "stage": "host-setup", "reason": "missing host receipt"}
    status = host.get("status")
    if status == "setup_failed" or host.get("hardLimitVerified") is not True:
        return {"verdict": "driver_error", "stage": "host-setup", "reason": "host limit or launch setup failed"}
    if host.get("cleanupOk") is not True:
        return {"verdict": "driver_error", "stage": "host-cleanup", "reason": "private cgroup cleanup failed"}
    if status == "host_error":
        return {"verdict": "driver_error", "stage": "host-monitor", "reason": "host monitoring or wait failed"}
    if host.get("testOnly") is not False or host.get("limitBytes") != HOST.LIMIT:
        return {"verdict": "driver_error", "stage": "host-policy", "reason": "nonproduction host policy"}
    events = host.get("memoryEvents")
    if (not isinstance(events, dict) or not {"oom", "oom_kill"} <= events.keys()
            or any(type(value) is not int or value < 0 for value in events.values())
            or type(host.get("memoryPeakBytes")) is not int or host["memoryPeakBytes"] < 0):
        return {"verdict": "driver_error", "stage": "host-monitor", "reason": "missing or invalid cgroup memory evidence"}
    if status in ("cgroup_oom", "resource_limit") or any(events.get(key, 0) for key in ("oom", "oom_kill", "oom_group_kill")):
        return {"verdict": "resource_exhausted", "stage": "host-memory",
                "reason": "private cgroup reported memory exhaustion", "host_memory_limit_bytes": HOST.LIMIT}
    if status == "timedout" or host.get("wallTimedOut") is True:
        return {"verdict": "timeout", "stage": "host-wall-time", "timeout_seconds": host.get("wallSeconds")}
    if status != "process_exit":
        return {"verdict": "driver_error", "stage": "host-process", "reason": "unknown host process status"}
    if host.get("returncode") not in (0, 2):
        if re.search(r"FATAL ERROR:.*JavaScript heap out of memory", stderr):
            return {"verdict": "resource_exhausted", "stage": "host-heap",
                    "reason": "Node reported JavaScript heap exhaustion", "host_heap_mib": 2048}
        return {"verdict": "driver_error", "stage": "host-process", "reason": "unexpected generated process exit"}
    return None


def finish_case(stdout: str, stderr: str, measurement: dict, source_sha256: str) -> dict:
    failure = host_failure(measurement.get("host"), stderr)
    if failure is not None:
        return {**measurement, **failure}
    matches = [line[len(PREFIX):] for line in stdout.splitlines() if line.startswith(PREFIX)]
    if len(matches) != 1:
        return {**measurement, "verdict": "driver_error", "stage": "report",
                "reason": "missing or duplicate generated-kernel verdict"}
    try:
        result = json.loads(matches[0])
    except (ValueError, TypeError) as exc:
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": str(exc)}
    if (not isinstance(result, dict) or result.get("format") != "psc1-arena-replay-v1" or result.get("verdict") not in VERDICTS
            or result.get("fuel") != "4096"
            or measurement.get("returncode") != (2 if result.get("verdict") == "driver_error" else 0)):
        return {**measurement, "verdict": "driver_error", "stage": "report",
                "reason": "invalid verdict envelope, exit status, or kernel fuel"}
    if result.get("sourceSha256") != source_sha256:
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": "input hash mismatch"}
    if result["verdict"] == "accepted" and (result.get("metadataValidated") is not True or result.get("coreInvoked") is not True):
        return {**measurement, "verdict": "driver_error", "stage": "report", "reason": "acceptance omitted metadata validation"}
    return {**result, **measurement}


def process_case(node: pathlib.Path, runner: pathlib.Path, kernel: pathlib.Path,
                 case: pathlib.Path, timeout: int, logs: pathlib.Path, index: int) -> dict:
    stdout_path = logs / f"case-{index:03d}-stdout.txt"
    stderr_path = logs / f"case-{index:03d}-stderr.txt"
    time_path = logs / f"case-{index:03d}-time.txt"
    source_sha256 = sha256(case.read_bytes())
    try:
        host = HOST.run_generated(node, runner, kernel, case, kernel.parent,
                                  stdout_path, stderr_path, time_path, seconds=timeout)
    except Exception as error:
        return {"verdict": "driver_error", "stage": "host-setup", "reason": repr(error)}
    stdout = stdout_path.read_text(encoding="utf-8", errors="replace") if stdout_path.exists() else ""
    stderr = stderr_path.read_text(encoding="utf-8", errors="replace") if stderr_path.exists() else ""
    measurement = {"elapsed_seconds": host.get("elapsedSeconds"),
                   "returncode": host.get("returncode"), "stdout": stdout_path.name,
                   "stderr": stderr_path.name, "time_log": time_path.name, "host": host,
                   "host_status": host.get("status"),
                   "cgroup_memory_peak_bytes": host.get("memoryPeakBytes"),
                   "sampled_node_vm_hwm_bytes_lower_bound": host.get("sampledNodeVmHwmBytesLowerBound")}
    measurement.update(progress_evidence(stderr, source_sha256))
    if time_path.exists():
        timing = time_path.read_text(encoding="utf-8", errors="replace")
        for label, key, convert in [
            (r"Maximum resident set size \(kbytes\)", "peak_rss_kib", int),
            (r"User time \(seconds\)", "process_cpu_user_seconds", float),
            (r"System time \(seconds\)", "process_cpu_system_seconds", float),
        ]:
            match = re.search(label + r":\s*([0-9]+(?:\.[0-9]+)?)", timing)
            if match:
                measurement[key] = convert(match.group(1))
    return finish_case(stdout, stderr, measurement, source_sha256)


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
    if not 1 <= args.timeout <= 60 or not 1 <= args.workers <= 2:
        parser.error("1..60 second timeout and 1..2 workers are required")
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
                                   "elapsed_seconds", "peak_rss_kib", "last_progress", "invalid_progress_snapshots",
                                   "host_status", "cgroup_memory_peak_bytes", "sampled_node_vm_hwm_bytes_lower_bound")}
                    diagnostic.update(index=record["index"], name=record["name"],
                                      label=record["label"], classification=record["classification"])
                    print("PSC1_ARENA435_DIAGNOSTIC " +
                          json.dumps(diagnostic, ensure_ascii=False), flush=True)
    results.sort(key=lambda record: record["index"])
    counts = Counter(record["classification"] for record in results)
    observed_counts = Counter(record.get("pskernel", {}).get("verdict", "not_run") for record in results)
    matched = sum(record["classification"].startswith("matched_") for record in results)
    host_limits_verified = len(results) == ORACLE.EXPECTED_CASES and all(
        record.get("pskernel", {}).get("host", {}).get("hardLimitVerified") is True
        and record.get("pskernel", {}).get("host", {}).get("cleanupOk") is True
        and record.get("pskernel", {}).get("host", {}).get("testOnly") is False
        for record in results)
    complete = (len(results) == ORACLE.EXPECTED_CASES and matched == ORACLE.EXPECTED_CASES
                and controls_valid and host_limits_verified)
    report = {
        "suite": "all 193 Lean Arena round-2026-09 bodies, current generated PSC1 DAG ingress",
        "archive_sha256": ORACLE.ARCHIVE_SHA256, "target_lean": ORACLE.TARGET,
        "kernel_module_sha256": kernel_hash, "kernel_fuel": 4096,
        "host_timeout_seconds_per_case": args.timeout, "node_heap_limit_mib": 2048,
        "host_cgroup_memory_limit_bytes": HOST.LIMIT, "host_cgroup_swap_limit_bytes": 0,
        "host_launcher_sha256": sha256(HOST_PATH.read_bytes()),
        "all_case_host_limits_verified": host_limits_verified,
        "memory_peak_scope": "cgroup charged memory; separate GNU time RSS and sampled Node VmHWM",
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
