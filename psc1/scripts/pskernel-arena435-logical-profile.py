#!/usr/bin/env python3
"""Diagnostic logical stacks for the authenticated generated Arena checker.

This makes a separate instrumented copy after authentic compilation. Production
artifacts, unprofiled comparisons and V8 profiles remain unchanged. The trace is
not a kernel certificate, conformance gate, source map, or timing comparison.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_profile", HERE / "pskernel-arena435-profile.py")
PROFILE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROFILE)
COMPARE = PROFILE.COMPARE
ORACLE = PROFILE.ORACLE

# TypeScript 7.0.2's type-erased version of BackendTs/Module.lean's runtime.
# Only whitespace and optional parentheses immediately around yield may vary.
EXPECTED_RUNTIME = """
const __ps$implementations = new WeakMap();
function __ps$run(root) {
    const pending = [root];
    let value = undefined;
    while (pending.length !== 0) {
        const next = pending[pending.length - 1].next(value);
        if (next.done) { pending.pop(); value = next.value; }
        else {
            const { fn, args } = next.value;
            const implementation = __ps$implementations.get(fn);
            if (implementation) {
                pending.push(Reflect.apply(implementation, undefined, args));
                value = undefined;
            }
            else value = Reflect.apply(fn, undefined, args);
        }
    }
    return value;
}
function __ps$wrap(implementation) {
    const fn = (...args) => __ps$run(implementation(...args));
    __ps$implementations.set(fn, implementation);
    return fn;
}
function* __ps$invoke(fn, ...args) {
    return (yield { fn, args });
}
"""

INSTRUMENTED_RUNTIME = r"""
import { appendFileSync as __ps$traceAppend } from 'node:fs';
const __ps$tracePath = process.env.PSC1_LOGICAL_TRACE_PATH;
if (!__ps$tracePath) throw Error('logical trace path is required');
const __ps$traceOrigin = __PSC1_ORIGIN__;
const __ps$traceContexts = [];
let __ps$traceSteps = 0, __ps$traceSamples = 0, __ps$traceNextMs = 0;
const __ps$traceStarted = performance.now();
function __ps$traceWrite(value) {
    __ps$traceAppend(__ps$tracePath, JSON.stringify(value) + '\n');
}
__ps$traceWrite({format: 'psc1-logical-stack-v1', kind: 'header',
    origin: __ps$traceOrigin, instrumented: true, kernel_qualified: false,
    step_interval: 4096, minimum_interval_ms: 100, maximum_samples: 800,
    maximum_named_frames: 64, maximum_inspected_frames: 16384});
