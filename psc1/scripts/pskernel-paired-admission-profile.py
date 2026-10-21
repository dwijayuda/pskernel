#!/usr/bin/env python3
"""Eight authenticated admission profiles; separate from ordinary paired timings."""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import time
import importlib.util

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("paired_profile_helpers", HERE / "pskernel-paired-performance.py")
if spec is None or spec.loader is None:
    raise RuntimeError("missing unchanged paired runtime helpers")
PAIR = importlib.util.module_from_spec(spec)
spec.loader.exec_module(PAIR)
ARTIFACTS = PAIR.ARTIFACTS
require, digest = PAIR.require, PAIR.digest

CANDIDATE_SOURCE = "5deaf5880c83a76290520fa1176982dab0bf87a5"
CANDIDATE_RUN = 39631703411
CANDIDATE_ARTIFACT = 12364250685
CANDIDATE_ZIP_SHA256 = "347d02515c408e825bd13790e265e13663f150e9ab4c64b01107d77b37b0fb01"
CANDIDATE_KERNEL_SHA256 = "fad819da8477cf225c608ab928baddb8f91aa3ce7d133edf08942262bcc9ac93"
BENCH = "pskernel-expr-v2-admission-bench.mjs"
PROFILER = "pskernel-generated-profile.mjs"
PROFILE_PREFIX = "PSC1_ADMISSION_PROFILE "
PHASES = ("cpu", "allocations", "survivors")
PROFILE_FILE_LIMIT = 64 * 1024 * 1024
PATCHES = json.loads(r'''[
  {
    "old": "const [filename, mode, variant, shape, countArg, callsArg] = process.argv.slice(2);",
    "new": "const [filename, mode, variant, shape, countArg, callsArg, profileDirArg] = process.argv.slice(2);"
  },
  {
    "old": "if (mode !== \"worker\") {",
    "new": "if (mode !== \"worker\" && mode !== \"profile\") {"
  },
  {
    "old": "    throw Error(\"PSC1_ADMISSION_INVALID_SIZE\");\n  const k = await import(pathToFileURL(absolute).href);",
    "new": "    throw Error(\"PSC1_ADMISSION_INVALID_SIZE\");\n  if (mode === \"profile\" && (shape !== \"metadata\" || !profileDirArg))\n    throw Error(\"PSC1_ADMISSION_INVALID_PROFILE\");\n  const k = await import(pathToFileURL(absolute).href);"
  },
  {
    "old": "  const cold = perform(0);\n  for (let i = 0; i < inputs.length; i++) perform(i);\n",
    "new": "  const cold = perform(0);\n  for (let i = 0; i < inputs.length; i++) perform(i);\n  if (mode === \"profile\") {\n    const { profileCheckedOperation } = await import(\"./pskernel-generated-profile.mjs\");\n    const identity = {\n      variant, shape, depth: count, operation: \"admit\", fuel: 4096,\n      declarations_per_batch: count, input_pool: inputs.length,\n      public_entry: variant === \"dag\" ? \"psKernelV1RunDag\" : \"psKernelV1AdmitDeclaration\",\n      validation: \"unchanged exact environment, receipt, definition and index assertions\"\n    };\n    const profile = await profileCheckedOperation({\n      perform: i => {\n        const slot = i % inputs.length;\n        const result = execute(inputs[slot]);\n        validate(result, expected[slot]);\n        return 1;\n      },\n      calls, modulePath: absolute, outputDirectory: profileDirArg, identity\n    });\n    const directDiagnostic = variant === \"dag\" ? directAdmissionDiagnostic() : null;\n    console.log(\"PSC1_ADMISSION_PROFILE \" + JSON.stringify({\n      variant, shape, declarations_per_batch: count, calls,\n      profiled_phases: 3, checked_declarations: 3 * calls * count,\n      all_correct: true, negative_type_mismatch: true, fuel: 4096,\n      input_pool: inputs.length, cold_admission_ms: cold.admissionMs,\n      cold_assertion_ms: cold.assertionMs, input_construction_ms: constructionMs,\n      input_construction_heap_delta_bytes: constructionAfter.heapUsed - constructionBefore.heapUsed,\n      input_construction_rss_delta_bytes: constructionAfter.rss - constructionBefore.rss,\n      generated_module_sha256: profile.generated_module_sha256,\n      profile_summary: [variant, shape, count, \"admit\"].join(\"-\") + \".summary.json\",\n      direct_dag_admission_diagnostic: directDiagnostic,\n      direct_dag_admission_path_measured: false,\n      instrumented_scope: \"same public execute plus independent validate; fresh session per batch\"\n    }));\n  } else {\n"
  },
  {
    "old": "  }));\n}\n",
    "new": "  }));\n  }\n}\n"
  }
]''')


