#!/usr/bin/env python3
"""Faithful native V1 admission diagnostic for one authenticated Arena input."""
from __future__ import annotations

import argparse
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

lean_lib NativeChurchDefEqTrace where
  srcDir := "native-church-diagnostic"
  roots := #[\x60NativeChurchDefEqTrace]

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


STAGES = ("preflight", "header-check", "proposition-check", "body-closed",
          "body-universes", "body-check", "type-defeq", "publication", "resource-limit")
STAGE_PREFIX = "PSC1_ARENA_NATIVE_STAGES "
EVENT_PREFIX = "PSC1_ARENA_NATIVE_STAGE_EVENT "
FIXTURE_SHA = "d15790e77d82af4b55e21428ebfbe3443c1735a04585359f35d425a9fe86da8a"
EXPORTER_SHA = "03f333187a255d469b6e6747a52c0e73f2432e6d77ebad551fea8d49e0aa0de7"


def exact_json(text: str) -> dict:
    def unique(items):
        value = {}
        for key, item in items:
            require(key not in value, "duplicate native stage JSON key")
            value[key] = item
        return value
    value = json.loads(text, object_pairs_hook=unique)
    require(isinstance(value, dict), "native stage envelope is not an object")
    return value


def stage_protocol(stdout: pathlib.Path, controls: bool) -> dict:
    lines = stdout.read_text(encoding="utf-8").splitlines()
    reports = [exact_json(line[len(STAGE_PREFIX):]) for line in lines if line.startswith(STAGE_PREFIX)]
    require(len(reports) == 1, "native stage protocol omitted/duplicated its outcome")
    expected = ["PSC1_ARENA_NATIVE_STAGE_CONTROLS: PASS count=3"] if controls else []
    require([line for line in lines if line and not line.startswith(STAGE_PREFIX)] == expected,
            "unexpected native stage stdout")
    return reports[0]


def stage_events(stderr: pathlib.Path) -> list[dict]:
    lines = [line for line in stderr.read_text(encoding="utf-8").splitlines() if line]
    require(all(line.startswith(EVENT_PREFIX) for line in lines),
            "unexpected native stage stderr")
    values = [exact_json(line[len(EVENT_PREFIX):]) for line in lines]
    require(0 < len(values) <= 60, "native stage event count outside bounded protocol")
    return values


