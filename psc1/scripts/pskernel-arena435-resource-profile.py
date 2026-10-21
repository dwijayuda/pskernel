#!/usr/bin/env python3
"""Bounded first-resource-error attribution and checked V1 reference replay.

This is an authentic-case diagnostic, not a qualification or speedup gate.
Original and observed modules keep the same 4096 fuel, 60-second case wall
limit and 2048-MiB Node old-space cap. Only a separately hashed copy observes
trampoline calls/returns. A third replay selects the actual checked V1 API;
it is explicitly a reference implementation selection, not instrumentation.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import pathlib
import re
import shutil
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_logical", HERE / "pskernel-arena435-logical-profile.py")
LOGICAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LOGICAL)
PROFILE, COMPARE, ORACLE = LOGICAL.PROFILE, LOGICAL.COMPARE, LOGICAL.ORACLE
IDENTITY = ("good", "perf/church-numerals.ndjson")
BODY_SHA256 = "85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47"

# The original replay only constructs ordered admission commands. This copy
# retains every transport guard and every post-admission metadata comparison,
# but deliberately selects real V1AdmitDeclaration for each original request.
# DecodeChecked performs the same PagedValidate + DecodeCanonicalFuel ingress.
# One extra real refusal enters V1AdmitDeclaration through V1AdmitChecked, so
# the nested generated call is visible to the existing reviewed trampoline.
# The admitted declaration and cancellation policy are actual existing controls;
# no fake checked receipt, changed case fuel, or direct observer event is used.
RESOURCE_CONTROL_EXTENSION = r"""
const diagnosticCheckedResource=get('psKernelV1AdmitChecked')(cancelledSession,admitted.declaration);
must(diagnosticCheckedResource&&typeof diagnosticCheckedResource==='object'&&
  'error' in diagnosticCheckedResource&&
  kernelErrorVerdict(kernel,diagnosticCheckedResource.error)==='resource_exhausted',
  'checked V1 replay preserves actual cancelled resource refusal');
console.log('PSC1_RESOURCE_OBSERVER_CONTROL: PASS');
"""

V1_REPLAY_HOOK = r"""
    const diagnosticV1Batch=()=>{
      accepted(get('psKernelKernelSessionPreflight')(session),'kernel-admission');
      const decodeOutcome=value=>{
        if(value&&typeof value==='object'&&'error' in value&&typeof value.error==='string')
          return get('Except').error(get('PsKernelError').rejectedInvalid(value.error));
        return value;
      };
      const originalDecoded=accepted(decodeOutcome(
        get('psKernelExprV2DecodeChecked')(arena)),'kernel-admission');
      let owner=session;
      const actualReplies=[];
      for(const group of order){
        const declaration=accepted(decodeOutcome(
          get('psKernelDagDecodeDeclaration')(originalDecoded,group.request)),'kernel-admission');
        const admitted=accepted(get('psKernelV1AdmitDeclaration')(owner,declaration),'kernel-admission');
        owner=admitted.session;
        actualReplies.push(get('PsKernelDagReply').admitted(admitted.declaration.receipt));
      }
      return get('Except').ok({session:owner,replies:list(actualReplies)});
    };
