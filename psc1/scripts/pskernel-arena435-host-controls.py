#!/usr/bin/env python3
"""Real Linux host-policy controls plus synthetic verdict-envelope precedence.

Synthetic envelopes test the host/parser boundary only. No fixture is an
admitted proof, an Arena match, or evidence of kernel semantic completeness.
"""
from __future__ import annotations
import argparse
import copy
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


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    sys.modules[name] = value
    spec.loader.exec_module(value)
    return value


HOST = module("arena_host_control_launcher", HERE / "pskernel-arena435-generated-cgroup.py")
COMPARE = module("arena_host_control_compare", HERE / "pskernel-arena435-compare.py")


def require(value, label):
    if value is not True:
        raise AssertionError("PSC1_ARENA_HOST_CONTROL_FAILED " + label)


def parser_controls():
    source = "a" * 64
    envelope = {"format": "psc1-arena-replay-v1", "sourceSha256": source,
                "fuel": "4096", "verdict": "accepted", "metadataValidated": True, "coreInvoked": True}
    clean = {"status": "process_exit", "hardLimitVerified": True, "cleanupOk": True,
             "testOnly": False, "limitBytes": HOST.LIMIT, "wallSeconds": 60,
             "returncode": 0, "wallTimedOut": False, "memoryPeakBytes": 1024,
             "memoryEvents": {"max": 0, "oom": 0, "oom_kill": 0, "oom_group_kill": 0}}
    count = 0

    def check(value, label):
        nonlocal count
        require(value, "parser: " + label)
        count += 1

    def observe(host=None, payload=None, stderr=""):
        receipt = copy.deepcopy(clean) if host is None else host
        output = COMPARE.PREFIX + json.dumps(envelope if payload is None else payload)
        return COMPARE.finish_case(output, stderr, {"host": receipt, "returncode": receipt.get("returncode")}, source)

    check(observe()["verdict"] == "accepted", "clean synthetic envelope reaches existing parser")
    for verdict in ("rejected", "malformed", "unsupported", "resource_exhausted", "internal_error"):
        result = observe(payload=dict(envelope, verdict=verdict))
        check(result["verdict"] == verdict, "preserve semantic envelope " + verdict)
    for label, changes, verdict, stage in [
        ("timeout", {"status": "timedout", "wallTimedOut": True}, "timeout", "host-wall-time"),
        ("oom-kill", {"status": "cgroup_oom", "memoryEvents": {"oom": 1, "oom_kill": 1}}, "resource_exhausted", "host-memory"),
        ("oom-no-kill", {"memoryEvents": {"oom": 1, "oom_kill": 0}}, "resource_exhausted", "host-memory"),
        ("oom-and-timeout", {"status": "timedout", "wallTimedOut": True,
                            "memoryEvents": {"oom": 1, "oom_kill": 1}}, "resource_exhausted", "host-memory"),
        ("setup", {"status": "setup_failed"}, "driver_error", "host-setup"),
        ("unverified", {"hardLimitVerified": False}, "driver_error", "host-setup"),
        ("cleanup", {"cleanupOk": False}, "driver_error", "host-cleanup"),
        ("cleanup-and-oom", {"cleanupOk": False, "status": "cgroup_oom"}, "driver_error", "host-cleanup"),
        ("monitor", {"status": "host_error"}, "driver_error", "host-monitor"),
        ("control-only", {"testOnly": True}, "driver_error", "host-policy"),
        ("wrong-memory-limit", {"limitBytes": HOST.CONTROL_LIMIT}, "driver_error", "host-policy"),
        ("nonzero-exit", {"returncode": 17}, "driver_error", "host-process"),
        ("unknown-host-status", {"status": "unknown"}, "driver_error", "host-process"),
        ("missing-memory-events", {"memoryEvents": {}}, "driver_error", "host-monitor"),
        ("invalid-memory-events", {"memoryEvents": {"oom": -1, "oom_kill": 0}}, "driver_error", "host-monitor"),
        ("missing-memory-peak", {"memoryPeakBytes": None}, "driver_error", "host-monitor"),
    ]:
        result = observe(dict(clean, **changes))
        check(result["verdict"] == verdict and result["stage"] == stage, label + " overrides accepted stdout")
        for official in ("accepted", "rejected"):
            check(COMPARE.classify({"verdict": official}, result).startswith("pskernel_"),
                  label + " cannot be parity against " + official)
    check(observe(dict(clean, memoryEvents={"max": 9, "oom": 0, "oom_kill": 0}))["verdict"] == "accepted",
          "memory.max events without OOM are not exhaustion")
    heap = observe(dict(clean, returncode=134), stderr="FATAL ERROR: Reached heap limit JavaScript heap out of memory")
    check(heap["verdict"] == "resource_exhausted" and heap["stage"] == "host-heap", "separate V8 heap failure")
    bad_host = COMPARE.finish_case(COMPARE.PREFIX + json.dumps(envelope), "", {"host": None, "returncode": 0}, source)
    check(bad_host["verdict"] == "driver_error", "missing host receipt refuses accepted stdout")
    for changes in ({"sourceSha256": "b" * 64}, {"fuel": "8192"}, {"fuel": 4096},
                    {"metadataValidated": False}, {"coreInvoked": False}, {"format": "wrong"}):
        check(observe(payload=dict(envelope, **changes))["verdict"] == "driver_error",
              "unchanged source/fuel/metadata/format assertion")
    driver = observe(dict(clean, returncode=2), dict(envelope, verdict="driver_error"))
    check(driver["verdict"] == "driver_error" and "stage" not in driver, "original driver-error exit2 protocol")
    check(observe(dict(clean, returncode=2))["verdict"] == "driver_error", "accepted stdout with exit2 refused")
    for output in ("", COMPARE.PREFIX + "{", COMPARE.PREFIX + "[]", COMPARE.PREFIX + "null",
                   (COMPARE.PREFIX + json.dumps(envelope) + "\n") * 2):
        result = COMPARE.finish_case(output, "", {"host": clean, "returncode": 0}, source)
        check(result["verdict"] == "driver_error", "missing/malformed/nonobject/duplicate report")
    print("PSC1_ARENA_HOST_PARSER_CONTROLS: PASS count=" + str(count), flush=True)
    return count