def validate_staged_case(value: dict, events: list[dict], label: str, index: int,
                        policy: dict, input_size: int | None = None) -> None:
    require(value.get("protocol") == "pskernel-arena-native-theorem-stages/1"
            and value.get("case") == label and value.get("sourceSha") == SOURCE
            and type(value.get("declarationIndex")) is int and value["declarationIndex"] == index
            and value.get("policy") == policy and value.get("sameAsUnmodifiedAPI") is True
            and value.get("inputSessionUnchanged") is True and value.get("noPartialPublication") is True
            and value.get("metadataValidated") is False and value.get("arenaMatchClaimed") is False,
            "native staged case identity, policy, comparison or publication control differs")
    if input_size is not None:
        require(type(value.get("inputEnvironmentDeclarations")) is int
                and value["inputEnvironmentDeclarations"] == input_size,
                "native staged case input environment size differs")
    if label == "church-numerals":
        require(value.get("bodySha256") == BODY and value.get("adaptedSourceSha256") == ADAPTED,
                "native staged Church body identity differs")
    else:
        require(value.get("bodySha256") is None and value.get("adaptedSourceSha256") is None,
                "native staged control claims authentic body identity")
    final = value.get("firstFailingStage")
    require(final is None or final in STAGES, "unknown first failing stage")
    completed = len(STAGES) if final is None else STAGES.index(final) + 1
    require(len(events) == completed * 2 + 2, "native staged events omit/duplicate a semantic stage or reference")
    semantic_events, reference_events = events[:-2], events[-2:]
    for number, stage in enumerate(STAGES[:completed]):
        entered, finished = semantic_events[2 * number:2 * number + 2]
        for item in (entered, finished):
            require(item.get("protocol") == "pskernel-arena-native-stage-event/1"
                    and item.get("case") == label and item.get("sourceSha") == SOURCE
                    and type(item.get("declarationIndex")) is int and item["declarationIndex"] == index
                    and type(item.get("fuel")) is int and item["fuel"] == policy["fuel"]
                    and item.get("stage") == stage, "native stage event identity differs")
        require(entered.get("phase") == "enter", "native stage event lacks entry marker")
        expected_phase = "error" if stage == final else "ok"
        require(finished.get("phase") == expected_phase, "native stage completion/error ordering differs")
    outcome = value.get("outcome")
    reference = value.get("reference")
    require(isinstance(reference, dict), "native stage reference API envelope missing")
    for item in reference_events:
        require(item.get("protocol") == "pskernel-arena-native-stage-event/1"
                and item.get("case") == label and item.get("sourceSha") == SOURCE
                and type(item.get("declarationIndex")) is int and item["declarationIndex"] == index
                and type(item.get("fuel")) is int and item["fuel"] == policy["fuel"]
                and item.get("stage") == "reference-operation",
                "native reference operation marker identity differs")
    require(reference_events[0].get("phase") == "enter"
            and reference_events[1].get("phase") == ("ok" if final is None else "error"),
            "native reference operation ordering or outcome differs")
    fields = ("outcome", "accepted", "complete", "resource", "message", "environmentDeclarations")
    require({key: value[key] for key in fields if key in value} ==
            {key: reference[key] for key in fields if key in reference},
            "native stage final typed outcome differs from unmodified API")
    if final is None:
        require(outcome == "native_admission_complete" and value.get("accepted") is True
                and value.get("complete") is True,
                "native stage success is not complete admission")
    else:
        require(outcome in {"rejectedInvalid", "declinedUnsupported", "resourceExhausted", "internalError"},
                "native stage failure lacks typed kernel outcome")
        require({key: value[key] for key in fields if key in value} ==
                {key: semantic_events[-1][key] for key in fields if key in semantic_events[-1]},
                "native first-error event differs from final outcome")
        require({key: reference[key] for key in fields if key in reference} ==
                {key: reference_events[-1][key] for key in fields if key in reference_events[-1]},
                "native reference error marker differs from unchanged API")
        if outcome in {"resourceExhausted", "declinedUnsupported", "internalError"}:
            require(value.get("accepted") is None and value.get("complete") is False,
                    "incomplete native stage result mislabeled as verdict")
        if outcome == "rejectedInvalid":
            require(value.get("accepted") is False and value.get("complete") is True,
                    "native invalid rejection protocol differs")


def validate_stage_parser_controls(value: dict, events: list[dict]) -> int:
    """Reject corrupted receipts using a real completed native positive control."""
    def refused(action):
        try:
            action()
        except ValueError:
            return
        raise ValueError("native stage parser accepted a deliberately corrupted receipt")
    refused(lambda: exact_json('{"case":"a","case":"b"}'))
    mutations = (
        lambda row: row.update(sourceSha="0" * 40),
        lambda row: row.update(sameAsUnmodifiedAPI=False),
        lambda row: row.update(noPartialPublication=False),
        lambda row: row.update(metadataValidated=True),
        lambda row: row["policy"].update(fuel=4097),
        lambda row: row["reference"].update(outcome="resourceExhausted"),
    )
    for mutate in mutations:
        copied = json.loads(json.dumps(value))
        mutate(copied)
        refused(lambda copied=copied: validate_staged_case(copied, events, "stage-positive", 0, POLICY, 0))
    refused(lambda: validate_staged_case(value, events[2:] + events[:2], "stage-positive", 0, POLICY, 0))
    refused(lambda: validate_staged_case(value, events[:-1], "stage-positive", 0, POLICY, 0))
    return 9



