#!/usr/bin/env python3
"""Same-runner artifact comparison; collection does not establish kernel parity."""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import hashlib
import importlib.util
import json
import math
import os
import pathlib
import re
import shutil
import signal
import statistics
import subprocess
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
ABBA = ("baseline", "candidate", "candidate", "baseline")
CASES = (("chain", 8, 3), ("chain", 32, 2), ("metadata", 8, 3),
         ("metadata", 32, 2), ("binder", 8, 2), ("binder", 32, 1))
AUTHENTIC = (("good", "perf/repeated-subproblem.ndjson"),
             ("good", "perf/church-numerals.ndjson"),
             ("good", "init-prelude.ndjson"),
             ("bad", "bugs/proj-of-stuck-prop.ndjson"))
UNCHANGED = ("scripts/pskernel-expr-v2-admission-bench.mjs",
             "scripts/pskernel-arena-replay.mjs",
             "scripts/pskernel-arena-replay-controls.mjs",
             "scripts/pskernel-arena435-oracle.py",
             "scripts/pskernel-arena435-compare.py", "lean-toolchain",
             "packages/pskernel-core/src/Ps/KernelCore/Checker/ResourcePolicy.lean")
DEADLINE = 60
OLD_SPACE_MIB = 2048
SAMPLE_PREFIX = "PSC1_ADMISSION_SAMPLE "


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def module(name: str, path: pathlib.Path):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, "cannot load pinned harness")
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


ARTIFACTS = module("paired_artifacts", HERE / "pskernel-paired-artifacts.py")


def read_json(path: pathlib.Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), "expected JSON object: " + str(path))
    return value


def finite(value, *, nonnegative: bool = True) -> bool:
    return (type(value) in (int, float) and math.isfinite(value)
            and (not nonnegative or value >= 0))


def runtime_environment(work: pathlib.Path) -> dict:
    scratch = work / "tmp"
    scratch.mkdir(exist_ok=True)
    return {"PATH": "", "LC_ALL": "C", "TZ": "UTC", "TMPDIR": str(scratch)}


@contextmanager
def only_runtime_environment(work: pathlib.Path):
    previous = dict(os.environ)
    try:
        os.environ.clear()
        os.environ.update(runtime_environment(work))
        yield
    finally:
        os.environ.clear()
        os.environ.update(previous)


def time_metrics(path: pathlib.Path) -> dict:
    if not path.exists():
        return {}
    contents = path.read_text(encoding="utf-8")
    result = {}
    for label, key, cast in (
        ("Maximum resident set size \\(kbytes\\)", "process_peak_rss_kib", int),
        ("User time \\(seconds\\)", "process_cpu_user_seconds", float),
        ("System time \\(seconds\\)", "process_cpu_system_seconds", float),
        ("Major \\(requiring I/O\\) page faults", "process_major_page_faults", int),
    ):
        match = re.search(label + r":\s*([0-9]+(?:\.[0-9]+)?)", contents)
        if match:
            result[key] = cast(match.group(1))
    return result


def process(command: list[str], work: pathlib.Path, logs: pathlib.Path, stem: str) -> tuple[dict, str]:
    stdout_path, stderr_path, time_path = (logs / (stem + suffix)
                                         for suffix in ("-stdout.txt", "-stderr.txt", "-time.txt"))
    launched = time.monotonic()
    timed_out = False
    try:
        child = subprocess.Popen(["/usr/bin/time", "-v", "-o", str(time_path), *command],
                                 cwd=work, env=runtime_environment(work), start_new_session=True,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 text=True, encoding="utf-8", errors="replace")
        try:
            stdout, stderr = child.communicate(timeout=DEADLINE)
        except subprocess.TimeoutExpired:
            timed_out = True
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            stdout, stderr = child.communicate()
        result = {"returncode": child.returncode,
                  "status": "timeout" if timed_out else ("completed" if child.returncode == 0 else "process_failure")}
    except OSError as error:
        stdout, stderr = "", str(error)
        result = {"returncode": None, "status": "launch_error"}
    stdout_path.write_text(stdout, encoding="utf-8")
    stderr_path.write_text(stderr, encoding="utf-8")
    result.update(elapsed_seconds=time.monotonic() - launched,
                  deadline_seconds=DEADLINE, old_space_limit_mib=OLD_SPACE_MIB,
                  stdout=stdout_path.name, stderr=stderr_path.name, time_log=time_path.name)
    result.update(time_metrics(time_path))
    if re.search(r"FATAL ERROR:.*JavaScript heap out of memory", stderr):
        result["host_heap_exhausted"] = True
    return result, stdout