def output_evidence(path):
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    prefix = "PSC1_HOST_CONTROL "
    require(len(lines) == 1 and lines[0].startswith(prefix), "one independent host fixture receipt")
    value = json.loads(lines[0][len(prefix):])
    require(isinstance(value, dict), "host fixture receipt object")
    return value


def run_live(node, output, report):
    fixture = HERE / "pskernel-arena435-host-control.mjs"
    with tempfile.TemporaryDirectory(prefix="psc1-host-controls-detached-") as temporary:
        work = pathlib.Path(temporary)
        detached_fixture = work / fixture.name
        shutil.copyfile(fixture, detached_fixture)
        for mode in ("normal", "exit", "hang", "descendant", "oom", "missing-executable"):
            folder = output / mode
            folder.mkdir()
            stdout, stderr, timing = (folder / name for name in ("stdout.txt", "stderr.txt", "time.txt"))
            if mode == "missing-executable":
                receipt = HOST.run_generated(work / "missing-node", detached_fixture, detached_fixture,
                    detached_fixture, work, stdout, stderr, timing)
            else:
                receipt = HOST.run_control(node, detached_fixture, mode, work, stdout, stderr, timing,
                                           seconds=1 if mode in ("hang", "descendant") else 10)
            row = {"mode": mode, "host": receipt}
            report["live"].append(row)
            require(receipt.get("cleanupOk") is True, "cleanup " + mode)
            if mode == "missing-executable":
                require(receipt.get("status") == "setup_failed" and receipt.get("hardLimitVerified") is False
                        and receipt.get("testOnly") is False and receipt.get("limitBytes") == HOST.LIMIT,
                        "production missing executable refuses before launch")
                print("PSC1_ARENA_HOST_LIVE_CONTROL " + json.dumps({"mode": mode, "status": receipt["status"],
                      "limitBytes": receipt["limitBytes"], "cleanupOk": receipt["cleanupOk"]}), flush=True)
                continue
            require(receipt.get("hardLimitVerified") is True and receipt.get("testOnly") is True
                    and receipt.get("limitBytes") == HOST.CONTROL_LIMIT, "verified explicit control-only cap")
            evidence = output_evidence(stdout)
            row["runtime"] = evidence
            require(evidence.get("mode") == mode and evidence.get("uid") == os.getuid()
                    and evidence.get("gid") == os.getgid() and evidence.get("groups") == []
                    and evidence.get("path") == "" and str(evidence.get("node", "")).startswith("v22.")
                    and evidence.get("memoryMax") == str(HOST.CONTROL_LIMIT)
                    and evidence.get("swapMax") == "0" and evidence.get("oomGroup") == "1"
                    and "/sys/fs/cgroup" + evidence.get("cgroup", "") == receipt.get("cgroup"),
                    "independent Node identity and cgroup readback " + mode)
            require(not pathlib.Path(receipt["cgroup"]).exists(), "private cgroup removed " + mode)
            events = receipt.get("memoryEvents", {})
            if mode in ("normal", "exit"):
                require(receipt.get("status") == "process_exit" and receipt.get("returncode") == (0 if mode == "normal" else 17)
                        and events.get("oom", 0) == 0 and events.get("oom_kill", 0) == 0,
                        "ordinary complete/nonzero exit " + mode)
                require(timing.is_file() and re.search(r"Maximum resident set size \(kbytes\):\s*[1-9][0-9]*",
                        timing.read_text()) is not None, "GNU time RSS receipt " + mode)
            elif mode in ("hang", "descendant"):
                require(receipt.get("status") == "timedout" and receipt.get("wallSeconds") == 1
                        and events.get("oom", 0) == 0 and events.get("oom_kill", 0) == 0,
                        "real one-second deadline " + mode)
                if mode == "descendant":
                    child = evidence.get("childPid")
                    require(type(child) is int and child > 0 and evidence.get("childCgroup") == evidence.get("cgroup"),
                            "detached descendant inherited exact cgroup")
                    status = pathlib.Path(f"/proc/{child}/status")
                    try:
                        state = re.search(r"^State:\s+([A-Z])", status.read_text(), re.M)
                        require(state is not None and state[1] in ("Z", "X"), "detached descendant is dead")
                    except FileNotFoundError:
                        pass
            else:
                require(receipt.get("status") == "cgroup_oom"
                        and (events.get("oom_kill", 0) > 0 or events.get("oom_group_kill", 0) > 0),
                        "real touched-memory cgroup OOM")
            print("PSC1_ARENA_HOST_LIVE_CONTROL " + json.dumps({
                "mode": mode, "status": receipt["status"], "limitBytes": receipt["limitBytes"],
                "memoryPeakBytes": receipt.get("memoryPeakBytes"), "cleanupOk": receipt["cleanupOk"]}), flush=True)
    require(len(report["live"]) == 6, "all real host controls recorded")
    report["live_complete"] = True
    print("PSC1_ARENA_HOST_LIVE_CONTROLS: PASS count=6", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--node", type=pathlib.Path, required=True)
    parser.add_argument("--out", type=pathlib.Path, required=True)
    args = parser.parse_args()
    output = args.out.resolve()
    output.mkdir(parents=True, exist_ok=False)
    report = {"format": "psc1-generated-host-controls-v1", "source_sha": os.environ.get("GITHUB_SHA"),
              "kernel_qualified": False, "corpus_run": False, "production_limit_bytes": HOST.LIMIT,
              "control_only_limit_bytes": HOST.CONTROL_LIMIT, "live": [], "complete": False,
              "source_files": [{"path": name, "sha256": hashlib.sha256((HERE / name).read_bytes()).hexdigest()}
                               for name in ("pskernel-arena435-generated-cgroup.py", "pskernel-arena435-compare.py",
                                            "pskernel-arena435-host-control.mjs", "pskernel-arena435-host-controls.py")]}
    code = 0
    try:
        report["parser_assertions"] = parser_controls()
        run_live(args.node.resolve(strict=True), output, report)
        report["complete"] = True
    except Exception as error:
        report["error"] = {"type": type(error).__name__, "message": str(error)}
        code = 1
    finally:
        (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
        manifest = [{"path": str(path.relative_to(output)), "bytes": path.stat().st_size,
                     "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                    for path in sorted(output.rglob("*")) if path.is_file()]
        (output / "sha256.json").write_text(json.dumps(manifest, indent=2) + "\n")
        print("PSC1_ARENA_HOST_CONTROLS " + json.dumps(report), flush=True)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