def collect_stages(binary: pathlib.Path, out: pathlib.Path, runner, report: dict) -> None:
    print("PSC1_ARENA_NATIVE_STAGE_START pinned_source=" + SOURCE + " fuel=4096", flush=True)
    controls_dir = out / "stage-controls"
    controls_dir.mkdir()
    controls = runner.run_native(binary, controls_dir, controls_dir / "stdout.txt",
                                 controls_dir / "stderr.txt", arguments=("--stage-controls",))
    report["stage_controls"] = controls
    require(controls.get("status") == "process_exit" and controls.get("cleanupOk") is True
            and controls.get("returncode") == 0, "native stage controls did not complete")
    protocol = stage_protocol(controls_dir / "stdout.txt", True)
    require(protocol.get("protocol") == "pskernel-arena-native-stage-controls/1"
            and protocol.get("sourceSha") == SOURCE and protocol.get("count") == 3
            and protocol.get("metadataValidated") is False and protocol.get("arenaMatchClaimed") is False,
            "native stage control identity differs")
    cases = protocol.get("cases")
    require(isinstance(cases, list) and len(cases) == 3, "native stage controls omitted a case")
    all_events = stage_events(controls_dir / "stderr.txt")
    labels = ("stage-positive", "stage-invalid", "stage-resource")
    grouped = {label: [event for event in all_events if event.get("case") == label] for label in labels}
    require(sum(map(len, grouped.values())) == len(all_events), "unknown native stage control event")
    require([event for label in labels for event in grouped[label]] == all_events,
            "native stage control cases interleaved or reordered")
    for value, label in zip(cases, labels):
        policy = dict(POLICY, fuel=0) if label == "stage-resource" else POLICY
        validate_staged_case(value, grouped[label], label, 0, policy, 0)
    require([value["outcome"] for value in cases] ==
            ["native_admission_complete", "rejectedInvalid", "resourceExhausted"]
            and [value["firstFailingStage"] for value in cases] == [None, "type-defeq", "preflight"]
            and cases[0].get("environmentDeclarations") == 1
            and cases[1].get("message") == "theorem proof type mismatch"
            and cases[2].get("resource") == "fuel"
            and cases[2].get("message") == "resource policy declined operation before entry",
            "native stage controls failed actual positive/invalid/resource obligations")
    controls["protocol"] = protocol
    controls["events"] = all_events
    parser_count = validate_stage_parser_controls(cases[0], grouped["stage-positive"])
    report["stage_protocol_controls"] = {"passed": True, "count": parser_count}
    print(f"PSC1_ARENA_NATIVE_STAGE_PARSER_CONTROLS: PASS count={parser_count}", flush=True)
    print("PSC1_ARENA_NATIVE_STAGE_CONTROLS_VALIDATED count=3", flush=True)
    case_dir = out / "stages"
    case_dir.mkdir()
    measurement = runner.run_native(binary, case_dir, case_dir / "stdout.txt",
                                    case_dir / "stderr.txt", arguments=("--stages",))
    report["stage_probe"] = {"measurement": measurement, "diagnostics_complete": False,
                             "metadata_validated": False, "arena_match_claimed": False}
    require(measurement.get("status") == "process_exit" and measurement.get("cleanupOk") is True
            and measurement.get("returncode") == 0,
            "native theorem stage process did not complete; no first failing phase qualified")
    value = stage_protocol(case_dir / "stdout.txt", False)
    events = stage_events(case_dir / "stderr.txt")
    validate_staged_case(value, events, "church-numerals", 3, POLICY)
    baseline = report.get("case", {}).get("protocol", {})
    require(baseline.get("acceptedRequests") == 3 and baseline.get("declarationIndex") == 3
            and baseline.get("outcome") == "resourceExhausted" and baseline.get("resource") == "fuel"
            and baseline.get("message") == "kernel reduction budget exhausted"
            and value.get("outcome") == baseline["outcome"]
            and value.get("resource") == baseline["resource"]
            and value.get("message") == baseline["message"]
            and value.get("firstFailingStage") is not None,
            "native stage probe does not reproduce the unchanged baseline Church resource result")
    report["stage_probe"].update(protocol=value, events=events, diagnostics_complete=True)
    print("PSC1_ARENA_NATIVE_STAGE_COMPLETE " + json.dumps({
        "source_sha": SOURCE, "declaration_index": 3, "fuel": 4096,
        "first_failing_stage": value["firstFailingStage"],
        "outcome": value["outcome"], "resource": value["resource"],
        "same_as_unmodified_api": True, "kernel_qualified": False}), flush=True)


