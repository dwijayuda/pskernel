#!/usr/bin/env python3
"""Faithful native V1 admission diagnostic for one authenticated Arena input."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
SOURCE = "369bee5801bd5e4476837684fad3f7e1ca8c422c"
BODY = "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47"
ADAPTED = "443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1"
ZIP_SHA = "9ae05c3d0cd949f74a1a4c8a3a833b3fd755f1cb917897ab59552c9ce3aa90cc"
ARCHIVE_SHA = "98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d"
LEAN_COMMIT = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
IDENTITY = ("good", "perf/church-numerals.ndjson")
PROTOCOL_PREFIX = "PSC1_ARENA_NATIVE_V1 "
POLICY = {"fuel": 4096, "maxRecDepth": 0, "maxNatSize": 134217728,
          "maxDeclarations": 0, "cancelled": False}
TARGET = "psc1_arena_native_v1_church"
APPEND_CONFIG = """
-- Host-only authentic input fixture; production kernel configuration is unchanged.
lean_lib NativeChurchInput where
  srcDir := "native-church-diagnostic"
  roots := #[\x60NativeChurchInput]

lean_exe psc1_arena_native_v1_church where
  srcDir := "native-church-diagnostic"
  root := \x60NativeChurchMain
"""


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def file_digest(path: pathlib.Path) -> str:
    return digest(path.read_bytes())


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def load_module(name: str, path: pathlib.Path):
    spec = importlib.util.spec_from_file_location(name, path)
    require(spec is not None and spec.loader is not None, "cannot load diagnostic helper")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def command_output(command: list[str], cwd: pathlib.Path) -> str:
    result = subprocess.run(command, cwd=cwd, check=True, capture_output=True,
                            text=True, timeout=60)
    return result.stdout.strip()


def fresh_write(path: pathlib.Path, value: bytes) -> None:
    with path.open("xb") as stream:
        stream.write(value)


def extract_protocol(stdout: pathlib.Path, controls: bool) -> dict:
    lines = stdout.read_text(encoding="utf-8").splitlines()
    payloads = [json.loads(line[len(PROTOCOL_PREFIX):]) for line in lines
                if line.startswith(PROTOCOL_PREFIX)]
    require(len(payloads) == 1 and isinstance(payloads[0], dict),
            "native diagnostic omitted or duplicated its structured outcome")
    expected_extra = ["PSC1_ARENA_NATIVE_V1_CONTROLS: PASS count=3"] if controls else []
    require([line for line in lines if line and not line.startswith(PROTOCOL_PREFIX)] == expected_extra,
            "unexpected native diagnostic output")
    return payloads[0]


def validate_case_protocol(value: dict) -> None:
    require(value.get("protocol") == "pskernel-arena-native-v1/1"
            and value.get("sourceSha") == SOURCE
            and value.get("bodySha256") == BODY
            and value.get("adaptedSourceSha256") == ADAPTED
            and value.get("case") == "church-numerals"
            and value.get("engine") == "psKernelV1AdmitDeclaration"
            and value.get("policy") == POLICY
            and value.get("inputNodes") == 197
            and value.get("inputRequests") == 4
            and value.get("metadataValidated") is False
            and value.get("arenaMatchClaimed") is False,
            "native case identity or scope differs")
    outcome = value.get("outcome")
    if outcome == "native_admission_complete":
        require(value.get("accepted") is True and value.get("complete") is True
                and value.get("acceptedRequests") == 4
                and value.get("declarationIndex") is None,
                "native success is not complete admission")
    elif outcome == "rejectedInvalid":
        require(value.get("accepted") is False and value.get("complete") is True
                and isinstance(value.get("message"), str), "invalid native rejection protocol")
    else:
        require(outcome in {"declinedUnsupported", "resourceExhausted", "internalError", "malformedInput"}
                and value.get("accepted") is None and value.get("complete") is False
                and isinstance(value.get("message"), str),
                "incomplete native outcome was misclassified")
        if outcome == "resourceExhausted":
            require(value.get("resource") in {"fuel", "recursionDepth", "natSize",
                    "cancelled", "declarationLimit", "hostStack"}, "unknown resource category")
    index = value.get("declarationIndex")
    require(index is None or (type(index) is int and 0 <= index < 4),
            "native declaration index outside original input")
    require(type(value.get("acceptedRequests")) is int and 0 <= value["acceptedRequests"] <= 4,
            "invalid native accepted-request count")


def collect(args: argparse.Namespace, report: dict) -> None:
    source = args.source.resolve(strict=True)
    kernel = args.kernel.resolve(strict=True)
    baseline_path = args.baseline.resolve(strict=True)
    authentication_path = args.authentication.resolve(strict=True)
    out = args.out.resolve()
    report.update(source_sha=SOURCE, workflow_source_sha=os.environ.get("GITHUB_SHA"),
                  kernel_qualified=False, metadata_validated=False, arena_match_claimed=False,
                  runtime_path_empty=True, kernel_fuel=4096,
                  host_wall_seconds_per_case=60, native_cgroup_memory_limit_bytes=2147483648)
    require(args.source_sha == SOURCE, "native diagnostic source pin differs")
    require(command_output(["git", "-C", str(source), "rev-parse", "HEAD"], source) == SOURCE,
            "native source checkout is not pinned")
    require(not command_output(["git", "-C", str(source), "status", "--porcelain",
                                "--untracked-files=no"], source), "pinned checkout has tracked edits")
    require((source / "lean-toolchain").read_text().strip() == "leanprover/lean4:v4.35.0",
            "native toolchain pin differs")
    original_config = (source / "kernel-lakefile.lean").read_bytes()
    replay = source / "scripts/pskernel-arena-replay.mjs"
    policy_source = source / "packages/pskernel-core/src/Ps/KernelCore/Checker/ResourcePolicy.lean"
    authentication = json.loads(authentication_path.read_text())
    require(authentication.get("format") == "psc1-authenticated-resource-artifact-replay-v1"
            and authentication.get("source_sha") == SOURCE
            and authentication.get("producer_run") == 39607734805
            and authentication.get("artifact_id") == 12350649771
            and authentication.get("artifact_zip_sha256") == ZIP_SHA
            and authentication.get("artifact_zip_bytes") == 14770339
            and authentication.get("kernel_qualified") is False,
            "runtime authentication receipt differs")
    runtime_files = authentication.get("files", [])
    require(len(runtime_files) == 4 and {item["name"] for item in runtime_files} ==
            {"kernel.js", "kernel.ts", "kernel.d.ts", "kernel.js.map"},
            "authenticated runtime closure differs")
    for item in runtime_files:
        runtime_file = kernel.parent / item["name"]
        require(runtime_file.stat().st_size == item["bytes"]
                and file_digest(runtime_file) == item["sha256"],
                "authenticated runtime file changed: " + item["name"])
    require(kernel.name == "kernel.js", "unexpected authenticated runtime filename")
    baseline = json.loads(baseline_path.read_text())
    require(baseline.get("format") == "psc1-authentic-arena-diagnostics-v1"
            and baseline.get("source_sha") == SOURCE
            and baseline.get("kernel_sha256") == file_digest(kernel)
            and baseline.get("replay_sha256") == file_digest(replay)
            and baseline.get("archive_sha256") == ARCHIVE_SHA
            and baseline.get("kernel_fuel") == 4096
            and baseline.get("diagnostics_complete") is True
            and file_digest(baseline_path) == authentication.get("baseline_report_sha256"),
            "native diagnostic baseline identity differs")
    selected = [case for case in baseline["cases"] if (case["label"], case["name"]) == IDENTITY]
    require(len(selected) == 1 and selected[0]["official"]["verdict"] == "accepted",
            "native diagnostic official/input identity differs")
    oracle_path = source / "scripts/pskernel-arena435-oracle.py"
    oracle = load_module("native_arena_oracle", oracle_path)
    corpus = {(label, name): data for label, name, data in oracle.read_archive(args.archive)}
    adapted, adaptation = oracle.adapt_header(corpus[IDENTITY])
    require(adaptation == selected[0]["adaptation"]
            and adaptation["original_body_sha256"] == BODY
            and adaptation["adapted_body_sha256"] == BODY
            and adaptation["body_bytes_identical"] is True
            and digest(adapted) == ADAPTED, "native diagnostic changed original body or header adaptation")
    report.update(authenticated_runtime=authentication, official_reference=selected[0]["official"],
                  adaptation=adaptation, replay_sha256=file_digest(replay),
                  resource_policy_sha256=file_digest(policy_source),
                  oracle_sha256=file_digest(oracle_path), original_lakefile_sha256=digest(original_config))
    for original, name in [(authentication_path, "authentication.json"), (baseline_path, "baseline.json"),
                            (replay, "pinned-replay.mjs")]:
        shutil.copyfile(original, out / name)
    (out / "input.ndjson").write_bytes(adapted)
    (out / "adaptation.json").write_text(json.dumps(adaptation, indent=2) + "\n")
    (out / "pinned-kernel-lakefile.lean").write_bytes(original_config)

    node_name, lake_name = shutil.which("node"), shutil.which("lake")
    require(node_name is not None and lake_name is not None, "pinned Node/Lean tools are unavailable")
    node, lake = pathlib.Path(node_name).resolve(strict=True), pathlib.Path(lake_name).absolute()
    node_version = command_output([str(node), "--version"], source)
    require(node_version.startswith("v22."), "native exporter requires Node22")
    lean_version = command_output([str(lake), "-f", "kernel-lakefile.lean",
                                   "env", "lean", "--version"], source)
    lean_commit = command_output([str(lake), "-f", "kernel-lakefile.lean",
                                  "env", "lean", "--githash"], source)
    require("4.35.0" in lean_version and lean_commit == LEAN_COMMIT, "native Lean identity differs")
    report.update(node_version=node_version, lean_version=lean_version, lean_githash=lean_commit)

    work = source / "native-church-diagnostic"
    work.mkdir()
    host_source = HERE.parent / "host/arena-native-v1/NativeChurchMain.lean"
    host = work / "NativeChurchMain.lean"
    shutil.copyfile(host_source, host)
    fixture = work / "NativeChurchInput.lean"
    exporter = HERE / "pskernel-arena435-native-export.mjs"
    export_receipt = out / "input-export.json"
    exporter_command = [str(node), "--max-old-space-size=2048", str(exporter),
        "--kernel", str(kernel), "--input", str(out / "input.ndjson"),
        "--replay", str(replay), "--out", str(fixture), "--receipt", str(export_receipt),
        "--source-sha", SOURCE]
    export_environment = dict(os.environ, PATH="")
    started = time.monotonic()
    with (out / "export.stdout.txt").open("wb") as stdout, (out / "export.stderr.txt").open("wb") as stderr:
        exported = subprocess.run(exporter_command, cwd=out, env=export_environment,
                                  stdout=stdout, stderr=stderr, timeout=60)
    require(exported.returncode == 0, "authentic original transport input export failed")
    exported_receipt = json.loads(export_receipt.read_text())
    require(exported_receipt.get("source_sha") == SOURCE
            and exported_receipt.get("body_sha256") == BODY
            and exported_receipt.get("adapted_input_sha256") == ADAPTED
            and exported_receipt.get("kernel_sha256") == file_digest(kernel)
            and exported_receipt.get("original_replay_sha256") == file_digest(replay)
            and exported_receipt.get("fixture_sha256") == file_digest(fixture)
            and exported_receipt.get("generator_sha256") == file_digest(exporter)
            and exported_receipt.get("generated_admission_invoked") is False
            and exported_receipt.get("requires_native_decode_checked") is True,
            "native fixture export receipt differs")
    report.update(input_export=exported_receipt, input_export_wall_seconds=time.monotonic() - started,
                  host_source_sha256=file_digest(host), exporter_sha256=file_digest(exporter))
    config = source / "kernel-native-church-lakefile.lean"
    fresh_write(config, original_config + APPEND_CONFIG.encode())
    for original in [host, fixture, config]:
        shutil.copyfile(original, out / original.name)
    report["generated_lakefile_sha256"] = file_digest(config)
    build_command = [str(lake), "-f", config.name, "build", TARGET]
    started = time.monotonic()
    with (out / "build.stdout.txt").open("wb") as stdout, (out / "build.stderr.txt").open("wb") as stderr:
        built = subprocess.run(build_command, cwd=source, stdout=stdout, stderr=stderr, timeout=900)
    report["build"] = {"command": build_command, "returncode": built.returncode,
                       "wall_seconds": time.monotonic() - started}
    require(built.returncode == 0, "native diagnostic build failed")
    require((source / "kernel-lakefile.lean").read_bytes() == original_config,
            "original kernel lakefile changed during diagnostic build")
    require(not command_output(["git", "-C", str(source), "diff", "--name-only", "--",
                "packages/pskernel-core/src", "kernel-lakefile.lean", "lean-toolchain"], source),
            "tracked kernel source changed during native build")
    binary_dir = out / "native"
    binary_dir.mkdir()
    binary = binary_dir / TARGET
    shutil.copy2(source / ".lake/build/bin" / TARGET, binary)
    report["native_executable_sha256"] = file_digest(binary)
    report["native_executable_bytes"] = binary.stat().st_size
    runner_path = HERE / "pskernel-arena435-native-cgroup.py"
    runner = load_module("native_arena_cgroup", runner_path)
    report["native_runner_sha256"] = file_digest(runner_path)

    controls_dir = out / "controls"
    controls_dir.mkdir()
    controls = runner.run_native(binary, controls_dir, controls_dir / "stdout.txt",
                                 controls_dir / "stderr.txt", arguments=("--controls",))
    report["controls"] = controls
    require(controls.get("status") == "process_exit" and controls.get("cleanupOk") is True
            and controls.get("returncode") == 0, "native positive/invalid/resource controls did not finish")
    controls_protocol = extract_protocol(controls_dir / "stdout.txt", True)
    require(controls_protocol.get("protocol") == "pskernel-arena-native-v1-controls/1"
            and controls_protocol.get("sourceSha") == SOURCE
            and controls_protocol.get("count") == 3
            and controls_protocol.get("metadataValidated") is False
            and controls_protocol.get("arenaMatchClaimed") is False,
            "native control protocol identity differs")
    rows = controls_protocol.get("cases", [])
    require(len(rows) == 3 and [row.get("outcome") for row in rows] ==
            ["native_admission_complete", "rejectedInvalid", "resourceExhausted"]
            and all(row.get("bodySha256") is None and row.get("adaptedSourceSha256") is None for row in rows),
            "native controls have incorrect classifications or input identities")
    controls["protocol"] = controls_protocol
    case_dir = out / "case"
    case_dir.mkdir()
    measurement = runner.run_native(binary, case_dir, case_dir / "stdout.txt", case_dir / "stderr.txt")
    report["case"] = {"label": IDENTITY[0], "name": IDENTITY[1], "measurement": measurement}
    require(measurement.get("cleanupOk") is True and measurement.get("status") in
            {"process_exit", "timedout", "cgroup_oom", "resource_limit"},
            "native cgroup setup, monitoring or cleanup failed")
    if measurement.get("status") == "process_exit" and measurement.get("returncode") == 0:
        protocol = extract_protocol(case_dir / "stdout.txt", False)
        validate_case_protocol(protocol)
        report["case"]["protocol"] = protocol
        report["case"]["outcome"] = protocol["outcome"]
        report["case"]["accepted"] = protocol["accepted"]
        report["case"]["semantic_outcome_complete"] = protocol["complete"]
    else:
        host_outcome = measurement["status"] if measurement["status"] != "process_exit" else "host_process_error"
        report["case"].update(outcome=host_outcome,
                              accepted=None, semantic_outcome_complete=False, protocol=None)
    report["diagnostics_complete"] = True
    report["note"] = ("This is original V1 admission of the exact authenticated input DAG and requests. "
                      "Exported metadata comparison is not run; admission completion is not an Arena match. "
                      "Host timeout/OOM and kernel resources remain incomplete outcomes, never rejection or parity.")


def write_manifest(out: pathlib.Path) -> None:
    records = [{"path": str(path.relative_to(out)), "sha256": file_digest(path),
                "bytes": path.stat().st_size} for path in sorted(out.rglob("*"))
               if path.is_file() and path.name != "sha256.json"]
    (out / "sha256.json").write_text(json.dumps(records, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("source", "kernel", "baseline", "authentication", "archive", "out"):
        parser.add_argument("--" + name, type=pathlib.Path, required=True)
    parser.add_argument("--source-sha", required=True)
    args = parser.parse_args()
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=False)
    report = {"format": "psc1-authentic-native-v1-admission-diagnostic-v1",
              "diagnostics_complete": False, "kernel_qualified": False}
    status = 0
    try:
        collect(args, report)
    except Exception as error:
        report["diagnostic_error"] = {"kind": type(error).__name__, "message": str(error)}
        status = 1
    finally:
        (args.out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        write_manifest(args.out)
        print("PSC1_ARENA_NATIVE_DIAGNOSTIC " + json.dumps(report), flush=True)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
