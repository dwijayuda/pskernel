#!/usr/bin/env python3
"""Bounded diagnostics on authentic Arena bodies; never a qualification gate.

The normal run uses the existing comparison harness unchanged. A separate
instrumented run uses V8's streaming tick log, which survives a later SIGKILL.
Both use the same complete public RunDag, 4096 kernel fuel, 60-second host
wall bound and 2048-MiB Node old-space bound. Profiling overhead is not a
performance result, and a timeout is never a semantic verdict.
"""
from __future__ import annotations

import argparse
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
SPEC = importlib.util.spec_from_file_location("arena_compare", HERE / "pskernel-arena435-compare.py")
COMPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COMPARE)
ORACLE = COMPARE.ORACLE
CASES = (
    ("good", "perf/repeated-subproblem.ndjson"),
    ("good", "perf/church-numerals.ndjson"),
    ("good", "init-prelude.ndjson"),
    ("bad", "bugs/proj-of-stuck-prop.ndjson"),
)
WALL_SECONDS = 60
OLD_SPACE_MIB = 2048


def digest(path: pathlib.Path) -> str:
    with path.open("rb") as stream:
        result = hashlib.file_digest(stream, "sha256")
    return result.hexdigest()


def invoke_bounded(command: list[str], cwd: pathlib.Path, stdout: pathlib.Path,
                   stderr: pathlib.Path, seconds: int, empty_path: bool) -> dict:
    """Record observed VmHWM separately from the exact process outcome."""
    started = time.monotonic()
    env = dict(os.environ, LC_ALL="C")
    if empty_path:
        env["PATH"] = ""
    peak = None
    with stdout.open("w", encoding="utf-8") as out, stderr.open("w", encoding="utf-8") as err:
        with subprocess.Popen(command, cwd=cwd, env=env, stdout=out, stderr=err,
                              start_new_session=True) as process:
            timed_out = False
            while process.poll() is None:
                try:
                    status = pathlib.Path(f"/proc/{process.pid}/status").read_text()
                    found = re.search(r"^VmHWM:\s*(\d+)\s+kB$", status, re.MULTILINE)
                    if found:
                        peak = max(peak or 0, int(found.group(1)))
                except (OSError, ValueError):
                    pass
                if time.monotonic() - started >= seconds:
                    timed_out = True
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    break
                time.sleep(0.05)
            process.wait()
            return {"returncode": process.returncode, "timed_out": timed_out,
                    "elapsed_seconds": time.monotonic() - started,
                    "observed_vm_hwm_kib_lower_bound": peak}


def profiled_outcome(measurement: dict, stdout: str, stderr: str, source_hash: str) -> dict:
    measurement = dict(measurement, **COMPARE.progress_evidence(stderr, source_hash))
    if measurement["timed_out"]:
        return dict(measurement, verdict="timeout", stage="host-wall-time",
                    timeout_seconds=WALL_SECONDS)
    envelopes = [line[len(COMPARE.PREFIX):] for line in stdout.splitlines()
                 if line.startswith(COMPARE.PREFIX)]
    if len(envelopes) != 1:
        if re.search(r"FATAL ERROR:.*JavaScript heap out of memory", stderr):
            return dict(measurement, verdict="resource_exhausted", stage="host-heap",
                        host_heap_mib=OLD_SPACE_MIB)
        return dict(measurement, verdict="driver_error", stage="report",
                    reason="missing or duplicate generated-kernel verdict")
    try:
        value = json.loads(envelopes[0])
    except (TypeError, ValueError) as exc:
        return dict(measurement, verdict="driver_error", stage="report", reason=str(exc))
    if (not isinstance(value, dict) or value.get("format") != "psc1-arena-replay-v1"
            or value.get("verdict") not in COMPARE.VERDICTS or value.get("fuel") != "4096"
            or value.get("sourceSha256") != source_hash
            or measurement["returncode"] != (2 if value.get("verdict") == "driver_error" else 0)):
        return dict(measurement, verdict="driver_error", stage="report",
                    reason="invalid verdict identity, resource policy or exit status")
    if value["verdict"] == "accepted" and (
            value.get("metadataValidated") is not True or value.get("coreInvoked") is not True):
        return dict(measurement, verdict="driver_error", stage="report",
                    reason="acceptance omitted independent checking or metadata validation")
    return dict(value, **measurement)