DEFEQ_PREFIX = "PSC1_ARENA_NATIVE_DEFEQ_EVENT "
DEFEQ_INPUT_PREFIX = "PSC1_ARENA_NATIVE_DEFEQ_INPUT "
DEFEQ_CONTROLS_PREFIX = "PSC1_ARENA_NATIVE_DEFEQ_CONTROLS "
DEFEQ_STAGES = frozenset({
    "zero-guard", "depth-guard", "quick", "reflection", "cheap-left", "cheap-right",
    "quick-after-core", "left-type", "is-proposition", "right-type", "proof-type-defeq",
    "lazy-delta", "projection-shortcut", "full-left", "full-right", "changed-retry",
    "full-shape", "final-rules",
})
DEFEQ_PROOFS = (
    "traceAttempt_identity", "frozen_eq_original", "traced_eq_frozen",
    "traced_eq_original", "session_eq_original",
)


def bounded_lines(path: pathlib.Path, limit: int = 1048576) -> list[str]:
    require(path.stat().st_size <= limit, "native DefEq observation exceeded output byte cap")
    return [line for line in path.read_text(encoding="utf-8", errors="strict").splitlines() if line]


def defeq_output(stdout: pathlib.Path, controls: bool) -> dict:
    lines = bounded_lines(stdout)
    prefix = DEFEQ_CONTROLS_PREFIX if controls else STAGE_PREFIX
    reports = [exact_json(line[len(prefix):]) for line in lines if line.startswith(prefix)]
    require(len(reports) == 1, "native DefEq outcome omitted or duplicated")
    expected = ["PSC1_ARENA_NATIVE_DEFEQ_CONTROLS: PASS count=4"] if controls else []
    require([line for line in lines if not line.startswith(prefix)] == expected,
            "unexpected native DefEq stdout")
    return reports[0]


def defeq_observations(stderr: pathlib.Path) -> tuple[list[dict], list[dict], list[dict]]:
    stages, inputs, events = [], [], []
    for line in bounded_lines(stderr):
        require(len(line.encode("utf-8")) <= 262144, "native DefEq event exceeds byte cap")
        if line.startswith(EVENT_PREFIX):
            stages.append(exact_json(line[len(EVENT_PREFIX):]))
        elif line.startswith(DEFEQ_INPUT_PREFIX):
            inputs.append(exact_json(line[len(DEFEQ_INPUT_PREFIX):]))
        elif line.startswith(DEFEQ_PREFIX):
            events.append(exact_json(line[len(DEFEQ_PREFIX):]))
        else:
            raise ValueError("unexpected native DefEq stderr")
    require(len(stages) <= 60 and len(inputs) <= 2 and len(events) <= 49,
            "native DefEq observation exceeded bounded counts")
    return stages, inputs, events


def validate_expr_view(value: dict) -> None:
    require(isinstance(value, dict) and value.get("nodeVisitLimit") == 24
            and value.get("shapeOnly") is True and type(value.get("truncated")) is bool,
            "native DefEq expression snapshot changed its bounded contract")
    nodes = value.get("nodes")
    require(isinstance(nodes, list) and 0 < len(nodes) <= 24, "invalid expression snapshot count")
    kinds = {"bvar", "fvar", "mvar", "sort", "const", "app", "lam",
             "forallE", "letE", "lit", "mdata", "proj"}
    require(all(isinstance(node, dict) and node.get("kind") in kinds
                and isinstance(node.get("path"), str) and len(node["path"]) <= 160
                for node in nodes), "invalid bounded expression snapshot node")


