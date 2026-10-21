#!/usr/bin/env python3
"""Replay all 193 authenticated bodies using a qualified artifact and fixed 2 GiB host policy."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
HOST_SOURCE = "275833e70351684b10256ec922aa90d13e813159"
AUTH_SOURCE = "7ae480eedcc7c6c67e63ebdb7a6f4eedcf7ddaa4"
KERNEL_SOURCE = "34126793178021a9cd1bdb37aa6fe17c0fab41c6"
KERNEL_RUN = 39640226534
KERNEL_ARTIFACT = 12367640311
KERNEL_ZIP_SHA256 = "d3240a7df49e6cca93dcc0c982e42b188a9b3792a1fb8421953b624a074ac98f"
KERNEL_JS_SHA256 = "d06d13d2e4cb54e8ea00aa0bfbb5b00b98cf3c2be1a610ccb5c699c64ee946c9"
KERNEL_JS_BYTES = 9893728
DEADLINE = 60
WORKERS = 2
LIMIT = 2147483648
RUNTIME_ENV = {"PATH": "", "LANG": "C.UTF-8", "LC_ALL": "C", "TZ": "UTC"}
HOST_FILES = (
    "psc1/scripts/pskernel-arena435-compare.py",
    "psc1/scripts/pskernel-arena435-generated-cgroup.py",
    "psc1/scripts/pskernel-arena435-host-controls.py",
    "psc1/scripts/pskernel-arena435-host-control.mjs",
    "psc1/scripts/pskernel-arena435-progress-controls.py",
    "psc1/scripts/pskernel-arena435-oracle.py",
    "psc1/scripts/pskernel-arena-replay.mjs",
    "psc1/scripts/pskernel-arena-replay-controls.mjs",
)
SHARED_FILES = ("psc1/scripts/pskernel-arena435-oracle.py",
                "psc1/scripts/pskernel-arena-replay.mjs",
                "psc1/scripts/pskernel-arena-replay-controls.mjs")
AUTH_FILE = "psc1/scripts/pskernel-paired-artifacts.py"
CONTROL_WRAPPER = "import { fileURLToPath, pathToFileURL } from \"node:url\";\nimport path from \"node:path\";\n\n// Command-line adaptation only: run the unchanged strict-argc control module.\nconst directory = path.dirname(fileURLToPath(import.meta.url));\nconst [kernel, controls] = process.argv.slice(2);\nif (process.argv.length !== 4 ||\n    kernel !== path.join(directory, \"kernel.mjs\") ||\n    controls !== path.join(directory, \"pskernel-arena-replay-controls.mjs\"))\n  throw Error(\"PSC1_ARTIFACT_ARENA_CONTROL_PATHS_DIFFER\");\nprocess.argv = [process.execPath, controls, kernel];\nawait import(pathToFileURL(controls).href);\n"


def require(condition, message):
    if condition is not True:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), "expected JSON object: " + str(path))
    return value


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, "missing pinned host module")
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def verify_checkout(root, expected, files):
    git = shutil.which("git")
    require(git is not None, "git required only for source authentication")
    actual = subprocess.check_output([git, "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    require(actual == expected, "checkout source differs: " + str(root))
    records = []
    for relative in files:
        committed = subprocess.check_output([git, "-C", str(root), "show", expected + ":" + relative])
        data = (root / relative).read_bytes()
        require(data == committed, "checked-out file differs from exact Git object: " + relative)
        records.append({"path": relative, "bytes": len(data), "sha256": digest(data)})
    return {"source_sha": actual, "files": records}


def authenticate(runtimes, artifacts):
    value = read_json(runtimes / "authentication.json")
    require(value.get("format") == "psc1-paired-performance-artifacts-v1"
            and value.get("repository") == artifacts.REPOSITORY
            and value.get("compiler_reexecuted") is False
            and value.get("canonical_rechecked") is False
            and value.get("new_kernel_qualification_established") is False,
            "artifact authentication protocol differs")
    identities = {
        "baseline": (artifacts.BASELINE_SOURCE, artifacts.BASELINE_RUN,
                     artifacts.BASELINE_ARTIFACT, artifacts.BASELINE_ZIP_SHA256,
                     artifacts.BASELINE_KERNEL_SHA256),
        "candidate": (KERNEL_SOURCE, KERNEL_RUN, KERNEL_ARTIFACT, KERNEL_ZIP_SHA256, KERNEL_JS_SHA256),
    }
    for label, expected in identities.items():
        receipt = value[label]
        require(tuple(receipt.get(field) for field in
            ("source_sha", "producer_run", "artifact_id", "artifact_zip_sha256", "kernel_sha256")) == expected,
            "immutable artifact identity differs: " + label)
        raw = (runtimes / (label + ".zip")).read_bytes()
        require(digest(raw) == expected[3] and len(raw) == receipt["artifact_zip_bytes"],
                "authenticated archive bytes changed: " + label)
        jobs = receipt["required_jobs"]
        require(len(jobs) == 2 and {job["name"] for job in jobs} ==
                {"native-dag-integration", "generated-dag-integration"}
                and all(job["conclusion"] == "success" for job in jobs),
                "producer integration qualification differs")
    official = value["official_reference"]
    require(official["source_sha"] == artifacts.BASELINE_SOURCE
            and official["producer_run"] == artifacts.REFERENCE_RUN
            and official["producer_job"] == artifacts.REFERENCE_JOB
            and official["artifact_id"] == artifacts.REFERENCE_ARTIFACT
            and official["artifact_zip_sha256"] == artifacts.REFERENCE_ZIP_SHA256
            and digest((runtimes / "official-reference.zip").read_bytes()) == artifacts.REFERENCE_ZIP_SHA256
            and digest((runtimes / "official-reference.json").read_bytes()) == official["report_sha256"],
            "official reference identity or bytes differ")
    return value


def write_report(out, report):
    temporary = out / "receipt.json.tmp"
    temporary.write_text(json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n",
                         encoding="utf-8")
    temporary.replace(out / "receipt.json")


def output_digests(out):
    rows = []
    for path in sorted(out.rglob("*")):
        if path.is_file() and path.name != "outputs.sha256":
            rows.append(digest(path.read_bytes()) + "  " + path.relative_to(out).as_posix())
    (out / "outputs.sha256").write_text("\n".join(rows) + "\n", encoding="utf-8")


def run_small(command, cwd, log, *, timeout, environment):
    result = subprocess.run(command, cwd=cwd, env=environment, capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=timeout)
    combined = result.stdout + result.stderr
    log.write_text(combined, encoding="utf-8")
    require(len(combined.encode("utf-8")) <= 512 * 1024, "bounded control log exceeds 512 KiB")
    print(combined, end="" if combined.endswith("\n") else "\n", flush=True)
    return result.returncode, combined


def run_host_controls(host_root, node, out, report):
    scripts = host_root / "psc1/scripts"
    environment = {"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8", "LC_ALL": "C",
                   "TZ": "UTC", "GITHUB_SHA": HOST_SOURCE}
    code, progress = run_small([sys.executable, str(scripts / "pskernel-arena435-progress-controls.py")],
        host_root, out / "progress-controls.log", timeout=30, environment=environment)
    require(code == 0 and progress.splitlines().count("PSC1_ARENA_PROGRESS_CONTROLS: PASS count=24") == 1,
            "original progress controls failed")
    report["progress_controls"] = {"assertions": 24, "passed": True, "host_source_sha": HOST_SOURCE}
    write_report(out, report)
    code, controls = run_small([sys.executable, str(scripts / "pskernel-arena435-host-controls.py"),
        "--node", str(node), "--out", str(out / "host-controls")], host_root,
        out / "host-controls.log", timeout=90, environment=environment)
    host = read_json(out / "host-controls/report.json")
    report["host_controls"] = host
    write_report(out, report)
    require(code == 0 and host.get("source_sha") == HOST_SOURCE and host.get("complete") is True
            and host.get("parser_assertions") == 70 and host.get("live_complete") is True
            and len(host.get("live", [])) == 6 and host.get("production_limit_bytes") == LIMIT
            and host.get("control_only_limit_bytes") == 134217728,
            "fresh host-control matrix failed")
    require(controls.splitlines().count("PSC1_ARENA_HOST_PARSER_CONTROLS: PASS count=70") == 1
            and controls.splitlines().count("PSC1_ARENA_HOST_LIVE_CONTROLS: PASS count=6") == 1,
            "host-control completion markers differ")


def replay_controls(compare, kernel, source_root, node, out, report):
    work = out / "detached-controls"
    work.mkdir()
    target = work / "kernel.mjs"
    shutil.copyfile(kernel, target)
    for name in ("pskernel-arena-replay.mjs", "pskernel-arena-replay-controls.mjs"):
        shutil.copyfile(source_root / "psc1/scripts" / name, work / name)
    runner = work / "control-runner.mjs"
    runner.write_text(CONTROL_WRAPPER, encoding="utf-8")
    stdout, stderr, timing = (work / name for name in ("stdout.txt", "stderr.txt", "time.txt"))
    host = compare.HOST.run_generated(node, runner, target, work / "pskernel-arena-replay-controls.mjs",
                                     work, stdout, stderr, timing, seconds=DEADLINE)
    text = stdout.read_text(encoding="utf-8", errors="replace") if stdout.exists() else ""
    errors = stderr.read_text(encoding="utf-8", errors="replace") if stderr.exists() else ""
    failure = compare.host_failure(host, errors)
    markers = [line for line in text.splitlines() if line.startswith("PSC1_ARENA_REPLAY_CONTROLS:")]
    count = len([line for line in text.splitlines() if line.startswith("PSC1_ARENA_CONTROL_PASS ")])
    receipt = {
        "host": host, "host_failure": failure, "expected_assertions": 138, "actual_assertions": count,
        "kernel_sha256": digest(target.read_bytes()),
        "control_script_sha256": digest((work / "pskernel-arena-replay-controls.mjs").read_bytes()),
        "control_replay_sha256": digest((work / "pskernel-arena-replay.mjs").read_bytes()),
        "cli_adapter_sha256": digest(runner.read_bytes()),
        "cli_scope": "restore original strict argc3 then import unchanged control module; no kernel decisions",
        "passed": failure is None and host.get("returncode") == 0
                  and markers == ["PSC1_ARENA_REPLAY_CONTROLS: PASS count=138"] and count == 138,
    }
    report["replay_controls"] = receipt
    write_report(out, report)
    require(len(text.encode("utf-8")) + len(errors.encode("utf-8")) <= 512 * 1024,
            "replay-control console output exceeds bound")
    print(text, end="" if text.endswith("\n") else "\n", flush=True)
    if errors:
        print(errors, end="" if errors.endswith("\n") else "\n", flush=True)
    print("PSC1_ARTIFACT_ARENA_REPLAY_HOST " + json.dumps(receipt, allow_nan=False), flush=True)
    require(receipt["passed"] is True and receipt["kernel_sha256"] == KERNEL_JS_SHA256,
            "unchanged replay controls failed under production 2 GiB policy")


def run_comparison(compare_path, node, kernel, runner, archive, reference, out):
    command = [sys.executable, str(compare_path), "--archive", str(archive),
               "--oracle-report", str(reference), "--kernel", str(kernel), "--runner", str(runner),
               "--node", str(node), "--out", str(out / "comparison/report.json"),
               "--timeout", str(DEADLINE), "--workers", str(WORKERS)]
    (out / "comparison").mkdir()
    environment = {"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8", "LC_ALL": "C", "TZ": "UTC"}
    # Each checker has the unchanged 60s cgroup deadline. The workflow has the overall 120min bound.
    with (out / "comparison/run.log").open("w", encoding="utf-8") as logfile:
        child = subprocess.Popen(command, cwd=out, env=environment, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
        require(child.stdout is not None, "missing comparison output pipe")
        for line in child.stdout:
            logfile.write(line)
            logfile.flush()
            print(line, end="", flush=True)
        return child.wait()


def compact_case(record):
    observed = record.get("pskernel", {})
    host = observed.get("host", {})
    launch = host.get("launch", {})
    encoded = json.dumps(record, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)
    return {
        "index": record.get("index"), "label": record.get("label"), "name": record.get("name"),
        "classification": record.get("classification"), "historical_expected": record.get("historical_expected"),
        "official_verdict": record.get("official", {}).get("verdict"),
        "official_provenance_matches": record.get("official_provenance_matches"),
        "adaptation": record.get("adaptation"),
        "verdict": observed.get("verdict"), "stage": observed.get("stage"), "reason": observed.get("reason"),
        "coreInvoked": observed.get("coreInvoked"), "metadataValidated": observed.get("metadataValidated"),
        "containsUnsafeOrPartial": observed.get("containsUnsafeOrPartial"),
        "fuel": observed.get("fuel"), "sourceSha256": observed.get("sourceSha256"),
        "exportedDeclarations": observed.get("exportedDeclarations"), "admissionCommands": observed.get("admissionCommands"),
        "arenaNodes": observed.get("arenaNodes"), "elapsed_seconds": observed.get("elapsed_seconds"),
        "peak_rss_kib": observed.get("peak_rss_kib"),
        "process_cpu_user_seconds": observed.get("process_cpu_user_seconds"),
        "process_cpu_system_seconds": observed.get("process_cpu_system_seconds"),
        "last_progress": observed.get("last_progress"),
        "invalid_progress_snapshots": observed.get("invalid_progress_snapshots"),
        "host": {key: host.get(key) for key in
            ("status", "limitBytes", "wallSeconds", "testOnly", "hardLimitVerified", "cleanupOk",
             "memoryPeakBytes", "memoryEvents", "wallTimedOut", "setupTimedOut", "returncode",
             "sampledNodeVmHwmBytesLowerBound")},
        "launch": {key: launch.get(key) for key in
            ("uid", "gid", "groups", "path", "memoryMax", "swapMax", "oomGroup", "mode")},
        "full_record_canonical_json_sha256": digest(encoded.encode("utf-8")),
    }


def validate_comparison(report, compare, corpus, reference, compare_code):
    expected = {
        "archive_sha256": compare.ORACLE.ARCHIVE_SHA256, "target_lean": compare.ORACLE.TARGET,
        "kernel_module_sha256": KERNEL_JS_SHA256, "kernel_fuel": 4096,
        "host_timeout_seconds_per_case": DEADLINE, "node_heap_limit_mib": 2048,
        "host_cgroup_memory_limit_bytes": LIMIT, "host_cgroup_swap_limit_bytes": 0,
        "host_launcher_sha256": digest(compare.HOST_PATH.read_bytes()), "host_workers": WORKERS,
        "runtime_path_empty": True, "native_435_reexport": False,
        "declaration_body_bytes_unchanged": True, "excluded_cases": [],
        "all_cases_recorded": True, "total": 193, "full_expression_v2_replacement_established": False,
    }
    for key, value in expected.items():
        require(report.get(key) == value, "comparison provenance/policy differs: " + key)
    rows = report["tests"]
    require(len(rows) == len(corpus) == 193 and [row.get("index") for row in rows] == list(range(193)),
            "all 193 ordered identities must be present exactly once")
    references = {(row["label"], row["name"]): row for row in reference["tests"]}
    require(len(references) == 193, "official reference identity set is incomplete")
    host_count = 0
    for index, (row, (label, name, original)) in enumerate(zip(rows, corpus)):
        require((row.get("label"), row.get("name")) == (label, name), "case identity changed at " + str(index))
        adapted, receipt = compare.ORACLE.adapt_header(original)
        require(row.get("adaptation") == receipt and receipt["body_bytes_identical"] is True,
                "case body/header receipt changed at " + str(index))
        source_reference = references[(label, name)]
        require(all(source_reference["adaptation"].get(key) == receipt[key] for key in
                ("original_sha256", "adapted_sha256", "original_body_sha256",
                 "adapted_body_sha256", "body_bytes_identical")),
                "case adaptation differs from official reference")
        require(row.get("official_provenance_matches") is True
                and row.get("official") == source_reference["official"],
                "official verdict or provenance differs")
        observed = row.get("pskernel", {})
        require(row.get("classification") == compare.classify(row["official"], observed),
                "case classification differs from unchanged policy")
        if observed.get("verdict") in ("accepted", "rejected", "malformed", "unsupported",
                                       "resource_exhausted", "internal_error"):
            # Host resource errors have no generated semantic envelope.
            if observed.get("stage") not in ("host-memory", "host-heap"):
                require(observed.get("sourceSha256") == digest(adapted) and observed.get("fuel") == "4096",
                        "generated envelope source or fixed fuel differs")
        host, launch = observed.get("host", {}), observed.get("host", {}).get("launch", {})
        valid = (host.get("hardLimitVerified") is True and host.get("cleanupOk") is True
                 and host.get("testOnly") is False and host.get("limitBytes") == LIMIT
                 and host.get("wallSeconds") == DEADLINE and launch.get("memoryMax") == LIMIT
                 and launch.get("swapMax") == 0 and launch.get("oomGroup") == 1
                 and launch.get("groups") == [] and launch.get("path") == ""
                 and launch.get("uid") == os.getuid() and launch.get("gid") == os.getgid()
                 and launch.get("mode") == "arena")
        host_count += int(valid)
    counts = dict(sorted(Counter(row["classification"] for row in rows).items()))
    verdicts = dict(sorted(Counter(row.get("pskernel", {}).get("verdict", "not_run") for row in rows).items()))
    matches = sum(row["classification"].startswith("matched_") for row in rows)
    require(report.get("counts") == counts and report.get("pskernel_verdicts") == verdicts
            and report.get("actual_matched_cases") == matches, "summary does not equal all recorded cases")
    official_controls = reference.get("controls", [])
    controls_valid = (len(official_controls) == 2
                      and {row.get("expected") for row in official_controls} == {"accepted", "rejected"}
                      and all(row.get("expected") == row.get("verdict") for row in official_controls))
    require(controls_valid and report.get("official_controls_valid") is True,
            "official positive/negative controls incomplete")
    require(report.get("all_case_host_limits_verified") is (host_count == 193),
            "reported versus independently inspected host-limit receipts differ")
    complete = matches == 193 and host_count == 193
    require(report.get("arena_comparison_complete") is complete and compare_code == (0 if complete else 1),
            "comparison exit status and complete gate disagree")
    return {"records": 193, "verified_production_host_limits": host_count,
            "all_body_receipts_preserved": True, "all_classifications_preserved": True,
            "matches": matches, "counts": counts, "pskernel_verdicts": verdicts,
            "arena_comparison_complete": complete}


def write_summary(out, receipt):
    verdict = "PASS" if receipt.get("arena_comparison_complete") is True else "FAIL / incomplete"
    lines = [
        "# Artifact-based full Arena comparison under the production host cap", "",
        "Kernel source: " + KERNEL_SOURCE + ". Host implementation: " + HOST_SOURCE + ".",
        "Generated artifact: run" + str(KERNEL_RUN) + "/artifact" + str(KERNEL_ARTIFACT) + ".", "",
        "Qualification result: **" + verdict + "**. This run checks an existing qualified artifact "
        "with the frozen host implementation; it does not build or qualify the current integration tree.", "",
        "Every applicable body is preserved. The comparison uses 60 seconds per case, 2 workers, "
        "fuel 4096, memory.max 2147483648, swap 0 and empty runtime PATH. The hard cap covers charged "
        "memory of the isolated checker/time/descendants. GNU time RSS and sampled Node VmHWM remain "
        "separate metrics. The historical metadata header is adapted; this is not a native 4.35 re-export.", "",
    ]
    result = receipt.get("comparison_validation")
    if result:
        lines.extend(["## Complete 193-case accounting", "",
                      "| Field | Result |", "| --- | --- |",
                      f"| Recorded identities | {result['records']} |",
                      f"| Verified production host-limit receipts | {result['verified_production_host_limits']} |",
                      f"| Matching outcomes | {result['matches']} |"])
        lines.extend("| " + name + " | " + str(count) + " |" for name, count in result["counts"].items())
        lines.extend(["", "Matching outcomes include their separately named kernel, metadata and transport "
                      "classes. Unsafe/partial agreements remain a separate contract class. Host timeouts, "
                      "cgroup/heap exhaustion, kernel fuel exhaustion and unsupported cases are never passes.", ""])
    if receipt.get("failure"):
        lines.extend(["## Driver or control failure", "", receipt["failure"], ""])
    lines.extend(["Full per-case records, source/body/artifact hashes, exact typed failures, memory events, "
                  "progress and logs are retained. Compact receipts for every case are printed in the job log. "
                  "No global soundness, complete V2 replacement or universal speedup claim follows.", ""])
    (out / "summary.md").write_text("\n".join(lines), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtimes", type=pathlib.Path, required=True)
    parser.add_argument("--host-source", type=pathlib.Path, required=True)
    parser.add_argument("--auth-source", type=pathlib.Path, required=True)
    parser.add_argument("--kernel-source", type=pathlib.Path, required=True)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    runtimes, host_root, auth_root, kernel_root, archive = (
        value.resolve(strict=True) for value in
        (args.runtimes, args.host_source, args.auth_source, args.kernel_source, args.archive))
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    source_sha = os.environ.get("GITHUB_SHA", "")
    require(re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None, "missing exact workflow source SHA")
    receipt = {
        "format": "psc1-artifact-arena-hardcap-v1", "workflow_source_sha": source_sha,
        "workflow_run": os.environ.get("GITHUB_SERVER_URL", "https://github.com") + "/"
                        + os.environ.get("GITHUB_REPOSITORY", "dwijayuda/pskernel")
                        + "/actions/runs/" + os.environ.get("GITHUB_RUN_ID", "unknown"),
        "kernel_source_sha": KERNEL_SOURCE, "host_source_sha": HOST_SOURCE,
        "authenticator_source_sha": AUTH_SOURCE,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "compiler_reexecuted": False, "canonical_rechecked": False,
        "official_reference_reexecuted": False, "full_v2_replacement_established": False,
        "current_integration_kernel_qualified": False, "collection_complete": False,
        "kernel_entry": "psKernelV1RunDag",
        "dag_scope": "transitional DAG checking with acknowledged whole-operation V1 fallbacks",
        "arena_comparison_complete": False,
        "kernel_fuel": 4096, "host_seconds_per_case": DEADLINE, "host_workers": WORKERS,
        "production_cgroup_memory_limit_bytes": LIMIT, "production_swap_limit_bytes": 0,
        "runtime_path_empty": True,
        "memory_scope": "isolated cgroup charged memory; separate process RSS and Node VmHWM",
    }
    write_report(out, receipt)
    exit_code = 1
    try:
        receipt["source_files"] = {
            "harness": verify_checkout(HERE.parent.parent, source_sha, (
                "psc1/scripts/pskernel-artifact-arena-hardcap.py",
                ".github/workflows/psc1-pskernel-artifact-arena-hardcap.yml")),
            "host": verify_checkout(host_root, HOST_SOURCE, HOST_FILES),
            "authenticator": verify_checkout(auth_root, AUTH_SOURCE, (AUTH_FILE,)),
            "kernel": verify_checkout(kernel_root, KERNEL_SOURCE, (*SHARED_FILES, "psc1/lean-toolchain")),
        }
        require((kernel_root / "psc1/lean-toolchain").read_text().strip() == "leanprover/lean4:v4.35.0",
                "source Lean toolchain differs")
        for relative in SHARED_FILES:
            require((host_root / relative).read_bytes() == (kernel_root / relative).read_bytes(),
                    "Name source and frozen host have different original replay/oracle: " + relative)
        artifacts = module("artifact_arena_auth", auth_root / AUTH_FILE)
        authentication = authenticate(runtimes, artifacts)
        receipt["authentication"] = authentication
        compare = module("artifact_arena_compare", host_root / "psc1/scripts/pskernel-arena435-compare.py")
        require(compare.HOST.LIMIT == LIMIT and compare.ORACLE.EXPECTED_CASES == 193,
                "frozen host or corpus policy differs")
        corpus = compare.ORACLE.read_archive(archive)
        reference = read_json(runtimes / "official-reference.json")
        require(len(corpus) == len(reference["tests"]) == 193
                and reference.get("official_reference_complete") is True
                and reference.get("archive_sha256") == compare.ORACLE.ARCHIVE_SHA256
                and reference.get("target_lean") == compare.ORACLE.TARGET
                and reference.get("native_435_reexport") is False,
                "authenticated complete reference and corpus differ")
        receipt["archive_sha256"] = digest(archive.read_bytes())
        receipt["official_reference_sha256"] = digest((runtimes / "official-reference.json").read_bytes())
        raw = (runtimes / "candidate.zip").read_bytes()
        restored = artifacts.restore_bundle(raw, out / "runtime-artifact.zip", out / "runtime",
                                             KERNEL_SOURCE, KERNEL_RUN, baseline=False)
        require(restored["manifest_sha256"] == authentication["candidate"]["manifest_sha256"]
                and restored["files"] == authentication["candidate"]["files"]
                and restored["kernel_sha256"] == KERNEL_JS_SHA256,
                "restored kernel/provider bytes differ from authenticated manifest")
        kernel = out / "runtime/kernel.js"
        require(kernel.stat().st_size == KERNEL_JS_BYTES, "generated kernel length differs")
        receipt["restored_runtime"] = restored
        node_path = shutil.which("node")
        require(node_path is not None, "Node required")
        node = pathlib.Path(node_path).resolve(strict=True)
        version = subprocess.check_output([str(node), "--version"], env=RUNTIME_ENV, text=True).strip()
        require(re.fullmatch(r"v22\.[0-9]+\.[0-9]+", version) is not None, "Node major differs from 22")
        receipt["node"] = {"version": version, "executable_sha256": digest(node.read_bytes())}
        write_report(out, receipt)
        run_host_controls(host_root, node, out, receipt)
        replay_controls(compare, kernel, kernel_root, node, out, receipt)
        code = run_comparison(host_root / "psc1/scripts/pskernel-arena435-compare.py", node, kernel,
                              kernel_root / "psc1/scripts/pskernel-arena-replay.mjs", archive,
                              runtimes / "official-reference.json", out)
        receipt["unchanged_comparison_exit_code"] = code
        report = read_json(out / "comparison/report.json")
        report_bytes = (out / "comparison/report.json").read_bytes()
        receipt["comparison_report"] = {"path": "comparison/report.json", "bytes": len(report_bytes),
                                        "sha256": digest(report_bytes)}
        records = report.get("tests", [])
        require(isinstance(records, list) and len(records) <= 193, "invalid per-case report collection")
        for row in records:
            compact = json.dumps(compact_case(row), ensure_ascii=False, allow_nan=False, separators=(",", ":"))
            require(len(compact.encode("utf-8")) <= 64 * 1024, "compact per-case receipt exceeds 64 KiB")
            print("PSC1_ARTIFACT_ARENA_CASE " + compact, flush=True)
        validated = validate_comparison(report, compare, corpus, reference, code)
        receipt["comparison_validation"] = validated
        receipt["collection_complete"] = validated["records"] == 193 and validated["verified_production_host_limits"] == 193
        receipt["arena_comparison_complete"] = validated["arena_comparison_complete"]
        exit_code = 0 if receipt["arena_comparison_complete"] else 1
    except (ValueError, TypeError, KeyError, OSError, subprocess.SubprocessError) as error:
        receipt["failure"] = type(error).__name__ + ": " + str(error)
    finally:
        receipt["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        write_report(out, receipt)
        write_summary(out, receipt)
        output_digests(out)
    data = (out / "receipt.json").read_bytes()
    print("PSC1_ARTIFACT_ARENA_RECEIPT " + json.dumps({
        "workflow_source_sha": source_sha, "kernel_source_sha": KERNEL_SOURCE,
        "host_source_sha": HOST_SOURCE, "bytes": len(data), "sha256": digest(data),
        "collection_complete": receipt["collection_complete"],
        "arena_comparison_complete": receipt["arena_comparison_complete"],
        "comparison": receipt.get("comparison_validation"), "failure": receipt.get("failure")
    }, allow_nan=False), flush=True)
    print("PSC1_ARTIFACT_ARENA_QUALIFICATION: " + ("PASS" if exit_code == 0 else "FAIL"), flush=True)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