def authenticate(runtimes: pathlib.Path) -> dict:
    value = PAIR.read_json(runtimes / "authentication.json")
    require(value.get("format") == "psc1-paired-performance-artifacts-v1"
            and value.get("repository") == ARTIFACTS.REPOSITORY
            and value.get("compiler_reexecuted") is False
            and value.get("canonical_rechecked") is False
            and value.get("new_kernel_qualification_established") is False,
            "different artifact authentication protocol")
    identities = {
        "baseline": (ARTIFACTS.BASELINE_SOURCE, ARTIFACTS.BASELINE_RUN,
                     ARTIFACTS.BASELINE_ARTIFACT, ARTIFACTS.BASELINE_ZIP_SHA256,
                     ARTIFACTS.BASELINE_KERNEL_SHA256),
        "candidate": (CANDIDATE_SOURCE, CANDIDATE_RUN, CANDIDATE_ARTIFACT,
                      CANDIDATE_ZIP_SHA256, CANDIDATE_KERNEL_SHA256),
    }
    for label, expected in identities.items():
        row = value[label]
        observed = tuple(row.get(key) for key in
                         ("source_sha", "producer_run", "artifact_id",
                          "artifact_zip_sha256", "kernel_sha256"))
        require(observed == expected, "profile source/artifact identity differs: " + label)
        require(digest((runtimes / (label + ".zip")).read_bytes()) == expected[3],
                "runtime ZIP changed after authentication: " + label)
        jobs = row["required_jobs"]
        require(len(jobs) == 2 and {job["name"] for job in jobs} ==
                {"native-dag-integration", "generated-dag-integration"}
                and all(job["conclusion"] == "success" for job in jobs),
                "producer integration receipt differs: " + label)
    require(digest((runtimes / "official-reference.zip").read_bytes()) == ARTIFACTS.REFERENCE_ZIP_SHA256
            and digest((runtimes / "official-reference.json").read_bytes()) ==
            value["official_reference"]["report_sha256"],
            "retained reference receipt changed; no reference is executed by this diagnostic")
    return value


def profile_harness(bundles: dict, baseline: pathlib.Path, candidate: pathlib.Path, node: pathlib.Path) -> dict:
    original = (baseline / "scripts" / BENCH).read_text(encoding="utf-8")
    require(original == (candidate / "scripts" / BENCH).read_text(encoding="utf-8"),
            "original admission benchmark differs between exact sources")
    profiler = (baseline / "scripts" / PROFILER).read_bytes()
    require(profiler == (candidate / "scripts" / PROFILER).read_bytes(),
            "original sampling implementation differs between sources")
    derived = original
    for patch in PATCHES:
        require(derived.count(patch["old"]) == 1, "profile-only harness insertion no longer exact")
        derived = derived.replace(patch["old"], patch["new"], 1)
    original_bytes, derived_bytes = original.encode("utf-8"), derived.encode("utf-8")
    require(derived_bytes != original_bytes, "missing profile branch")
    for label, bundle in bundles.items():
        target = bundle / "scripts" / BENCH
        require(target.read_bytes() == original_bytes, "restored original worker changed: " + label)
        target.write_bytes(derived_bytes)
        (bundle / "scripts" / PROFILER).write_bytes(profiler)
        checked = subprocess.run([str(node), "--check", str(target)], cwd=bundle,
                                 env=PAIR.runtime_environment(bundle), capture_output=True,
                                 text=True, timeout=10)
        require(checked.returncode == 0, "derived profile harness syntax failed: " + checked.stderr)
    return {
        "original_admission_harness_sha256": digest(original_bytes),
        "derived_profile_harness_sha256": digest(derived_bytes),
        "original_sampling_module_sha256": digest(profiler),
        "exact_profile_only_replacements": len(PATCHES),
        "ordinary_worker_source_preserved_as_alternative_branch": True,
        "kernel_bytes_modified": False,
        "fresh_syntax_check_passed": True,
        "runtime_files": [BENCH, PROFILER],
    }