def validate_defeq_input(value: dict, label: str, index: int, policy: dict) -> None:
    authentic = label == "church-numerals"
    require(value.get("protocol") == "pskernel-arena-native-defeq-input/1"
            and value.get("sourceSha") == SOURCE and value.get("case") == label
            and type(value.get("declarationIndex")) is int and value["declarationIndex"] == index
            and type(value.get("fuel")) is int and value["fuel"] == policy["fuel"]
            and value.get("sourceTypesChecked") is authentic
            and value.get("bodySha256") == (BODY if authentic else None)
            and value.get("inferredTypeMatchesSource") is (True if authentic else None)
            and value.get("claimedTypeMatchesSource") is (True if authentic else None),
            "native actual DefEq input identity or source-type check differs")
    validate_expr_view(value.get("inferredType"))
    validate_expr_view(value.get("claimedType"))


def validate_defeq_events(events: list[dict]) -> None:
    require(0 < len(events) <= 49, "native DefEq failure trace empty or over cap")
    prior = -1
    for event in events:
        fuel = event.get("ownerFuel")
        stage = event.get("stage")
        require(event.get("protocol") == "pskernel-arena-native-defeq-event/1"
                and event.get("sourceSha") == SOURCE and event.get("phase") == "error"
                and type(fuel) is int and 0 <= fuel <= 4096
                and (fuel >= 4080 or fuel <= 16 or fuel % 256 == 0)
                and fuel > prior and stage in DEFEQ_STAGES
                and type(event.get("recursiveDefEqFuel")) is int
                and event["recursiveDefEqFuel"] == max(0, fuel - 1),
                "native DefEq trace identity, selection or unwind order differs")
        prior = fuel
        guarded = stage in {"zero-guard", "depth-guard"}
        require(event.get("guardWithoutSyntaxInspection") is guarded,
                "native DefEq guard inspection marker differs")
        if stage == "zero-guard":
            require(fuel == 0, "native DefEq zero guard was not at zero fuel")
        if guarded:
            require(not {"left", "right", "recDepth", "nextFresh"} & event.keys(),
                    "native DefEq guard observation inspected syntax or state")
        else:
            require(type(event.get("recDepth")) is int and event["recDepth"] >= 0
                    and type(event.get("nextFresh")) is int and event["nextFresh"] >= 0,
                    "native DefEq snapshot lacks actual input owner state")
            validate_expr_view(event.get("left"))
            validate_expr_view(event.get("right"))
        message = event.get("message")
        require(isinstance(message, dict) and isinstance(message.get("text"), str)
                and message.get("truncated") is False
                and type(message.get("utf8ByteSize")) is int
                and message["utf8ByteSize"] == len(message["text"].encode("utf-8"))
                and message["utf8ByteSize"] <= 256 and len(message["text"]) <= 64,
                "native DefEq observed error message was truncated or malformed")


def validate_defeq_parser_controls(event: dict, snapshot: dict) -> int:
    def refused(action):
        try:
            action()
        except ValueError:
            return
        raise ValueError("native DefEq parser accepted a deliberately corrupted receipt")
    for update in (
        {"sourceSha": "0" * 40}, {"ownerFuel": 4097}, {"ownerFuel": 17},
        {"stage": "unknown"}, {"left": {}},
    ):
        changed = json.loads(json.dumps(event))
        changed.update(update)
        refused(lambda changed=changed: validate_defeq_events([changed]))
    changed = json.loads(json.dumps(event))
    changed["message"]["truncated"] = True
    refused(lambda: validate_defeq_events([changed]))
    refused(lambda: validate_defeq_events([event, event]))
    changed_input = json.loads(json.dumps(snapshot))
    changed_input["sourceSha"] = "0" * 40
    refused(lambda: validate_defeq_input(changed_input, "defeq-positive", 0, POLICY))
    changed_input = json.loads(json.dumps(snapshot))
    changed_input["inferredType"]["nodeVisitLimit"] = 25
    refused(lambda: validate_defeq_input(changed_input, "defeq-positive", 0, POLICY))
    return 9