def compact_ticks(text: str) -> list[str]:
    """Keep hottest JS rows and the beginning of the bottom-up caller table."""
    selected, active, remaining = [], False, 0
    for line in text.splitlines():
        if "[JavaScript]:" in line:
            active, remaining = True, 26
        elif "[Bottom up (heavy) profile]:" in line:
            active, remaining = True, 65
        elif active and line.lstrip().startswith("[") and "[Summary]:" not in line:
            active = False
        if active and remaining > 0:
            selected.append(line)
            remaining -= 1
    return selected


def profile_case(node: pathlib.Path, runner: pathlib.Path, kernel: pathlib.Path,
                 case: pathlib.Path, directory: pathlib.Path) -> dict:
    stdout, stderr = directory / "profiled.stdout.txt", directory / "profiled.stderr.txt"
    log_base = directory / "ticks.v8.log"
    command = [str(node), "--prof", f"--logfile={log_base}",
               f"--max-old-space-size={OLD_SPACE_MIB}", str(runner), str(kernel), str(case)]
    observation = invoke_bounded(command, kernel.parent, stdout, stderr, WALL_SECONDS, True)
    result = profiled_outcome(observation, stdout.read_text(), stderr.read_text(), digest(case))
    logs = sorted(directory.glob("*ticks.v8.log"))
    profiles = []
    for index, log in enumerate(logs):
        processed = directory / f"ticks-{index}.processed.txt"
        processing_error = directory / f"ticks-{index}.processing.stderr.txt"
        # Symbol processing is outside the kernel process and may use host nm.
        processing = invoke_bounded([str(node), "--prof-process", str(log)], directory,
                                    processed, processing_error, 45, False)
        with log.open("r", encoding="utf-8", errors="replace") as stream:
            ticks = sum(line.startswith("tick,") for line in stream)
        profiles.append({"raw_log": log.name, "raw_log_sha256": digest(log),
                         "bytes": log.stat().st_size, "tick_records": ticks,
                         "processed": processed.name,
                         "processed_sha256": digest(processed),
                         "processing": processing,
                         "hottest_javascript_and_callers": compact_ticks(processed.read_text())})
    return {"observation": result, "streaming_profiles": profiles,
            "trailing_samples_may_be_lost_on_kill": observation["timed_out"],
            "instrumented_timing_is_not_a_performance_comparison": True,
            "profile_collection_complete": bool(profiles) and all(
                p["tick_records"] > 0 and p["processing"]["returncode"] == 0
                and not p["processing"]["timed_out"] for p in profiles)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--kernel", type=pathlib.Path, required=True)
    parser.add_argument("--official-project", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    source_sha = os.environ.get("GITHUB_SHA", "")
    if re.fullmatch(r"[0-9a-f]{40}", source_sha) is None:
        parser.error("GITHUB_SHA must identify the exact Actions source revision")
    node_path = shutil.which("node")
    if node_path is None:
        parser.error("Node.js is required")
    node = pathlib.Path(node_path).resolve(strict=True)
    project, kernel = args.official_project.resolve(strict=True), args.kernel.resolve(strict=True)
    runner = (HERE / "pskernel-arena-replay.mjs").resolve(strict=True)
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    corpus = {(label, name): original for label, name, original in ORACLE.read_archive(args.archive)}
    records, controls = [], []
    with tempfile.TemporaryDirectory(prefix="psc1-arena-profile-detached-") as tmp:
        detached = pathlib.Path(tmp)
        runtime, replay = detached / "kernel.mjs", detached / "replay.mjs"
        shutil.copyfile(kernel, runtime)
        shutil.copyfile(runner, replay)
        for valid in (True, False):
            expected = "accepted" if valid else "rejected"
            case = out / f"official-control-{expected}.ndjson"
            case.write_bytes(ORACLE.control_bytes(valid))
            controls.append({"expected": expected, **ORACLE.official(
                project, case, 300, out / f"official-control-{expected}.txt")})
        for index, identity in enumerate(CASES):
            label, name = identity
            directory = out / f"case-{index:02d}-{pathlib.PurePosixPath(name).stem}"
            directory.mkdir()
            adapted, receipt = ORACLE.adapt_header(corpus[identity])
            case = directory / "input.ndjson"
            case.write_bytes(adapted)
            official = ORACLE.official(project, case, 300, directory / "official.txt")
            unprofiled = COMPARE.process_case(node, replay, runtime, case, WALL_SECONDS, directory, index)
            profiled = profile_case(node, replay, runtime, case, directory)
            record = {"index": index, "label": label, "name": name,
                      "adaptation": receipt, "official": official, "unprofiled": unprofiled,
                      "unprofiled_classification": COMPARE.classify(official, unprofiled),
                      "profiled": profiled,
                      "profiled_classification": COMPARE.classify(official, profiled["observation"])}
            records.append(record)
            # Persist every completed case before starting the next bounded run.
            (directory / "report.json").write_text(json.dumps(record, indent=2) + "\n")
            print("PSC1_ARENA_AUTHENTIC_PROFILE " + json.dumps({
                "source_sha": source_sha, "name": name, "body_sha256": receipt["original_body_sha256"],
                "official": official["verdict"], "unprofiled": unprofiled["verdict"],
                "profiled": profiled["observation"]["verdict"],
                "last_progress": profiled["observation"].get("last_progress"),
                "observed_vm_hwm_kib_lower_bound": profiled["observation"].get(
                    "observed_vm_hwm_kib_lower_bound"),
                "profile_collection_complete": profiled["profile_collection_complete"],
                "kernel_qualified": False}), flush=True)
            for profile in profiled["streaming_profiles"]:
                print("PSC1_ARENA_AUTHENTIC_HOTTEST " + json.dumps({
                    "name": name, "ticks": profile["tick_records"],
                    "frames": profile["hottest_javascript_and_callers"]}), flush=True)
    complete = (len(records) == len(CASES) and
                all(c["verdict"] == c["expected"] for c in controls) and
                all(r["official"]["verdict"] in ("accepted", "rejected") and
                    r["profiled"]["profile_collection_complete"] and
                    r["unprofiled"]["verdict"] != "driver_error" and
                    r["profiled"]["observation"]["verdict"] != "driver_error" and
                    r["unprofiled_classification"] not in ("false_accept", "false_reject") and
                    r["profiled_classification"] not in ("false_accept", "false_reject")
                    for r in records))
    report = {
        "format": "psc1-authentic-arena-diagnostics-v1", "source_sha": source_sha,
        "kernel_sha256": digest(kernel), "replay_sha256": digest(runner),
        "driver_sha256": digest(pathlib.Path(__file__)),
        "archive_sha256": ORACLE.ARCHIVE_SHA256, "target_lean": ORACLE.TARGET,
        "kernel_fuel": 4096, "host_wall_seconds_per_case": WALL_SECONDS,
        "node_old_space_limit_mib": OLD_SPACE_MIB, "runtime_path_empty": True,
        "case_selection": "fixed diagnostic subset; full 193-case qualification is separate",
        "controls": controls, "cases": records, "diagnostics_complete": complete,
        "kernel_qualified": False,
        "limitations": ["Instrumented timing includes V8 profiler overhead.",
                       "SIGKILL can truncate the final buffered tick-log tail.",
                       "Observed /proc VmHWM is a sampled lower bound on peak RSS.",
                       "Neither profiling nor diagnostic completion establishes kernel conformance."],
    }
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    manifest = [{"path": str(path.relative_to(out)), "sha256": digest(path)}
                for path in sorted(out.rglob("*")) if path.is_file() and path.name != "sha256.json"]
    (out / "sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("PSC1_ARENA_PROFILE_COLLECTION: " + ("COMPLETE" if complete else "INCOMPLETE")
          + " cases=" + str(len(records)) + " kernel_qualified=false", flush=True)
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