def verify_sources(baseline: pathlib.Path, candidate: pathlib.Path, authentication: dict) -> dict:
    git = shutil.which("git")
    require(git is not None, "git is required only to authenticate the two source checkouts")
    for label, source in (("baseline", baseline), ("candidate", candidate)):
        actual = subprocess.check_output([git, "-C", str(source), "rev-parse", "HEAD"],
                                         text=True, encoding="utf-8").strip()
        require(actual == authentication[label]["source_sha"], "checkout source identity differs: " + label)
    unchanged = {}
    for relative in UNCHANGED:
        old, new = (source / relative for source in (baseline, candidate))
        old_bytes, new_bytes = old.read_bytes(), new.read_bytes()
        require(old_bytes == new_bytes, "comparison requires the unchanged harness/policy: " + relative)
        unchanged[relative] = digest(old_bytes)
    require((baseline / "lean-toolchain").read_text().strip() == "leanprover/lean4:v4.35.0",
            "source toolchain differs")
    prefix = pathlib.Path("packages/pskernel-core/src/Ps/KernelCore")
    identities = sorted({path.relative_to(source).as_posix()
                         for source in (baseline, candidate) for path in (source / prefix).rglob("*.lean")})
    changes = []
    for relative in identities:
        old, new = (source / relative for source in (baseline, candidate))
        before = digest(old.read_bytes()) if old.is_file() else None
        after = digest(new.read_bytes()) if new.is_file() else None
        if before != after:
            changes.append({"path": relative, "baseline_sha256": before, "candidate_sha256": after})
    require(bool(changes), "no kernel source difference to measure")
    return {"unchanged_harness_and_policy": unchanged, "changed_kernel_files": changes,
            "attribution": "entire difference between exact source revisions, not a single-function causal estimate"}


def restore_detached(runtimes: pathlib.Path, authentication: dict, baseline_source: pathlib.Path,
                     work: pathlib.Path) -> dict[str, pathlib.Path]:
    result = {}
    for label in ("baseline", "candidate"):
        source, destination = runtimes / label, work / label
        manifest_bytes = (source / "artifacts.json").read_bytes()
        require(digest(manifest_bytes) == authentication[label]["manifest_sha256"],
                "authenticated manifest changed before measurement")
        manifest = json.loads(manifest_bytes)
        require(manifest["sourceSha"] == authentication[label]["source_sha"]
                and manifest["files"] == authentication[label]["files"],
                "runtime manifest receipt differs")
        for record in manifest["files"]:
            require(record["path"].startswith(ARTIFACTS.PROVIDER_PREFIX), "invalid manifest path prefix")
            relative = record["path"][len(ARTIFACTS.PROVIDER_PREFIX):]
            require(relative in ARTIFACTS.BUNDLE_FILES, "unexpected runtime dependency")
            data = (source / relative).read_bytes()
            require(len(data) == record["bytes"] and digest(data) == record["sha256"],
                    "runtime dependency changed before measurement: " + relative)
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        require(digest((destination / "kernel.js").read_bytes()) == authentication[label]["kernel_sha256"],
                "runtime kernel changed before measurement")
        (destination / "artifacts.json").write_bytes(manifest_bytes)
        for name in ("pskernel-expr-v2-admission-bench.mjs", "pskernel-arena-replay.mjs",
                     "pskernel-arena-replay-controls.mjs"):
            shutil.copyfile(baseline_source / "scripts" / name, destination / "scripts" / name)
        result[label] = destination
    return result