def print_compile_failure_logs(out: pathlib.Path, names: tuple[str, ...]) -> None:
    # Preserve the complete files in the artifact; expose a bounded diagnostic tail.
    for name in names:
        path = out / name
        data = path.read_bytes()
        limit = 262144
        print("PSC1_ARENA_NATIVE_COMPILE_LOG " + json.dumps({
            "name": name, "bytes": len(data), "sha256": digest(data),
            "printed_tail_bytes": min(len(data), limit), "truncated": len(data) > limit
        }), flush=True)
        print(data[-limit:].decode("utf-8", errors="replace"), flush=True)


def audit_defeq_proofs(lake: pathlib.Path, source: pathlib.Path, config: pathlib.Path,
                      trace: pathlib.Path, out: pathlib.Path, report: dict) -> None:
    command = [str(lake), "-f", config.name, "env", "lean", str(trace.relative_to(source))]
    started = time.monotonic()
    stdout_path, stderr_path = out / "defeq-proof.stdout.txt", out / "defeq-proof.stderr.txt"
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        result = subprocess.run(command, cwd=source, stdout=stdout, stderr=stderr, timeout=120)
    receipt = {"command": command, "returncode": result.returncode,
               "wall_seconds": time.monotonic() - started, "source_sha256": file_digest(trace),
               "stdout_sha256": file_digest(stdout_path), "stderr_sha256": file_digest(stderr_path)}
    report["defeq_proof_gate"] = receipt
    if result.returncode != 0:
        print_compile_failure_logs(out, ("defeq-proof.stdout.txt", "defeq-proof.stderr.txt"))
    require(result.returncode == 0, "native frozen/observer equivalence proof compilation failed")
    output = stdout_path.read_text(encoding="utf-8", errors="strict")
    pattern = re.compile(
        r"'NativeChurchDefEqTrace\.([A-Za-z_]+)' (?:does not depend on any axioms|"
        r"depends on axioms:\s*\[([^\]]*)\])")
    matches = pattern.findall(output)
    require(len(matches) == 5 and tuple(name for name, _ in matches) == DEFEQ_PROOFS,
            "native DefEq proof gate omitted or duplicated an axiom report")
    printed = {}
    allowed = {"propext", "Classical.choice", "Quot.sound"}
    for name, raw in matches:
        axioms = [item.strip() for item in raw.split(",") if item.strip()]
        require(set(axioms) <= allowed, "native DefEq proof uses an unapproved axiom: " + name)
        printed[name] = axioms
    require("sorryAx" not in output and "declaration uses 'sorry'" not in output,
            "native DefEq proof gate contains an unfinished proof")
    receipt.update(passed=True, count=5, axioms=printed,
                   scope="host-only exact frozen V1 worker and identity observer equivalence")
    print("PSC1_ARENA_NATIVE_DEFEQ_PROOFS: PASS count=5", flush=True)