function __ps$tracePoll(force) {
    if (__ps$traceSamples >= 800) return;
    const now = performance.now();
    if (!force && now < __ps$traceNextMs) return;
    __ps$traceNextMs = now + 100;
    const frames = [];
    let inspected = 0, logicalDepth = 0, truncated = false;
    for (const context of __ps$traceContexts) logicalDepth += context.length;
    outer: for (let c = __ps$traceContexts.length - 1; c >= 0; --c) {
        const context = __ps$traceContexts[c];
        for (let i = context.length - 1; i >= 0; --i) {
            if (++inspected > 16384) { truncated = true; break outer; }
            const name = context[i];
            if (!name || name === '<anonymous>') continue;
            const previous = frames[frames.length - 1];
            if (previous && previous.name === name) ++previous.repetitions;
            else {
                if (frames.length === 64) { truncated = true; break outer; }
                frames.push({name, repetitions: 1});
            }
        }
    }
    const memory = process.memoryUsage();
    __ps$traceWrite({format: 'psc1-logical-stack-v1', kind: 'sample',
        sample: __ps$traceSamples++, steps: __ps$traceSteps,
        elapsed_ms_since_import: now - __ps$traceStarted, epoch_ms: Date.now(),
        logical_depth: logicalDepth, nested_runs: __ps$traceContexts.length,
        inspected_frames: Math.min(inspected, 16384), truncated,
        nearest_named_frames_first: frames, rss_bytes: memory.rss,
        heap_used_bytes: memory.heapUsed, kernel_qualified: false});
}
process.on('exit', () => {
    __ps$tracePoll(true);
    __ps$traceWrite({format: 'psc1-logical-stack-v1', kind: 'exit',
        steps: __ps$traceSteps, samples: __ps$traceSamples,
        unfinished_runs: __ps$traceContexts.length, kernel_qualified: false});
});
const __ps$implementations = new WeakMap();
function __ps$run(root) {
    const pending = [root];
    const labels = ['<anonymous>'];
    __ps$traceContexts.push(labels);
    let value = undefined;
    try {
        while (pending.length !== 0) {
            ++__ps$traceSteps;
            if ((__ps$traceSteps & 4095) === 0) __ps$tracePoll(false);
            const next = pending[pending.length - 1].next(value);
            if (next.done) {
                pending.pop(); labels.pop(); value = next.value;
            }
            else {
                const { fn, args } = next.value;
                const implementation = __ps$implementations.get(fn);
                if (implementation) {
                    pending.push(Reflect.apply(implementation, undefined, args));
                    labels.push(implementation.name ? implementation.name.slice(0, 160) : '<anonymous>');
                    value = undefined;
                }
                else value = Reflect.apply(fn, undefined, args);
            }
        }
        return value;
    }
    finally {
        __ps$traceContexts.pop();
    }
}
function __ps$wrap(implementation) {
    const fn = (...args) => __ps$run(implementation(...args));
    __ps$implementations.set(fn, implementation);
    return fn;
}
function* __ps$invoke(fn, ...args) {
    return (yield { fn, args });
}
"""


def normalized(text: str) -> str:
    return re.sub(r"\s+", "", text)


def instrument(kernel: pathlib.Path, destination: pathlib.Path, source_sha: str) -> dict:
    source = kernel.read_text(encoding="utf-8")
    if source.count("const __ps$implementations = new WeakMap();") != 1:
        raise ValueError("generated runtime identity is not unique")
    start = source.index("const __ps$implementations = new WeakMap();")
    invoke = source.index("function* __ps$invoke(", start)
    end = source.index("\n}", invoke) + 2
    original = source[start:end]
    expected = normalized(EXPECTED_RUNTIME)
    actual = normalized(original)
    allowed = {expected, expected.replace("return(yield{fn,args});", "returnyield{fn,args};")}
    if actual not in allowed:
        raise ValueError("generated trampoline differs from the reviewed exact runtime")
    origin = {"source_sha": source_sha, "kernel_sha256": PROFILE.digest(kernel),
              "original_runtime_sha256": hashlib.sha256(original.encode()).hexdigest()}
    changed = INSTRUMENTED_RUNTIME.replace("__PSC1_ORIGIN__", json.dumps(origin, sort_keys=True))
    tail = re.sub(r"(?m)^//# sourceMappingURL=.*(?:\n|$)", "", source[end:])
    destination.write_text(source[:start] + changed + tail, encoding="utf-8")
    return dict(origin, instrumented_sha256=PROFILE.digest(destination),
                source_maps_apply_to_instrumented_copy=False,
                production_runtime_modified=False)


def trace_summary(path: pathlib.Path) -> dict:
    rows = []
    incomplete_tail = False
    if path.exists():
        with path.open(encoding="utf-8") as stream:
            for line in stream:
                if not line.endswith("\n"):
                    incomplete_tail = True
                    break
                rows.append(json.loads(line))
                if len(rows) > 802:
                    raise ValueError("logical trace exceeded its fixed record bound")
    if not rows or rows[0].get("format") != "psc1-logical-stack-v1" or rows[0].get("kind") != "header":
        raise ValueError("missing logical trace identity")
    if any(row.get("kernel_qualified") is not False for row in rows):
        raise ValueError("diagnostic trace claimed kernel qualification")
    samples = [row for row in rows if row.get("kind") == "sample"]
    if not samples or len(samples) > 800:
        raise ValueError("missing samples or trace bound exceeded")
    inclusive = collections.Counter()
    nearest = collections.Counter()
    for sample in samples:
        frames = sample["nearest_named_frames_first"]
        if len(frames) > 64 or sample["inspected_frames"] > 16384:
            raise ValueError("logical frame bound exceeded")
        names = [frame["name"] for frame in frames]
        inclusive.update(set(names))
        if names:
            nearest[names[0]] += 1
    return {"trace_sha256": PROFILE.digest(path), "samples": len(samples),
            "observed_steps": samples[-1]["steps"],
            "maximum_observed_logical_depth": max(row["logical_depth"] for row in samples),
            "incomplete_tail_ignored": incomplete_tail,
            "normal_exit_recorded": any(row.get("kind") == "exit" for row in rows),
            "nearest_named_frame_samples": nearest.most_common(24),
            "inclusive_named_frame_samples": inclusive.most_common(32),
            "sampled_stacks": samples[::max(1, len(samples) // 8)][:8],
            "instrumented_timing_is_not_a_performance_comparison": True}


def invoke_traced(command: list[str], cwd: pathlib.Path, stdout: pathlib.Path,
                  stderr: pathlib.Path, trace: pathlib.Path, seconds: int) -> dict:
    previous = os.environ.get("PSC1_LOGICAL_TRACE_PATH")
    os.environ["PSC1_LOGICAL_TRACE_PATH"] = str(trace)
    try:
        return PROFILE.invoke_bounded(command, cwd, stdout, stderr, seconds, True)
    finally:
        if previous is None:
            os.environ.pop("PSC1_LOGICAL_TRACE_PATH", None)
        else:
            os.environ["PSC1_LOGICAL_TRACE_PATH"] = previous


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=pathlib.Path, required=True)
    parser.add_argument("--kernel", type=pathlib.Path, required=True)
    parser.add_argument("--baseline-report", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    source_sha = os.environ.get("GITHUB_SHA", "")
    if re.fullmatch(r"[0-9a-f]{40}", source_sha) is None:
        parser.error("GITHUB_SHA must name the exact Actions revision")
    node_name = shutil.which("node")
    if node_name is None:
        parser.error("Node.js is required")
    node = pathlib.Path(node_name).resolve(strict=True)
    kernel = args.kernel.resolve(strict=True)
    baseline_path = args.baseline_report.resolve(strict=True)
    baseline = json.loads(baseline_path.read_text())
    if (baseline.get("format") != "psc1-authentic-arena-diagnostics-v1"
            or baseline.get("source_sha") != source_sha
            or baseline.get("kernel_sha256") != PROFILE.digest(kernel)
            or baseline.get("archive_sha256") != ORACLE.ARCHIVE_SHA256
            or baseline.get("diagnostics_complete") is not True):
        parser.error("baseline is not the complete same-source authentic diagnostic run")
    baseline_cases = {(row["label"], row["name"]): row for row in baseline["cases"]}
    if set(baseline_cases) != set(PROFILE.CASES) or len(baseline["cases"]) != len(PROFILE.CASES):
        parser.error("baseline diagnostic case identities differ")
    corpus = {(label, name): original for label, name, original in ORACLE.read_archive(args.archive)}
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory(prefix="psc1-logical-profile-detached-") as tmp:
        detached = pathlib.Path(tmp)
        logical = detached / "kernel.logical.mjs"
        receipt = instrument(kernel, logical, source_sha)
        shutil.copyfile(logical, out / "kernel.logical.mjs")
        runner = detached / "pskernel-arena-replay.mjs"
        controls = detached / "pskernel-arena-replay-controls.mjs"
        shutil.copyfile(HERE / runner.name, runner)
        shutil.copyfile(HERE / controls.name, controls)
        syntax = PROFILE.invoke_bounded([str(node), "--check", str(logical)], detached,
            out / "syntax.stdout.txt", out / "syntax.stderr.txt", 30, True)
        if syntax["returncode"] != 0 or syntax["timed_out"]:
            raise ValueError("instrumented runtime failed syntax checking")
        control_out, control_err = out / "controls.stdout.txt", out / "controls.stderr.txt"
        control = invoke_traced([str(node), f"--max-old-space-size={PROFILE.OLD_SPACE_MIB}",
            str(controls), str(logical)], detached, control_out, control_err,
            out / "controls.logical.jsonl", 60)
        if (control["returncode"] != 0 or control["timed_out"]
                or "PSC1_ARENA_REPLAY_CONTROLS: PASS" not in control_out.read_text()):
            raise ValueError("instrumented detached positive/adversarial controls failed")
        control_trace = trace_summary(out / "controls.logical.jsonl")
        for index, identity in enumerate(PROFILE.CASES):
            label, name = identity
            previous = baseline_cases[identity]
            directory = out / f"case-{index:02d}-{pathlib.PurePosixPath(name).stem}"
            directory.mkdir()
            adapted, adaptation = ORACLE.adapt_header(corpus[identity])
            if adaptation != previous["adaptation"]:
                raise ValueError("logical run changed the authenticated body/header receipt")
            case = directory / "input.ndjson"
            case.write_bytes(adapted)
            stdout, stderr = directory / "logical.stdout.txt", directory / "logical.stderr.txt"
            trace = directory / "logical.jsonl"
            measurement = invoke_traced([str(node),
                f"--max-old-space-size={PROFILE.OLD_SPACE_MIB}", str(runner), str(logical), str(case)],
                detached, stdout, stderr, trace, PROFILE.WALL_SECONDS)
            outcome = PROFILE.profiled_outcome(measurement, stdout.read_text(), stderr.read_text(),
                                               PROFILE.digest(case))
            summary = trace_summary(trace)
            classification = COMPARE.classify(previous["official"], outcome)
            normal = previous["unprofiled"]
            assessed = normal["verdict"] != "timeout" and outcome["verdict"] != "timeout"
            stable = normal["verdict"] == outcome["verdict"] if assessed else None
            record = {"index": index, "label": label, "name": name, "adaptation": adaptation,
                      "official": previous["official"], "unprofiled": normal,
                      "logical": outcome, "classification": classification,
                      "completed_outcome_agreement": stable, "trace": summary,
                      "kernel_qualified": False}
            records.append(record)
            (directory / "report.json").write_text(json.dumps(record, indent=2) + "\n")
            print("PSC1_ARENA_LOGICAL_PROFILE " + json.dumps({
                "source_sha": source_sha, "name": name,
                "body_sha256": adaptation["original_body_sha256"],
                "unprofiled": normal["verdict"], "logical": outcome["verdict"],
                "samples": summary["samples"], "observed_steps": summary["observed_steps"],
                "maximum_observed_logical_depth": summary["maximum_observed_logical_depth"],
                "nearest": summary["nearest_named_frame_samples"],
                "inclusive": summary["inclusive_named_frame_samples"],
                "kernel_qualified": False}), flush=True)
            for sample in summary["sampled_stacks"]:
                print("PSC1_ARENA_LOGICAL_STACK " + json.dumps({
                    "name": name, "steps": sample["steps"],
                    "elapsed_ms_since_import": sample["elapsed_ms_since_import"],
                    "depth": sample["logical_depth"], "truncated": sample["truncated"],
                    "frames": sample["nearest_named_frames_first"],
                    "kernel_qualified": False}), flush=True)
    complete = (len(records) == len(PROFILE.CASES) and all(
        row["logical"]["verdict"] != "driver_error"
        and row["classification"] not in ("false_accept", "false_reject")
        and row["completed_outcome_agreement"] is not False for row in records))
    report = {"format": "psc1-authentic-arena-logical-diagnostics-v1", "source_sha": source_sha,
              "instrumentation": receipt, "baseline_report_sha256": PROFILE.digest(baseline_path),
              "driver_sha256": PROFILE.digest(pathlib.Path(__file__)),
              "replay_sha256": PROFILE.digest(HERE / "pskernel-arena-replay.mjs"),
              "archive_sha256": ORACLE.ARCHIVE_SHA256, "kernel_fuel": 4096,
              "host_wall_seconds_per_case": PROFILE.WALL_SECONDS,
              "node_old_space_limit_mib": PROFILE.OLD_SPACE_MIB, "runtime_path_empty": True,
              "control": control, "control_trace": control_trace, "cases": records,
              "diagnostics_complete": complete, "kernel_qualified": False,
              "limitations": [
                  "The instrumented copy is diagnostic only and is never the qualified artifact.",
                  "Trace steps count trampoline resumes, not kernel fuel or instructions.",
                  "Anonymous frames are omitted; named ancestors are bounded and may be truncated.",
                  "Synchronous non-generator code is not sampled inside a trampoline resume.",
                  "Frame frequencies are sampled observations, not complete operation costs.",
                  "Tracing adds CPU, memory and synchronous IO; its timing cannot measure speedup.",
                  "The original source map does not describe the instrumented copy.",
                  "SIGKILL may omit the final trace sample or incomplete last line."]}
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    manifest = [{"path": str(path.relative_to(out)), "sha256": PROFILE.digest(path)}
                for path in sorted(out.rglob("*")) if path.is_file() and path.name != "sha256.json"]
    (out / "sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("PSC1_ARENA_LOGICAL_COLLECTION: " + ("COMPLETE" if complete else "INCOMPLETE")
          + " cases=" + str(len(records)) + " kernel_qualified=false", flush=True)
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