def validate_sample(sample: dict, variant: str, shape: str, count: int, calls: int) -> None:
    require(sample.get("variant") == variant and sample.get("shape") == shape
            and sample.get("declarations_per_batch") == count and sample.get("calls") == calls
            and sample.get("checksum") == calls * count and sample.get("checked_declarations") == calls * count
            and sample.get("all_correct") is True and sample.get("negative_type_mismatch") is True
            and sample.get("fuel") == 4096 and sample.get("input_pool") == 5,
            "full-admission worker identity/checks differ")
    diagnostic = sample.get("direct_dag_admission_diagnostic")
    if variant == "dag":
        require(isinstance(diagnostic, dict) and diagnostic.get("positive_direct_attempts") == count
                and diagnostic.get("checked_original_id_entries") == count
                and diagnostic.get("exact_direct_type_mismatch") is True
                and diagnostic.get("dispatcher_environment_parity") is True
                and diagnostic.get("timed_path_instrumented") is False
                and sample.get("direct_dag_admission_path_measured") is False,
                "mandatory untimed DAG admission diagnostics differ")
    else:
        require(diagnostic is None, "unexpected legacy DAG diagnostics")
    for name in ("admission_ms", "independent_assertion_ms", "checked_wall_ms",
                 "cold_admission_ms", "cold_assertion_ms", "input_construction_ms",
                 "heap_before_bytes", "heap_after_gc_bytes", "peak_rss_kib"):
        require(finite(sample.get(name)), "invalid admission measurement: " + name)
    for name in ("input_construction_heap_delta_bytes", "input_construction_rss_delta_bytes",
                 "retained_heap_delta_bytes"):
        require(finite(sample.get(name), nonnegative=False), "invalid signed heap/RSS measurement: " + name)


def admission_observation(node: pathlib.Path, work: pathlib.Path, logs: pathlib.Path, index: int,
                          label: str, variant: str, shape: str, count: int, calls: int) -> dict:
    record, stdout = process([str(node), "--max-old-space-size=2048", "--expose-gc",
                              str(work / "scripts/pskernel-expr-v2-admission-bench.mjs"),
                              str(work / "kernel.js"), "worker", variant, shape, str(count), str(calls)],
                             work, logs, f"admission-{index:03d}")
    record.update(index=index, source=label, variant=variant, shape=shape,
                  declarations_per_batch=count, calls=calls, valid=False)
    if record["status"] != "completed":
        return record
    try:
        samples = [line[len(SAMPLE_PREFIX):] for line in stdout.splitlines() if line.startswith(SAMPLE_PREFIX)]
        require(len(samples) == 1, "missing or duplicate admission sample")
        sample = json.loads(samples[0])
        require(isinstance(sample, dict), "admission sample is not an object")
        validate_sample(sample, variant, shape, count, calls)
        record.update(valid=True, sample=sample)
    except (ValueError, TypeError, KeyError, OverflowError) as error:
        record.update(status="protocol_failure", reason=str(error))
    return record


def admission_summary(rows: list[dict]) -> list[dict]:
    result = []
    metrics = {
        "warm_admission_ms_per_batch": lambda row: row["sample"]["admission_ms"] / row["calls"],
        "cold_admission_ms": lambda row: row["sample"]["cold_admission_ms"],
        "input_construction_ms": lambda row: row["sample"]["input_construction_ms"],
        "independent_assertion_ms_per_batch": lambda row: row["sample"]["independent_assertion_ms"] / row["calls"],
        "pre_diagnostic_peak_rss_kib": lambda row: row["sample"]["peak_rss_kib"],
        "retained_heap_delta_bytes": lambda row: row["sample"]["retained_heap_delta_bytes"],
        "process_elapsed_seconds": lambda row: row["elapsed_seconds"],
        "process_peak_rss_kib": lambda row: row.get("process_peak_rss_kib"),
        "process_cpu_user_seconds": lambda row: row.get("process_cpu_user_seconds"),
        "process_cpu_system_seconds": lambda row: row.get("process_cpu_system_seconds"),
    }
    for shape, count, calls in CASES:
        for variant in ("legacy", "dag"):
            selected = [row for row in rows if row["shape"] == shape
                        and row["declarations_per_batch"] == count and row["variant"] == variant]
            by_source = {label: [row for row in selected if row["source"] == label] for label in ("baseline", "candidate")}
            complete = (len(selected) == 4 and all(len(group) == 2 for group in by_source.values())
                        and all(row["valid"] for row in selected))
            entry = {"shape": shape, "declarations_per_batch": count, "calls": calls,
                     "variant": variant, "complete": complete, "observations": [row["index"] for row in selected],
                     "metric_means": {}, "baseline_over_candidate_latency_ratio": None}
            if complete:
                for metric, extract in metrics.items():
                    values = {label: [extract(row) for row in group] for label, group in by_source.items()}
                    if all(all(finite(value, nonnegative=False) for value in group) for group in values.values()):
                        entry["metric_means"][metric] = {label: statistics.fmean(group) for label, group in values.items()}
                warm = entry["metric_means"]["warm_admission_ms_per_batch"]
                if warm["candidate"] > 0:
                    entry["baseline_over_candidate_latency_ratio"] = warm["baseline"] / warm["candidate"]
            result.append(entry)
    return result