def collect_defeq(binary: pathlib.Path, out: pathlib.Path, runner, report: dict) -> None:
    print("PSC1_ARENA_NATIVE_DEFEQ_START pinned_source=" + SOURCE + " fuel=4096", flush=True)
    controls_dir = out / "defeq-controls"
    controls_dir.mkdir()
    controls = runner.run_native(binary, controls_dir, controls_dir / "stdout.txt",
                                 controls_dir / "stderr.txt", arguments=("--defeq-controls",))
    report["defeq_controls"] = controls
    require(controls.get("status") == "process_exit" and controls.get("cleanupOk") is True
            and controls.get("returncode") == 0, "native DefEq controls did not complete")
    protocol = defeq_output(controls_dir / "stdout.txt", True)
    require(protocol.get("protocol") == "pskernel-arena-native-defeq-controls/1"
            and protocol.get("sourceSha") == SOURCE and protocol.get("count") == 4
            and protocol.get("metadataValidated") is False and protocol.get("arenaMatchClaimed") is False,
            "native DefEq control identity differs")
    cases = protocol.get("cases")
    require(isinstance(cases, list) and len(cases) == 3, "native DefEq stage controls omitted a case")
    stages, inputs, events = defeq_observations(controls_dir / "stderr.txt")
    labels = ("defeq-positive", "defeq-invalid", "defeq-resource")
    grouped = {label: [event for event in stages if event.get("case") == label] for label in labels}
    require([event for label in labels for event in grouped[label]] == stages,
            "native DefEq control stages unknown or reordered")
    for value, label in zip(cases, labels):
        policy = dict(POLICY, fuel=0) if label == "defeq-resource" else POLICY
        validate_staged_case(value, grouped[label], label, 0, policy, 0)
        require(value.get("typeDefEqObserved") is True, "native DefEq control did not select observer")
    require([value["outcome"] for value in cases] ==
            ["native_admission_complete", "rejectedInvalid", "resourceExhausted"]
            and [value["firstFailingStage"] for value in cases] == [None, "type-defeq", "preflight"]
            and cases[0].get("environmentDeclarations") == 1
            and cases[1].get("message") == "theorem proof type mismatch"
            and cases[2].get("resource") == "fuel"
            and cases[2].get("message") == "resource policy declined operation before entry",
            "native DefEq actual positive/invalid/resource obligations failed")
    require(len(inputs) == 2, "native DefEq control input snapshot count differs")
    for snapshot, label in zip(inputs, labels[:2]):
        validate_defeq_input(snapshot, label, 0, POLICY)
    validate_defeq_events(events)
    require(len(events) == 1 and events[0]["stage"] == "zero-guard"
            and events[0]["message"]["text"] == "kernel definitional equality budget exhausted"
            and protocol.get("zeroGuard") == {
                "fuel": 0, "sameAsUnmodifiedWorker": True,
                "message": "kernel definitional equality budget exhausted",
                "invalidSyntaxNotInspected": True},
            "native zero-fuel observation did not preserve the mandatory entry guard")
    controls.update(protocol=protocol, stage_events=stages, input_snapshots=inputs, events=events)
    count = validate_defeq_parser_controls(events[0], inputs[0])
    report["defeq_protocol_controls"] = {"passed": True, "count": count}
    print(f"PSC1_ARENA_NATIVE_DEFEQ_PARSER_CONTROLS: PASS count={count}", flush=True)
    print("PSC1_ARENA_NATIVE_DEFEQ_CONTROLS_VALIDATED count=4", flush=True)

    case_dir = out / "defeq-trace"
    case_dir.mkdir()
    measurement = runner.run_native(binary, case_dir, case_dir / "stdout.txt",
                                    case_dir / "stderr.txt", arguments=("--defeq-trace",))
    probe = {"measurement": measurement, "diagnostics_complete": False,
             "metadata_validated": False, "arena_match_claimed": False}
    report["defeq_probe"] = probe
    require(measurement.get("status") == "process_exit" and measurement.get("cleanupOk") is True
            and measurement.get("returncode") == 0,
            "native DefEq trace did not finish; no recursive failure path qualified")
    value = defeq_output(case_dir / "stdout.txt", False)
    stages, inputs, events = defeq_observations(case_dir / "stderr.txt")
    validate_staged_case(value, stages, "church-numerals", 3, POLICY, 5)
    require(value.get("typeDefEqObserved") is True and len(inputs) == 1,
            "native Church DefEq observer or actual input snapshot missing")
    validate_defeq_input(inputs[0], "church-numerals", 3, POLICY)
    validate_defeq_events(events)
    baseline = report.get("case", {}).get("protocol", {})
    require(baseline.get("acceptedRequests") == 3 and baseline.get("declarationIndex") == 3
            and baseline.get("outcome") == "resourceExhausted" and baseline.get("resource") == "fuel"
            and baseline.get("message") == "kernel reduction budget exhausted"
            and value.get("outcome") == baseline["outcome"]
            and value.get("resource") == baseline["resource"]
            and value.get("message") == baseline["message"]
            and value.get("firstFailingStage") == "type-defeq"
            and events[-1]["ownerFuel"] == 4096
            and all(event["message"]["text"] == baseline["message"] for event in events),
            "native DefEq trace does not reproduce the independent original API resource result")
    probe.update(protocol=value, stage_events=stages, input_snapshots=inputs, events=events,
                 diagnostics_complete=True, selected_owner_fuel_levels=len(events),
                 maximum_observed_frames=49, maximum_expression_visits=24,
                 observation_only=True)
    print("PSC1_ARENA_NATIVE_DEFEQ_COMPLETE " + json.dumps({
        "source_sha": SOURCE, "declaration_index": 3, "fuel": 4096,
        "observed_frames": len(events), "first_observed_stage": events[0]["stage"],
        "first_observed_owner_fuel": events[0]["ownerFuel"],
        "same_as_unmodified_api": True, "outcome": value["outcome"],
        "resource": value["resource"], "kernel_qualified": False}), flush=True)


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
    trace_source = HERE.parent / "host/arena-native-v1/NativeChurchDefEqTrace.lean"
    trace = work / "NativeChurchDefEqTrace.lean"
    shutil.copyfile(trace_source, trace)
    knot = source / "packages/pskernel-core/src/Ps/KernelCore/Checker/Knot.lean"
    knot_text = knot.read_text(encoding="utf-8")
    start = knot_text.index("def psKernelIsDefEqWithFuel\n")
    finish = knot_text.index("\ndef psKernelIsDefEq\n", start)
    frozen = knot_text[start:finish].replace("psKernelIsDefEqWithFuel", "frozenWithFuel")
    require(trace.read_text(encoding="utf-8").count(frozen) == 1,
            "native trace does not contain the exact pinned original frozen worker")
    report.update(defeq_observer_source_sha256=file_digest(trace),
                  original_defeq_knot_sha256=file_digest(knot), frozen_defeq_worker_sha256=digest(frozen.encode()))
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
            and exported_receipt.get("fixture_sha256") == file_digest(fixture) == FIXTURE_SHA
            and exported_receipt.get("generator_sha256") == file_digest(exporter) == EXPORTER_SHA
            and exported_receipt.get("generated_admission_invoked") is False
            and exported_receipt.get("requires_native_decode_checked") is True,
            "native fixture export receipt differs")
    report.update(input_export=exported_receipt, input_export_wall_seconds=time.monotonic() - started,
                  host_source_sha256=file_digest(host), exporter_sha256=file_digest(exporter))
    config = source / "kernel-native-church-lakefile.lean"
    fresh_write(config, original_config + APPEND_CONFIG.encode())
    for original in [host, trace, fixture, config]:
        shutil.copyfile(original, out / original.name)
    report["generated_lakefile_sha256"] = file_digest(config)
    build_command = [str(lake), "-f", config.name, "build", TARGET]
    started = time.monotonic()
    with (out / "build.stdout.txt").open("wb") as stdout, (out / "build.stderr.txt").open("wb") as stderr:
        built = subprocess.run(build_command, cwd=source, stdout=stdout, stderr=stderr, timeout=900)
    report["build"] = {"command": build_command, "returncode": built.returncode,
                       "wall_seconds": time.monotonic() - started}
    if built.returncode != 0:
        print_compile_failure_logs(out, ("build.stdout.txt", "build.stderr.txt"))
    require(built.returncode == 0, "native diagnostic build failed")
    require((source / "kernel-lakefile.lean").read_bytes() == original_config,
            "original kernel lakefile changed during diagnostic build")
    require(not command_output(["git", "-C", str(source), "diff", "--name-only", "--",
                "packages/pskernel-core/src", "kernel-lakefile.lean", "lean-toolchain"], source),
            "tracked kernel source changed during native build")
    audit_defeq_proofs(lake, source, config, trace, out, report)
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
    collect_stages(binary, out, runner, report)
    collect_defeq(binary, out, runner, report)
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