def validate_profile(receipt: dict, profile: dict, variant: str, count: int, calls: int,
                     expected_hash: str, node_version: str, directory: pathlib.Path) -> list[dict]:
    label = f"{variant}-metadata-{count}-admit"
    require(receipt.get("variant") == variant and receipt.get("shape") == "metadata"
            and receipt.get("declarations_per_batch") == count and receipt.get("calls") == calls
            and receipt.get("profiled_phases") == 3
            and receipt.get("checked_declarations") == 3 * calls * count
            and receipt.get("all_correct") is True and receipt.get("negative_type_mismatch") is True
            and receipt.get("fuel") == 4096 and receipt.get("input_pool") == 5
            and receipt.get("generated_module_sha256") == expected_hash
            and receipt.get("profile_summary") == label + ".summary.json",
            "profile admission receipt or source identity differs")
    diagnostic = receipt.get("direct_dag_admission_diagnostic")
    if variant == "dag":
        require(isinstance(diagnostic, dict) and diagnostic.get("positive_direct_attempts") == count
                and diagnostic.get("checked_original_id_entries") == count
                and diagnostic.get("exact_direct_type_mismatch") is True
                and diagnostic.get("dispatcher_environment_parity") is True
                and diagnostic.get("timed_path_instrumented") is False
                and receipt.get("direct_dag_admission_path_measured") is False,
                "original untimed admission diagnostics differ")
    else:
        require(diagnostic is None, "unexpected legacy DAG diagnostic")
    for key in ("cold_admission_ms", "cold_assertion_ms", "input_construction_ms"):
        require(PAIR.finite(receipt.get(key)), "invalid setup observation: " + key)
    for key in ("input_construction_heap_delta_bytes", "input_construction_rss_delta_bytes"):
        require(PAIR.finite(receipt.get(key), nonnegative=False), "invalid signed setup observation: " + key)
    identity = {
        "variant": variant, "shape": "metadata", "depth": count, "operation": "admit", "fuel": 4096,
        "declarations_per_batch": count, "input_pool": 5,
        "public_entry": "psKernelV1RunDag" if variant == "dag" else "psKernelV1AdmitDeclaration",
        "validation": "unchanged exact environment, receipt, definition and index assertions",
    }
    require(profile.get("format") == "psc1-generated-profile-v1"
            and profile.get("generated_module_sha256") == expected_hash
            and profile.get("identity") == identity and profile.get("node") == node_version,
            "sampled source/operation identity differs")
    files = []
    for phase in PHASES:
        result = profile[phase]
        require(isinstance(result, dict), "profile phase is not an object: " + phase)
        require(result.get("calls") == calls and result.get("checksum") == calls
                and result.get("all_correct") is True and PAIR.finite(result.get("instrumented_ms"))
                and type(result.get("sample_count")) is int and result["sample_count"] >= 0,
                "profile phase has incomplete checked calls: " + phase)
        suffix = ".cpuprofile" if phase == "cpu" else "." + phase + ".heapprofile"
        expected_file = label + suffix
        require(result.get("profile_file") == expected_file, "unexpected raw profile path")
        raw_path = directory / expected_file
        require(raw_path.is_file() and 0 < raw_path.stat().st_size <= PROFILE_FILE_LIMIT,
                "missing or oversized raw profile")
        raw = raw_path.read_bytes()
        parsed = json.loads(raw)
        require(isinstance(parsed, dict), "raw profile is not an object")
        if phase == "cpu":
            require(result.get("sampling_interval_us") == 1000 and result["sample_count"] > 0
                    and isinstance(parsed.get("nodes"), list) and isinstance(parsed.get("samples"), list)
                    and len(parsed["samples"]) == result["sample_count"]
                    and PAIR.finite(result.get("sampled_us")) and result["sampled_us"] > 0,
                    "CPU sampling record is incomplete")
        else:
            require(result.get("phase") == phase
                    and result.get("sampling_interval_bytes") == (32768 if phase == "allocations" else 4096)
                    and result.get("include_collected_objects") is (phase == "allocations")
                    and isinstance(parsed.get("head"), dict)
                    and PAIR.finite(result.get("estimated_total_bytes")),
                    "allocation sampling record is incomplete")
            for key in ("heap_used_delta_after_gc_bytes", "heap_reserved_delta_after_gc_bytes",
                        "rss_delta_after_gc_bytes"):
                require(PAIR.finite(result.get(key), nonnegative=False), "invalid sampled heap delta")
        files.append({"phase": phase, "path": expected_file, "bytes": len(raw), "sha256": digest(raw)})
    summary_bytes = (directory / (label + ".summary.json")).read_bytes()
    files.append({"phase": "summary", "path": label + ".summary.json",
                  "bytes": len(summary_bytes), "sha256": digest(summary_bytes)})
    return files


