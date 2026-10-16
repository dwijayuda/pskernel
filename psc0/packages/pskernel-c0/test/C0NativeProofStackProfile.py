#!/usr/bin/env python3
"""Bounded offline source-code hot-stack sampler for native C0 (diagnostics only).

Start the unchanged C0 executable with a separately compiled LD_PRELOAD
SIGUSR1 handler. Collect only stack traces and analyze symbol addresses.
No source checker, admission rule, resource budget or proof term is modified.
"""
import argparse
from bisect import bisect_right
from collections import Counter
import ctypes
import json
import os
from pathlib import Path
import platform
import re
import signal
import subprocess
import time

PROFILE_BEGIN = "C0_WF_PROFILE_SAMPLE_BEGIN"
PROFILE_END = "C0_WF_PROFILE_SAMPLE_END"


def sample(exe, source, preload, log, samples, interval, wait_for=None, max_wait=800):
    env = dict(os.environ)
    env["LD_PRELOAD"] = str(preload)
    env["LEAN_BACKTRACE"] = "0"
    with log.open("w", encoding="utf8") as out:
        cmd = [str(exe), "--require-accepted", str(source), "4096"]
        if wait_for is not None:
            # Buffer only active-declaration trace output. The C0 binary
            # still runs the unchanged source checker at the same fuel.
            cmd = ["stdbuf", "-oL", "-eL", str(exe),
                   "--require-accepted", "--trace-declarations",
                   str(source), "4096"]
        proc = subprocess.Popen(
            cmd,
            env=env, stdout=out, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        attempts = 0
        worker_attempts = 0
        assert platform.machine() == "x86_64", "tgkill syscall pinned to x86_64 runner"
        libc = ctypes.CDLL(None, use_errno=True)
        SYS_tgkill = 234
        reached = wait_for is None
        if wait_for is not None:
            # Wait until the exact problematic declaration enters its native
            # proof-body checker; sampling from startup confounds the heavy
            # theorem with initial environment checking.
            needle = wait_for.encode("utf8")
            cursor = 0
            carry = b""
            for _ in range(max_wait):
                time.sleep(1)
                if proc.poll() is not None:
                    break
                with log.open("rb") as reader:
                    reader.seek(cursor)
                    fragment = reader.read()
                    cursor = reader.tell()
                if needle in carry + fragment:
                    reached = True
                    print(f"C0_PROFILE_TARGET_REACHED marker={wait_for}")
                    break
                carry = (carry + fragment)[-len(needle):]
            if not reached:
                print(f"C0_PROFILE_TARGET_NOT_REACHED marker={wait_for} max_wait={max_wait}")
        for iteration in range(samples if reached else 0):
            time.sleep(interval)
            if proc.poll() is not None:
                break
            # Native Lean's main thread waits for run_with_thread_stack's
            # checker worker. Sampling the PID only sees that idle main
            # thread, not the executable checker. Inspect its LWP threads.
            task_dir = Path(f"/proc/{proc.pid}/task")
            status = []
            for tid_path in task_dir.iterdir():
                try:
                    stat = (tid_path / "stat").read_text()
                    state = stat.rsplit(") ", 1)[1].split()[0]
                    tid = int(tid_path.name)
                    status.append((tid, state))
                except (OSError, ValueError, IndexError):
                    continue
            active = sorted(t for t, st in status
                            if t != proc.pid and st == "R")
            others = sorted(t for t, st in status if t != proc.pid)
            if not others:
                print(f"C0_WF_PROFILE_NO_WORKER sample={iteration} threads={status}")
                continue
            chosen = active[iteration % len(active)] if active else others[iteration % len(others)]
            result = libc.syscall(SYS_tgkill, proc.pid, chosen, signal.SIGUSR1)
            if result == 0:
                attempts += 1
                worker_attempts += 1
                print(f"C0_WF_PROFILE_WORKER sample={iteration} tid={chosen} state={dict(status).get(chosen)}")
            else:
                print(f"C0_WF_PROFILE_SIGNAL_FAILED sample={iteration} tid={chosen} errno={ctypes.get_errno()}")
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
        print(f"C0_WF_PROFILE_WORKER_SAMPLES={worker_attempts}")
        print(f"C0_WF_PROFILE_PROCESS status={status} diagnostic_stopped={status is None}")
    return attempts, reached


def analyze(log: Path, binary: Path, summary: Path):
    source = log.read_text(encoding="utf8", errors="replace")
    chunks = source.split(PROFILE_BEGIN)[1:]
    stacks = [block.split(PROFILE_END)[0] for block in chunks if PROFILE_END in block]
    address_re = re.compile(r"\+0x([a-fA-F0-9]+)\)")
    exe_lines = []
    for block in stacks:
        exe_lines.extend(line for line in block.splitlines()
                         if str(binary) in line)
    addresses = [
        match.group(1) for line in exe_lines
        if (match := address_re.search(line)) is not None
    ]
    unique = list(dict.fromkeys(addresses))
    resolved = {}
    if unique:
        for start in range(0, len(unique), 180):
            portion = unique[start:start+180]
            result = subprocess.run(
                ["addr2line", "-f", "-C", "-e", str(binary),
                 *("0x"+a for a in portion)],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=35,
            )
            lines = result.stdout.splitlines()
            for i, addr in enumerate(portion):
                resolved[addr] = {
                    "function": lines[2*i] if 2*i < len(lines) else "??",
                    "source": lines[2*i+1] if 2*i+1 < len(lines) else "??",
                }
    symbols = []
    try:
        p = subprocess.run(
            ["nm", "-n", "--defined-only", str(binary)],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=65,
        )
        if p.returncode == 0:
            for line in p.stdout.splitlines():
                parts = line.split()
                if len(parts) == 3 and re.fullmatch(r"[0-9a-fA-F]+", parts[0]):
                    symbols.append((int(parts[0],16),parts[2]))
    except (subprocess.TimeoutExpired, OSError):
        pass
    locations = [x[0] for x in symbols]
    for addr in unique:
        result = resolved[addr]
        if result["function"] in ("??", "unknown"):
            n = bisect_right(locations,int(addr,16))-1
            if n>=0:
                result["function"]=symbols[n][1]
                result["source"]=f"nearest_native_symbol_plus_0x{int(addr,16)-locations[n]:x}"
        if result["function"] in ("??","unknown"):
            result["function"]="c0OfficialReplay+0x"+addr
    sampled_frames = []
    for b in stacks:
        sampled_frames.append([
            resolved.get(addr, {"function": "unknown", "source": "?"})
            for line in b.splitlines()
            if str(binary) in line
            if (match := address_re.search(line)) is not None
            for addr in [match.group(1)]
        ])
    inclusive = Counter(fr["function"] for stack in sampled_frames for fr in set_as_unique(stack))
    deepest = Counter(
        next((f["function"] for f in stack
              if f["function"] not in ("??", "unknown")), "unknown")
        for stack in sampled_frames
    )
    report = {
        "diagnostic_only": True,
        "source_file": source.name if hasattr(source, "name") else log.name,
        "native_stack_samples": len(stacks),
        "native_symbol_count": len(symbols),
        "checker_executable_addresses": len(unique),
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
    arg.add_argument("--wait-for", default=None,
                     help="sample only after this exact native declaration marker")
    arg.add_argument("--max-wait", type=int, default=800)
    a = arg.parse_args()
    if not (1 <= a.samples <= 20 and 0.5 <= a.interval <= 10):
        raise ValueError("sampling bounds cannot be disabled")
    if not (30 <= a.max_wait <= 850):
        raise ValueError("max-wait must remain a bounded number of seconds")
    exe, source, lib = (x.resolve() for x in (a.binary, a.source, a.preload))
    attempts, reached = sample(
        exe, source, lib, a.log, a.samples, a.interval,
        wait_for=a.wait_for, max_wait=a.max_wait)
    analyze(a.log, exe, a.summary)
    if not reached or attempts == 0:
        raise RuntimeError("source checker never entered the requested sampled phase")


if __name__ == "__main__":
    main()
