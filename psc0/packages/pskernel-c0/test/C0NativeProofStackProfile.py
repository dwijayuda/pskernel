#!/usr/bin/env python3
"""Bounded offline source-code hot-stack sampler for native C0 (diagnostics only).

Start the unchanged C0 executable with a separately compiled LD_PRELOAD
SIGUSR1 handler. Collect only stack traces and analyze symbol addresses.
No source checker, admission rule, resource budget or proof term is modified.
"""
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

PROFILE_BEGIN = "C0_WF_PROFILE_SAMPLE_BEGIN"
PROFILE_END = "C0_WF_PROFILE_SAMPLE_END"


def sample(exe, source, preload, log, samples, interval):
    env = dict(os.environ)
    env["LD_PRELOAD"] = str(preload)
    env["LEAN_BACKTRACE"] = "0"
    with log.open("w", encoding="utf8") as out:
        proc = subprocess.Popen(
            [str(exe), "--require-accepted", str(source), "4096"],
            env=env, stdout=out, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        attempts = 0
        for _ in range(samples):
            time.sleep(interval)
            if proc.poll() is not None:
                break
            try:
                os.kill(proc.pid, signal.SIGUSR1)
                attempts += 1
            except ProcessLookupError:
                break
        status = proc.poll()
        if status is None:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                proc.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait(timeout=8)
        print(f"C0_WF_PROFILE_INTENT samples={samples} interval_seconds={interval} sampled={attempts}")
        print(f"C0_WF_PROFILE_PROCESS status={status} diagnostic_stopped={status is None}")
    return attempts


def analyze(log: Path, binary: Path, summary: Path):
    source = log.read_text(encoding="utf8", errors="replace")
    chunks = source.split(PROFILE_BEGIN)[1:]
    stacks = [block.split(PROFILE_END)[0] for block in chunks if PROFILE_END in block]
    address_re = re.compile(r"\+0x([a-fA-F0-9]+)\)")
    addresses = []
    for block in stacks:
        addresses += address_re.findall(block)
    unique = list(dict.fromkeys(addresses))
    resolved = {}
    if unique:
        for start in range(0, len(unique), 180):
            portion = unique[start:start + 180]
            result = subprocess.run(
                ["addr2line", "-f", "-C", "-e", str(binary),
                 *("0x" + a for a in portion)],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=35,
            )
            lines = result.stdout.splitlines()
            for i, addr in enumerate(portion):
                resolved[addr] = {
                    "function": lines[2*i] if 2*i < len(lines) else "<unknown>",
                    "source": lines[2*i+1] if 2*i+1 < len(lines) else "<unknown>",
                }
    sampled_frames = []
    for b in stacks:
        sampled_frames.append([
            resolved.get(addr, {"function": "unknown", "source": "?"})
            for addr in address_re.findall(b)
        ])
    inclusive = Counter(fr["function"] for stack in sampled_frames for fr in set_as_unique(stack))
    deepest = Counter(
        next((f["function"] for f in stack[3:] if f["function"] not in ("??", "unknown")), "unknown")
        for stack in sampled_frames
    )
    report = {
        "diagnostic_only": True,
        "source_file": source.name if hasattr(source, "name") else log.name,
        "native_stack_samples": len(stacks),
        "successful_source_acceptance": "C0_REAL_EXPORT replay_outcome=C0ExportVerdict.accepted" in source,
        "top_inclusive_functions": inclusive.most_common(35),
        "top_active_functions": deepest.most_common(20),
        "example_stacks": sampled_frames[:4],
        "raw_profile_log": log.name,
        "no_trusted_code_modified": True,
    }
    summary.write_text(json.dumps(report, indent=2) + "\n")
    print("C0_WF_PROFILE_RESULT_BEGIN")
    print(json.dumps({k: v for k, v in report.items() if k != "example_stacks"}, indent=2))
    print("C0_WF_PROFILE_RESULT_END")


def set_as_unique(stack):
    seen = set()
    result = []
    for item in stack:
        fn = item["function"]
        if fn not in seen:
            seen.add(fn)
            result.append(item)
    return result


def main():
    arg = argparse.ArgumentParser(description=__doc__)
    arg.add_argument("binary", type=Path)
    arg.add_argument("source", type=Path)
    arg.add_argument("preload", type=Path)
    arg.add_argument("log", type=Path)
    arg.add_argument("summary", type=Path)
    arg.add_argument("--samples", type=int, default=12)
    arg.add_argument("--interval", type=float, default=5)
    a = arg.parse_args()
    if not (1 <= a.samples <= 20 and 0.5 <= a.interval <= 10):
        raise ValueError("sampling bounds cannot be disabled")
    exe, source, lib = (x.resolve() for x in (a.binary, a.source, a.preload))
    sample(exe, source, lib, a.log, a.samples, a.interval)
    analyze(a.log, exe, a.summary)


if __name__ == "__main__":
    main()