def observation(node: pathlib.Path, node_version: str, bundle: pathlib.Path, logs: pathlib.Path,
                directory: pathlib.Path, index: int, source: str, variant: str,
                count: int, calls: int, kernel_hash: str) -> dict:
    directory.mkdir()
    result, stdout = PAIR.process([
        str(node), "--max-old-space-size=2048", "--expose-gc", str(bundle / "scripts" / BENCH),
        str(bundle / "kernel.js"), "profile", variant, "metadata", str(count), str(calls), str(directory)
    ], bundle, logs, f"profile-{index:02d}-{source}-{variant}-{count}")
    result.update(index=index, source=source, variant=variant, shape="metadata",
                  declarations_per_batch=count, calls_per_phase=calls, valid=False,
                  profile_directory=directory.name)
    if result["status"] != "completed":
        result["failure_stdout_tail"] = stdout[-4000:]
        stderr_path = logs / result["stderr"]
        if stderr_path.is_file():
            result["failure_stderr_tail"] = stderr_path.read_text(encoding="utf-8", errors="replace")[-8000:]
        return result
    try:
        lines = [line[len(PROFILE_PREFIX):] for line in stdout.splitlines() if line.startswith(PROFILE_PREFIX)]
        require(len(lines) == 1, "missing or duplicate admission profile receipt")
        receipt = json.loads(lines[0])
        require(isinstance(receipt, dict), "admission profile receipt is not an object")
        summary_path = directory / f"{variant}-metadata-{count}-admit.summary.json"
        require(summary_path.is_file() and summary_path.stat().st_size <= PROFILE_FILE_LIMIT,
                "missing or oversized summary")
        profile = PAIR.read_json(summary_path)
        files = validate_profile(receipt, profile, variant, count, calls, kernel_hash, node_version, directory)
        result.update(valid=True, admission=receipt, profile=profile, files=files)
    except (ValueError, TypeError, KeyError, OSError, OverflowError) as error:
        result.update(status="protocol_failure", reason=str(error))
    return result