def authentic_summary(rows: list[dict]) -> list[dict]:
    result = []
    for label, name in AUTHENTIC:
        selected = [row for row in rows if row["label"] == label and row["name"] == name]
        groups = {source: [row for row in selected if row["source"] == source] for source in ("baseline", "candidate")}
        eligible = (len(selected) == 4 and all(len(group) == 2 for group in groups.values())
                    and all(row["classification"] in ("matched_acceptance", "matched_kernel_rejection")
                            for row in selected)
                    and len({row["classification"] for row in selected}) == 1)
        entry = {"label": label, "name": name, "observations": [row["index"] for row in selected],
                 "all_four_official_matching_kernel_outcomes": eligible,
                 "classifications": {source: [row["classification"] for row in group]
                                     for source, group in groups.items()},
                 "mean_elapsed_seconds": None, "mean_peak_rss_kib": None,
                 "baseline_over_candidate_elapsed_ratio": None}
        if eligible:
            elapsed = {source: statistics.fmean(row["pskernel"]["elapsed_seconds"] for row in group)
                       for source, group in groups.items()}
            entry["mean_elapsed_seconds"] = elapsed
            if elapsed["candidate"] > 0:
                entry["baseline_over_candidate_elapsed_ratio"] = elapsed["baseline"] / elapsed["candidate"]
            if all(finite(row["pskernel"].get("peak_rss_kib")) for row in selected):
                entry["mean_peak_rss_kib"] = {
                    source: statistics.fmean(row["pskernel"]["peak_rss_kib"] for row in group)
                    for source, group in groups.items()}
        result.append(entry)
    return result