"""


def replace_once(text: str, before: str, after: str) -> str:
    if text.count(before) != 1:
        raise ValueError("diagnostic source anchor is not unique: " + before[:120])
    return text.replace(before, after)


def prepare_v1_replay(source: pathlib.Path, destination: pathlib.Path) -> dict:
    text = source.read_text()
    anchor = "    const commands=order.map(group=>C.admit(group.request));\n"
    text = replace_once(text, anchor, anchor + V1_REPLAY_HOOK)
    text = replace_once(text,
        "get('psKernelV1RunDag')(session,nil,S.safe,arena,list(commands))",
        "diagnosticV1Batch()")
    destination.write_text(text)
    return {"original_replay_sha256": PROFILE.digest(source),
            "reference_replay_sha256": PROFILE.digest(destination),
            "reference_entry": "psKernelV1AdmitDeclaration",
            "validated_ingress": "psKernelExprV2DecodeChecked",
            "original_request_decode": "psKernelDagDecodeDeclaration",
            "original_transport_and_metadata_checks_retained": True,
            "reference_selection_changes_implementation": True,
            "production_runtime_modified": False, "kernel_qualified": False}


def prepare_resource_replay(source: pathlib.Path, destination: pathlib.Path) -> dict:
    hook = replace_once(LOGICAL.DECLINE_REPLAY_HOOK,
        "DiagnosticExcept.error('diagnostic tag'));",
        "DiagnosticExcept.error('diagnostic tag'),\n"
        "      get('PsKernelError').resourceExhausted(get('PsKernelResourceError').fuel,'diagnostic resource tag'),\n"
        "      get('PsKernelError').rejectedInvalid('diagnostic invalid tag'));")
    text = source.read_text()
    anchor = "    const commands=order.map(group=>C.admit(group.request));\n"
    destination.write_text(replace_once(text, anchor, anchor + hook))
    return {"original_replay_sha256": PROFILE.digest(source),
            "observed_replay_sha256": PROFILE.digest(destination),
            "semantic_call_unchanged": True}


def resource_messages(policy: pathlib.Path) -> list[str]:
    source = policy.read_text()
    messages = re.findall(r'String\.Internal\.append messagePrefix "([^"]+)"', source)
    if (len(messages) < 25 or len(messages) > 64
            or "kernel reduction budget exhausted" not in messages
            or "kernel recursor budget exhausted" not in messages):
        raise ValueError("pinned resource-message policy differs from the reviewed source")
    prefixes = ("", "nested preprocessing: ", "nested transformed admission: ",
                "nested original restoration: ", "nested auxiliary restoration: ",
                "nested restored validation: ")
    return sorted({prefix + message for prefix in prefixes for message in messages})


def resource_summary(path: pathlib.Path, source_hash: str | None = None) -> dict:
    base = LOGICAL.decline_summary(path, source_hash)
    rows = []
    for line in path.read_text().splitlines(keepends=True):
        if line.endswith("\n"):
            rows.append(json.loads(line))
    errors = [row for row in rows if row.get("kind") == "first_resource_error_return"]
    zero = [row for row in rows if row.get("kind") == "first_zero_fuel_entry"]
    if any(row.get("result", {}).get("error", {}).get("resource_error") is not True for row in errors):
        raise ValueError("resource trace contains an unclassified error")
    return dict(base, first_resource_error_returns=errors, first_zero_fuel_entries=zero,
                first_observed_resource_error=errors[0] if errors else None,
                maximum_live_frames=32768, maximum_events=512,
                sequential_call_count_uncapped=True,
                first_observed_error_is_attribution_not_a_soundness_proof=True)


def envelope(stdout: pathlib.Path) -> dict | None:
    lines = [line[len(COMPARE.PREFIX):] for line in stdout.read_text().splitlines()
             if line.startswith(COMPARE.PREFIX)]
    return json.loads(lines[0]) if len(lines) == 1 else None


def completed_agreement(left: dict, right: dict,
                        left_payload: dict | None, right_payload: dict | None) -> bool | None:
    if left["verdict"] == "timeout" or right["verdict"] == "timeout":
        return None
    # Heap termination, absent protocol, and driver errors are never represented
    # by null agreement. The collection remains incomplete in those situations.
    return (left_payload is not None and right_payload is not None
            and left["verdict"] != "driver_error" and right["verdict"] != "driver_error"
            and left_payload == right_payload)


def controls(node: pathlib.Path, directory: pathlib.Path, kernel: pathlib.Path,
             out: pathlib.Path, observed: bool) -> dict:
    stdout, stderr = out / "controls.stdout.txt", out / "controls.stderr.txt"
    command = [str(node), f"--max-old-space-size={PROFILE.OLD_SPACE_MIB}",
               str(directory / "pskernel-arena-replay-controls.mjs"), str(kernel)]
    if observed:
        measurement = LOGICAL.invoke_traced(command, directory, stdout, stderr,
                                             out / "controls.resource.jsonl", 60)
    else:
        measurement = PROFILE.invoke_bounded(command, directory, stdout, stderr, 60, True)
    if (measurement["returncode"] != 0 or measurement["timed_out"]
            or "PSC1_ARENA_REPLAY_CONTROLS: PASS count=138" not in stdout.read_text()
            or "PSC1_RESOURCE_OBSERVER_CONTROL: PASS" not in stdout.read_text()):
        raise ValueError("detached 138 positive/adversarial controls failed: " + out.name)
    result = dict(measurement, stdout_sha256=PROFILE.digest(stdout),
                  stderr_sha256=PROFILE.digest(stderr), original_control_count=138,
                  additional_resource_control_count=1,
                  control_source_sha256=PROFILE.digest(directory / "pskernel-arena-replay-controls.mjs"))
    if observed:
        summary = resource_summary(out / "controls.resource.jsonl")
        if (not summary["normal_exit_recorded"] or summary["observation_limited"]
                or not summary["first_resource_error_returns"]):
            raise ValueError("resource observer controls omitted real resource errors or complete unwind")
        result["trace"] = summary
    return result


def run_case(node: pathlib.Path, directory: pathlib.Path, kernel: pathlib.Path,
             case: pathlib.Path, out: pathlib.Path, observed: bool) -> tuple[dict, dict | None]:
    stdout, stderr = out / "case.stdout.txt", out / "case.stderr.txt"
    command = [str(node), f"--max-old-space-size={PROFILE.OLD_SPACE_MIB}",
               str(directory / "pskernel-arena-replay.mjs"), str(kernel), str(case)]
    if observed:
        measurement = LOGICAL.invoke_traced(command, directory, stdout, stderr,
                                             out / "case.resource.jsonl", PROFILE.WALL_SECONDS)
    else:
        measurement = PROFILE.invoke_bounded(command, directory, stdout, stderr,
                                             PROFILE.WALL_SECONDS, True)
    outcome = PROFILE.profiled_outcome(measurement, stdout.read_text(), stderr.read_text(),
                                       PROFILE.digest(case))
    (out / "outcome.json").write_text(json.dumps(outcome, indent=2) + "\n")
    return outcome, envelope(stdout)


def manifest(out: pathlib.Path) -> None:
    records = [{"path": str(path.relative_to(out)), "sha256": PROFILE.digest(path)}
               for path in sorted(out.rglob("*")) if path.is_file() and path.name != "sha256.json"]
    (out / "sha256.json").write_text(json.dumps(records, indent=2) + "\n")


def collect(args: argparse.Namespace) -> int:
    source_sha = args.source_sha
    if re.fullmatch(r"[0-9a-f]{40}", source_sha) is None:
        raise ValueError("source-sha must identify the exact compiled source")
    kernel, baseline_path = args.kernel.resolve(strict=True), args.baseline_report.resolve(strict=True)
    baseline = json.loads(baseline_path.read_text())
    if (baseline.get("format") != "psc1-authentic-arena-diagnostics-v1"
            or baseline.get("source_sha") != source_sha
            or baseline.get("kernel_sha256") != PROFILE.digest(kernel)
            or baseline.get("archive_sha256") != ORACLE.ARCHIVE_SHA256
            or baseline.get("diagnostics_complete") is not True):
        raise ValueError("baseline is not a complete same-source authentic profile collection")
    previous = [row for row in baseline["cases"] if (row["label"], row["name"]) == IDENTITY]
    if len(previous) != 1 or previous[0]["official"]["verdict"] != "accepted":
        raise ValueError("authentic church case/official reference identity differs")
    previous = previous[0]
    corpus = {(label, name): original for label, name, original in ORACLE.read_archive(args.archive)}
    adapted, adaptation = ORACLE.adapt_header(corpus[IDENTITY])
    if (adaptation != previous["adaptation"]
            or adaptation["original_body_sha256"] != BODY_SHA256):
        raise ValueError("resource diagnostic changed authenticated case bytes/header receipt")
    out = args.out.resolve()
    case = out / "input.ndjson"
    case.write_bytes(adapted)
    node_name = shutil.which("node")
    if node_name is None:
        raise ValueError("Node.js is required")
    node = pathlib.Path(node_name).resolve(strict=True)
    source_replay, source_controls = HERE / "pskernel-arena-replay.mjs", HERE / "pskernel-arena-replay-controls.mjs"
    messages = resource_messages(args.resource_policy.resolve(strict=True))
    helper_path = HERE / "pskernel-arena435-resource-observer.mjs"
    helper = replace_once(helper_path.read_text(), "__PSC1_RESOURCE_MESSAGES__", json.dumps(messages))
    with tempfile.TemporaryDirectory(prefix="psc1-arena-resource-detached-") as temporary:
        detached = pathlib.Path(temporary)
        modes, control_results, receipts = {}, {}, {}
        for mode in ("original", "observed", "reference_v1"):
            directory, evidence = detached / mode, out / mode
            directory.mkdir()
            evidence.mkdir()
            runtime, replay = directory / "kernel.mjs", directory / "pskernel-arena-replay.mjs"
            (directory / source_controls.name).write_text(source_controls.read_text() + RESOURCE_CONTROL_EXTENSION)
            if mode == "observed":
                receipts["instrumentation"] = LOGICAL.instrument(
                    kernel, runtime, source_sha, LOGICAL.decline_runtime(helper))
                receipts["observed_replay"] = prepare_resource_replay(source_replay, replay)
                shutil.copyfile(runtime, out / "kernel.resource.mjs")
                shutil.copyfile(replay, out / "replay.resource.mjs")
            else:
                shutil.copyfile(kernel, runtime)
                if mode == "reference_v1":
                    receipts["reference_v1_replay"] = prepare_v1_replay(source_replay, replay)
                    shutil.copyfile(replay, out / "replay.reference-v1.mjs")
                else:
                    shutil.copyfile(source_replay, replay)
                    shutil.copyfile(runtime, out / "kernel.original.mjs")
            for candidate in (runtime, replay):
                syntax = PROFILE.invoke_bounded([str(node), "--check", str(candidate)], directory,
                    evidence / (candidate.stem + ".syntax.stdout.txt"),
                    evidence / (candidate.stem + ".syntax.stderr.txt"), 30, True)
                if syntax["returncode"] != 0 or syntax["timed_out"]:
                    raise ValueError("diagnostic syntax guard failed: " + mode + "/" + candidate.name)
            control_results[mode] = controls(node, directory, runtime, evidence, mode == "observed")
            modes[mode] = (directory, runtime, evidence)
        if len({value["stdout_sha256"] for value in control_results.values()}) != 1:
            raise ValueError("detached original/observed/reference control outputs differ")
        outcomes, payloads = {}, {}
        for mode, (directory, runtime, evidence) in modes.items():
            outcomes[mode], payloads[mode] = run_case(node, directory, runtime, case, evidence,
                                                     mode == "observed")
            print("PSC1_ARENA_RESOURCE_CASE " + json.dumps({
                "source_sha": source_sha, "name": IDENTITY[1], "mode": mode,
                "body_sha256": BODY_SHA256, "outcome": outcomes[mode],
                "kernel_qualified": False}), flush=True)
        trace = resource_summary(out / "observed" / "case.resource.jsonl", PROFILE.digest(case))
        stable = completed_agreement(outcomes["original"], outcomes["observed"],
                                     payloads["original"], payloads["observed"])
        v1_stable = completed_agreement(outcomes["original"], outcomes["reference_v1"],
                                        payloads["original"], payloads["reference_v1"])
        baseline_completed = previous["unprofiled"]["verdict"] != "timeout" and outcomes["original"]["verdict"] != "timeout"
        baseline_stable = (all(previous["unprofiled"].get(key) == value
                               for key, value in payloads["original"].items())
                           if baseline_completed and payloads["original"] is not None else None)
        if baseline_completed and payloads["original"] is None:
            baseline_stable = False
        resource_observed = (outcomes["observed"]["verdict"] != "resource_exhausted"
                             or bool(trace["first_resource_error_returns"]))
        complete = (stable is not False and baseline_stable is not False
                    and not trace["observation_limited"]
                    and resource_observed
                    and all(value["verdict"] != "driver_error" for value in outcomes.values())
                    and all(COMPARE.classify(previous["official"], value) not in ("false_accept", "false_reject")
                            for value in outcomes.values()))
        report = {"format": "psc1-authentic-arena-resource-diagnostics-v1",
            "source_sha": source_sha, "workflow_source_sha": os.environ.get("GITHUB_SHA", ""),
            "name": IDENTITY[1], "adaptation": adaptation, "official": previous["official"],
            "archive_sha256": ORACLE.ARCHIVE_SHA256, "kernel_sha256": PROFILE.digest(kernel),
            "baseline_report_sha256": PROFILE.digest(baseline_path),
            "resource_policy_sha256": PROFILE.digest(args.resource_policy),
            "observer_sha256": PROFILE.digest(helper_path),
            "driver_sha256": PROFILE.digest(pathlib.Path(__file__)), "receipts": receipts,
            "controls": control_results, "outcomes": outcomes, "protocol_envelopes": payloads,
            "completed_original_observed_agreement": stable,
            "completed_original_v1_reference_agreement": v1_stable,
            "completed_baseline_original_agreement": baseline_stable,
            "v1_reference_process_terminated_before_wall_limit": outcomes["reference_v1"]["verdict"] != "timeout",
            "v1_reference_protocol_completed": (payloads["reference_v1"] is not None
                and outcomes["reference_v1"]["verdict"] != "driver_error"),
            "trace": trace, "kernel_fuel": 4096, "host_wall_seconds_per_case": PROFILE.WALL_SECONDS,
            "node_old_space_limit_mib": PROFILE.OLD_SPACE_MIB, "runtime_path_empty": True,
            "diagnostics_complete": complete, "kernel_qualified": False,
            "limitations": [
                "The observed copy adds allocation, dispatch and IO overhead; its timing is not a speed comparison.",
                "The Node old-space cap is not an operating-system RSS limit.",
                "First error and callback ownership are bounded observations, not a proof of semantic causation.",
                "Returned aliases retain the innermost recorded identity; callback attribution does not prove captured fuel.",
                "The V1 reference selects the checked V1 API; it is not the unchanged production RunDag path.",
                "Resource exhaustion remains a non-verdict for official conformance; timeout agreement is null.",
                "The full 193-case qualification and original V8 profiles remain separate."]}
        (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        print("PSC1_ARENA_RESOURCE_PROVENANCE " + json.dumps({
            "source_sha": source_sha, "name": IDENTITY[1], "body_sha256": BODY_SHA256,
            "completed_original_observed_agreement": stable,
            "completed_original_v1_reference_agreement": v1_stable,
            "observation_limited": trace["observation_limited"],
            "first_zero_fuel_entries": trace["first_zero_fuel_entries"][:8],
            "first_resource_error_returns": trace["first_resource_error_returns"][:8],
            "trace_sha256": trace["trace_sha256"], "kernel_qualified": False}), flush=True)
        print("PSC1_ARENA_RESOURCE_COLLECTION: " + ("COMPLETE" if complete else "INCOMPLETE")
              + " cases=1 kernel_qualified=false", flush=True)
        return 0 if complete else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("archive", "kernel", "baseline-report", "resource-policy", "out"):
        parser.add_argument("--" + name, type=pathlib.Path, required=True)
    parser.add_argument("--source-sha", required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    try:
        return collect(args)
    except Exception as error:
        (args.out / "collection-failure.json").write_text(json.dumps({
            "source_sha": args.source_sha, "error_type": type(error).__name__,
            "reason": str(error), "kernel_qualified": False}, indent=2) + "\n")
        raise
    finally:
        manifest(args.out)


if __name__ == "__main__":
    sys.exit(main())