def summary(out: pathlib.Path, report: dict) -> None:
    lines = [
        "# Eight artifact-based metadata admission profiles", "",
        "Baseline: " + ARTIFACTS.BASELINE_SOURCE + ". Candidate: " + CANDIDATE_SOURCE + ".", "",
        "These diagnostics explain the separately measured metadata admission regression. Each cell "
        "uses one fresh detached process, the same exact metadata fixtures and assertions, unchanged "
        "fuel 4096, and separate CPU/allocation/survivor phases. The callback includes public admission "
        "and its independent exact-result validation. The old 48-worker ABBA report is unchanged.", "",
        "Each process has a 60-second deadline and 2048 MiB V8 old-space limit. No OS memory cap is "
        "enforced by this diagnostic; measured RSS includes memory outside old space. "
        "The separate generated Arena hard-cap controls do not retroactively qualify these runs.", "",
        "## Collected profiles", "",
        "| Source | Entry | Declarations | Valid | CPU samples | CPU instrumented ms | Allocation estimate bytes | Survivor estimate bytes | Process peak RSS KiB |",
        "| --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in report["observations"]:
        if row["valid"]:
            profile = row["profile"]
            values = (profile["cpu"]["sample_count"], f"{profile['cpu']['instrumented_ms']:.3f}",
                      profile["allocations"]["estimated_total_bytes"],
                      profile["survivors"]["estimated_total_bytes"], row.get("process_peak_rss_kib"))
        else:
            values = ("unavailable",) * 5
        lines.append(f"| {row['source']} | {row['variant']} | {row['declarations_per_batch']} "
                     f"| {row['valid']} | " + " | ".join(map(str, values)) + " |")
    lines.extend(["", "CPU weights approximate sampled self time. Allocation estimates are statistical; "
                  "survivors cover newly sampled allocations still live after GC, not a whole-heap census. "
                  "Nearby generated declaration names are source-location hints. Timings include "
                  "instrumentation and cannot replace the ordinary paired measurements. Whole-process "
                  "RSS/CPU also include fixture setup, warmups and the unchanged untimed DAG diagnostics.", "",
                  "No new kernel/canonical-source qualification, full V2 completion, corpus parity, "
                  "timeout resolution, or statistically established speedup follows from this collection.", ""])
    (out / "summary.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtimes", type=pathlib.Path, required=True)
    parser.add_argument("--baseline-source", type=pathlib.Path, required=True)
    parser.add_argument("--candidate-source", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    runtimes, baseline, candidate = (p.resolve(strict=True) for p in
                                     (args.runtimes, args.baseline_source, args.candidate_source))
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    require(not (out / "report.json").exists(), "refusing to overwrite an existing profile report")
    authentication = authenticate(runtimes)
    sources = PAIR.verify_sources(baseline, candidate, authentication)
    node_path = shutil.which("node")
    require(node_path is not None and pathlib.Path("/usr/bin/time").is_file(), "missing Node/GNU time")
    node = pathlib.Path(node_path).resolve(strict=True)
    node_version = subprocess.check_output([str(node), "--version"], text=True).strip()
    require(re.fullmatch(r"v22\.[0-9]+\.[0-9]+", node_version) is not None, "Node major differs from 22")
    report = {
        "format": "psc1-paired-admission-profile-v1", "workflow_source_sha": os.environ.get("GITHUB_SHA"),
        "workflow_run": os.environ.get("GITHUB_SERVER_URL", "https://github.com") + "/"
                        + os.environ.get("GITHUB_REPOSITORY", ARTIFACTS.REPOSITORY)
                        + "/actions/runs/" + os.environ.get("GITHUB_RUN_ID", "unknown"),
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "authentication": authentication, "source_comparison": sources,
        "driver_sha256": digest(pathlib.Path(__file__).read_bytes()),
        "unchanged_paired_driver_sha256": digest((HERE / "pskernel-paired-performance.py").read_bytes()),
        "node_version": node_version, "node_executable_sha256": digest(node.read_bytes()),
        "host_cpu_models": sorted({line.partition(":")[2].strip() for line in
                                  pathlib.Path("/proc/cpuinfo").read_text().splitlines()
                                  if line.startswith("model name")}),
        "kernel_fuel": 4096, "host_deadline_seconds_per_process": 60,
        "v8_old_space_limit_mib": 2048, "hard_rss_limit_enforced": False,
        "rss_scope": "measured KiB; old-space limit is not a total-process memory limit",
        "runtime_path_empty": True, "host_workers": 1,
        "runtime_working_directory_contains_no_Lean_compiler_or_kernel_sources": True,
        "profile_processes_expected": 8, "phases_per_process": list(PHASES),
        "comparison_scope": "whole exact source revisions; one diagnostic sample per source/entry/size",
        "profiled_callback": "unchanged complete public admission plus independent exact validation",
        "independent_assertions_included_in_samples": True,
        "fresh_semantic_session_per_callback": True,
        "input_construction_profiled": False,
        "source_order": "baseline/candidate for metadata8; candidate/baseline for metadata32",
        "dag_entry_scope": "psKernelV1RunDag uses transitional DAG checking with V1 whole-operation fallbacks",
        "official_reference_executed_or_used_as_profile_oracle": False,
        "new_kernel_qualification_established": False, "full_v2_replacement_established": False,
        "all_193_conformance_established": False, "ordinary_paired_report_modified": False,
        "controls": [], "observations": [], "collection_complete": False,
    }
    logs, profiles = out / "logs", out / "profiles"
    logs.mkdir()
    profiles.mkdir()
    PAIR.write_report(out, report)
    try:
        with tempfile.TemporaryDirectory(prefix="psc1-paired-profile-detached-") as temporary:
            work = pathlib.Path(temporary)
            bundles = PAIR.restore_detached(runtimes, authentication, baseline, work)
            report["profile_harness"] = profile_harness(bundles, baseline, candidate, node)
            retained_harness = out / "profile-harness"
            retained_harness.mkdir()
            for filename in (BENCH, PROFILER):
                shutil.copyfile(bundles["baseline"] / "scripts" / filename, retained_harness / filename)
            PAIR.write_report(out, report)
            for label in ("baseline", "candidate"):
                bundle = bundles[label]
                observed, stdout = PAIR.process([
                    str(node), "--max-old-space-size=2048",
                    str(bundle / "scripts/pskernel-arena-replay-controls.mjs"), str(bundle / "kernel.js")
                ], bundle, logs, "controls-" + label)
                markers = [line for line in stdout.splitlines()
                           if line.startswith("PSC1_ARENA_REPLAY_CONTROLS:")]
                valid = (observed["status"] == "completed"
                         and markers == ["PSC1_ARENA_REPLAY_CONTROLS: PASS count=138"]
                         and len([line for line in stdout.splitlines()
                                  if line.startswith("PSC1_ARENA_CONTROL_PASS ")]) == 138)
                report["controls"].append({"source": label, "valid": valid, "expected_assertions": 138, **observed})
                PAIR.write_report(out, report)
                require(valid, "fresh original replay controls failed: " + label)
                print("PSC1_PAIRED_PROFILE_CONTROLS_PASS " + label + " count=138", flush=True)
            for count, calls in ((8, 3), (32, 2)):
                for variant in ("legacy", "dag"):
                    for label in (("baseline", "candidate") if count == 8 else ("candidate", "baseline")):
                        index = len(report["observations"])
                        row = observation(node, node_version, bundles[label], logs,
                            profiles / f"{index:02d}-{label}-{variant}-{count}", index, label,
                            variant, count, calls, authentication[label]["kernel_sha256"])
                        report["observations"].append(row)
                        PAIR.write_report(out, report)
                        encoded = json.dumps(row, ensure_ascii=False, allow_nan=False)
                        require(len(encoded.encode("utf-8")) <= 256 * 1024, "profile console record exceeds bound")
                        print("PSC1_PAIRED_ADMISSION_PROFILE " + encoded, flush=True)
                        require(row["valid"], "instrumented profile incomplete: " + str(index))
            require(len(report["observations"]) == 8 and all(row["valid"] for row in report["observations"]),
                    "profile matrix is incomplete")
            report["collection_complete"] = True
    except (ValueError, TypeError, KeyError, OSError, subprocess.SubprocessError) as error:
        report["failure"] = str(error)
    finally:
        report["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        PAIR.write_report(out, report)
        summary(out, report)
        PAIR.output_digests(out)
    data = (out / "report.json").read_bytes()
    print("PSC1_PAIRED_PROFILE_REPORT " + json.dumps({"bytes": len(data), "sha256": digest(data),
          "profiles": len(report["observations"]), "complete": report["collection_complete"]}), flush=True)
    print("PSC1_PAIRED_ADMISSION_PROFILE_COLLECTION: " +
          ("PASS profiles=8" if report["collection_complete"] else "FAIL"), flush=True)
    return 0 if report["collection_complete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