def write_report(out: pathlib.Path, report: dict) -> None:
    temporary = out / "report.json.tmp"
    temporary.write_text(json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
    temporary.replace(out / "report.json")


def write_summary(out: pathlib.Path, report: dict) -> None:
    lines = [
        "# Same-runner generated-kernel comparison", "",
        "Baseline: " + report["authentication"]["baseline"]["source_sha"] + ".",
        "Candidate: " + report["authentication"]["candidate"]["source_sha"] + ".", "",
        "Both immutable generated bundles run with the same Node executable, sequential ABBA source order, "
        "fresh processes and empty PATH. Each process has a 60-second deadline and a 2048 MiB V8 old-space "
        "limit. This is not a hard RSS cap; measured process RSS includes memory outside old space.", "",
        "The complete-admission worker includes real independent acceptance/refusal checks. Each timed "
        "batch starts a fresh session. The worker's untimed direct-DAG diagnostic is retained and is not "
        "included in its admission timer. Whole-process RSS and elapsed time include all setup and diagnostics.", "",
        "The legacy entry is psKernelV1AdmitDeclaration. The DAG-batch and authentic replay entry is "
        "psKernelV1RunDag, which uses the transitional DAG checker with acknowledged whole-operation "
        "V1 fallbacks. Names alone do not identify a separate complete V1 or V2 architecture.", "",
        "## Complete public admission", "",
        "| Fixture | Representation | Warm ms/batch baseline | Candidate | Baseline / candidate | Cold ms baseline / candidate | Process peak RSS KiB baseline / candidate | Retained heap delta bytes baseline / candidate |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in report["admission_summary"]:
        if not row["complete"]:
            lines.append(f"| {row['shape']} {row['declarations_per_batch']} | {row['variant']} | incomplete | incomplete | unavailable | unavailable | unavailable | unavailable |")
            continue
        metrics = row["metric_means"]
        warm = metrics["warm_admission_ms_per_batch"]
        def pair(key: str) -> str:
            values = metrics.get(key)
            return "unavailable" if values is None else f"{values['baseline']:.3f} / {values['candidate']:.3f}"
        ratio = row["baseline_over_candidate_latency_ratio"]
        ratio_text = "unavailable" if ratio is None else f"{ratio:.3f}"
        lines.append(f"| {row['shape']} {row['declarations_per_batch']} | {row['variant']} "
                     f"| {warm['baseline']:.3f} | {warm['candidate']:.3f} | {ratio_text} "
                     f"| {pair('cold_admission_ms')} | {pair('process_peak_rss_kib')} "
                     f"| {pair('retained_heap_delta_bytes')} |")
    lines.extend(["", "## Four authenticated Arena bodies", "",
                  "The existing header adapter and full replay/metadata-validation protocol are unchanged. "
                  "The immutable official reference covers all 193 bodies, but this performance subset "
                  "contains only the four listed identities. A timeout or resource error is incomplete and "
                  "never enters an accepted/rejected latency ratio.", "",
                  "| Case | Baseline classifications | Candidate classifications | Baseline / candidate elapsed ratio |",
                  "| --- | --- | --- | ---: |"])
    for row in report["authentic_summary"]:
        ratio = row["baseline_over_candidate_elapsed_ratio"]
        lines.append("| " + row["label"] + "/" + row["name"] + " | "
                     + ", ".join(row["classifications"]["baseline"]) + " | "
                     + ", ".join(row["classifications"]["candidate"]) + " | "
                     + ("unavailable" if ratio is None else f"{ratio:.3f}") + " |")
    lines.extend(["", "All individual observations, construction, retained heap after GC, CPU/RSS measurements, exact body hashes, "
                  "source-file differences, controls, errors and artifact identities are in report.json "
                  "and the retained logs. Two samples per side are descriptive measurements, without a "
                  "statistical significance or universal speedup claim. This collection does not establish "
                  "full V2 replacement, a global soundness proof, canonical-source requalification, or "
                  "full 193-case conformance.", ""])
    (out / "summary.md").write_text("\n".join(lines), encoding="utf-8")


def output_digests(out: pathlib.Path) -> None:
    lines = []
    for path in sorted(out.rglob("*")):
        if path.is_file() and path.name != "outputs.sha256":
            lines.append(digest(path.read_bytes()) + "  " + path.relative_to(out).as_posix())
    (out / "outputs.sha256").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtimes", type=pathlib.Path, required=True)
    parser.add_argument("--baseline-source", type=pathlib.Path, required=True,
                        help="exact baseline checkout's psc1 directory")
    parser.add_argument("--candidate-source", type=pathlib.Path, required=True,
                        help="exact candidate checkout's psc1 directory")
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    runtimes, baseline_source, candidate_source, archive = (
        path.resolve(strict=True) for path in
        (args.runtimes, args.baseline_source, args.candidate_source, args.archive))
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    require(not (out / "report.json").exists(), "refusing to overwrite an existing performance report")
    authentication = read_json(runtimes / "authentication.json")
    require(authentication.get("format") == "psc1-paired-performance-artifacts-v1"
            and authentication.get("repository") == ARTIFACTS.REPOSITORY
            and authentication["baseline"]["source_sha"] == ARTIFACTS.BASELINE_SOURCE
            and authentication["baseline"]["producer_run"] == ARTIFACTS.BASELINE_RUN
            and authentication["baseline"]["artifact_id"] == ARTIFACTS.BASELINE_ARTIFACT
            and authentication["baseline"]["artifact_zip_sha256"] == ARTIFACTS.BASELINE_ZIP_SHA256
            and authentication["baseline"]["kernel_sha256"] == ARTIFACTS.BASELINE_KERNEL_SHA256
            and authentication.get("compiler_reexecuted") is False
            and authentication.get("canonical_rechecked") is False
            and authentication.get("new_kernel_qualification_established") is False,
            "missing or different artifact authentication")
    for label in ("baseline", "candidate"):
        require(digest((runtimes / (label + ".zip")).read_bytes()) ==
                authentication[label]["artifact_zip_sha256"], "runtime ZIP changed after authentication")
        require({job["name"] for job in authentication[label]["required_jobs"]} ==
                {"native-dag-integration", "generated-dag-integration"}
                and all(job["conclusion"] == "success" for job in authentication[label]["required_jobs"]),
                "producer integration qualification receipt differs")
    require(digest((runtimes / "official-reference.zip").read_bytes()) == ARTIFACTS.REFERENCE_ZIP_SHA256
            and digest((runtimes / "official-reference.json").read_bytes()) ==
            authentication["official_reference"]["report_sha256"],
            "official reference changed after authentication")
    sources = verify_sources(baseline_source, candidate_source, authentication)
    compare = module("paired_arena_compare", baseline_source / "scripts/pskernel-arena435-compare.py")
    corpus = compare.ORACLE.read_archive(archive)
    reference = read_json(runtimes / "official-reference.json")
    references = {(row["label"], row["name"]): row for row in reference["tests"]}
    require(len(corpus) == len(reference["tests"]) == len(references) == 193
            and set(references) == {(label, name) for label, name, _ in corpus},
            "official reference and authenticated archive identities differ")
    lookup = {(label, name): (index, raw) for index, (label, name, raw) in enumerate(corpus)}
    require(set(AUTHENTIC) <= set(lookup), "fixed authentic subset is missing from archive")
    selected = []
    inputs = out / "inputs"
    inputs.mkdir()
    for label, name in AUTHENTIC:
        index, original = lookup[(label, name)]
        adapted, receipt = compare.ORACLE.adapt_header(original)
        require(all(references[(label, name)]["adaptation"].get(field) == receipt[field] for field in
                    ("original_sha256", "adapted_sha256", "original_body_sha256",
                     "adapted_body_sha256", "body_bytes_identical")),
                "authentic body/header receipt differs from official reference: " + name)
        path = inputs / f"case-{index:03d}.ndjson"
        path.write_bytes(adapted)
        selected.append({"label": label, "name": name, "corpus_index": index, "adaptation": receipt,
                         "official": references[(label, name)]["official"], "path": path})
    node_path = shutil.which("node")
    require(node_path is not None and pathlib.Path("/usr/bin/time").is_file(), "Node and GNU time are required")
    node = pathlib.Path(node_path).resolve(strict=True)
    node_version = subprocess.check_output([str(node), "--version"], text=True).strip()
    require(re.fullmatch(r"v22\.[0-9]+\.[0-9]+", node_version) is not None, "Node major differs from 22")
    report = {
        "format": "psc1-paired-performance-v1", "workflow_source_sha": os.environ.get("GITHUB_SHA"),
        "workflow_run": os.environ.get("GITHUB_SERVER_URL", "https://github.com") + "/"
                        + os.environ.get("GITHUB_REPOSITORY", ARTIFACTS.REPOSITORY)
                        + "/actions/runs/" + os.environ.get("GITHUB_RUN_ID", "unknown"),
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "authentication": authentication, "source_comparison": sources,
        "harness_sha256": digest(pathlib.Path(__file__).read_bytes()),
        "node_version": node_version, "node_executable_sha256": digest(node.read_bytes()),
        "host_cpu_models": sorted({line.partition(":")[2].strip() for line in
                                  pathlib.Path("/proc/cpuinfo").read_text().splitlines()
                                  if line.startswith("model name")}),
        "host_workers": 1, "source_order_per_group": list(ABBA), "runtime_path_empty": True,
        "runtime_working_directory_contains_no_Lean_or_repository_sources": True,
        "kernel_fuel": 4096, "host_deadline_seconds_per_process": DEADLINE,
        "v8_old_space_limit_mib": OLD_SPACE_MIB, "hard_rss_limit_enforced": False,
        "rss_scope": "measured KiB; V8 old-space limit is not a total-process memory limit",
        "archive_sha256": compare.ORACLE.ARCHIVE_SHA256, "target_lean": compare.ORACLE.TARGET,
        "native_435_reexport": False, "declaration_body_bytes_unchanged": True,
        "subset_identities": [{"label": label, "name": name} for label, name in AUTHENTIC],
        "corpus_cases_not_measured": 193 - len(AUTHENTIC), "all_193_conformance_established": False,
        "new_kernel_qualification_established": False, "full_v2_replacement_established": False,
        "entry_points": {"legacy": "psKernelV1AdmitDeclaration", "dag": "psKernelV1RunDag",
                         "authentic": "psKernelV1RunDag"},
        "dag_entry_scope": "transitional DAG checker with acknowledged whole-operation V1 fallbacks",
        "comparison_scope": "whole source revisions; old/new legacy and DAG admission measured separately",
        "cold_scope": "first valid batch after mandatory negative sentinel; process setup recorded separately",
        "warm_scope": "five worker warmups; every timed batch still has a fresh semantic session",
        "controls": [], "admission_observations": [], "authentic_observations": [],
        "admission_summary": [], "authentic_summary": [], "collection_complete": False,
    }
    write_report(out, report)
    logs = {phase: out / ("logs-" + phase) for phase in ("controls", "admission", "authentic")}
    for path in logs.values():
        path.mkdir()
    with tempfile.TemporaryDirectory(prefix="psc1-paired-detached-") as temporary:
        work = pathlib.Path(temporary)
        bundles = restore_detached(runtimes, authentication, baseline_source, work)
        for label in ("baseline", "candidate"):
            bundle = bundles[label]
            observed, stdout = process([str(node), "--max-old-space-size=2048",
                                        str(bundle / "scripts/pskernel-arena-replay-controls.mjs"),
                                        str(bundle / "kernel.js")],
                                       bundle, logs["controls"], label)
            markers = [line for line in stdout.splitlines()
                       if line.startswith("PSC1_ARENA_REPLAY_CONTROLS:")]
            valid = (observed["status"] == "completed"
                     and markers == ["PSC1_ARENA_REPLAY_CONTROLS: PASS count=138"]
                     and len([line for line in stdout.splitlines()
                              if line.startswith("PSC1_ARENA_CONTROL_PASS ")]) == 138)
            report["controls"].append({"source": label, "valid": valid, "expected_assertions": 138, **observed})
            write_report(out, report)
            if not valid:
                report["failure"] = "fresh unchanged replay controls failed: " + label
                write_report(out, report)
                write_summary(out, report)
                output_digests(out)
                print("PSC1_PAIRED_PERFORMANCE_CONTROLS_FAILED " + label, flush=True)
                return 1
        for shape, count, calls in CASES:
            for variant in ("legacy", "dag"):
                for label in ABBA:
                    index = len(report["admission_observations"])
                    observed = admission_observation(node, bundles[label], logs["admission"],
                                                     index, label, variant, shape, count, calls)
                    report["admission_observations"].append(observed)
                    write_report(out, report)
                    print("PSC1_PAIRED_ADMISSION " + json.dumps(
                        {key: observed[key] for key in ("index", "source", "variant", "shape",
                                                       "declarations_per_batch", "status", "valid")}), flush=True)
        for case in selected:
            for label in ABBA:
                index = len(report["authentic_observations"])
                bundle = bundles[label]
                with only_runtime_environment(bundle):
                    observed = compare.process_case(node, bundle / "scripts/pskernel-arena-replay.mjs",
                                                    bundle / "kernel.js", case["path"],
                                                    DEADLINE, logs["authentic"], index)
                observed.update(time_metrics(logs["authentic"] / f"case-{index:03d}-time.txt"))
                row = {key: value for key, value in case.items() if key != "path"}
                row.update(index=index, source=label, pskernel=observed,
                           classification=compare.classify(case["official"], observed))
                report["authentic_observations"].append(row)
                write_report(out, report)
                print("PSC1_PAIRED_AUTHENTIC " + json.dumps(
                    {key: row[key] for key in ("index", "source", "label", "name", "classification")}), flush=True)
    report["admission_summary"] = admission_summary(report["admission_observations"])
    report["authentic_summary"] = authentic_summary(report["authentic_observations"])
    report["all_admission_samples_valid"] = (len(report["admission_observations"]) == 48
                                            and all(row["valid"] for row in report["admission_observations"]))
    forbidden = {"false_accept", "false_reject", "pskernel_driver_error", "pskernel_internal_error"}
    report["unexpected_authentic_failures"] = [
        {"index": row["index"], "source": row["source"], "name": row["name"],
         "classification": row["classification"]} for row in report["authentic_observations"]
        if row["classification"] in forbidden or row["pskernel"].get("invalid_progress_snapshots", 0) != 0]
    report["collection_complete"] = (len(report["controls"]) == 2
                                     and all(row["valid"] for row in report["controls"])
                                     and len(report["admission_observations"]) == 48
                                     and len(report["authentic_observations"]) == 16)
    report["collection_protocol_valid"] = (report["collection_complete"]
                                           and report["all_admission_samples_valid"]
                                           and not report["unexpected_authentic_failures"])
    report["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    write_report(out, report)
    write_summary(out, report)
    output_digests(out)
    print("PSC1_PAIRED_PERFORMANCE_COLLECTION " + json.dumps({
        "complete": report["collection_complete"], "protocol_valid": report["collection_protocol_valid"],
        "admission_samples": len(report["admission_observations"]),
        "authentic_processes": len(report["authentic_observations"]),
        "all_193_conformance_established": False, "hard_rss_limit_enforced": False}), flush=True)
    return 0 if report["collection_protocol_valid"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print("PSC1_PAIRED_PERFORMANCE_DRIVER_ERROR " + type(error).__name__ + ": " + str(error),
              file=sys.stderr, flush=True)
        sys.exit(1)
