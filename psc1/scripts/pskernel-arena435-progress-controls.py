#!/usr/bin/env python3
"""Regression checks for diagnostic-only, hash-bound Arena progress evidence."""
from __future__ import annotations

import importlib.util
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("arena_progress_compare", HERE / "pskernel-arena435-compare.py")
COMPARE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = COMPARE
SPEC.loader.exec_module(COMPARE)
SOURCE_HASH = "a" * 64
passed = 0


def check(condition: bool, label: str) -> None:
    global passed
    if condition is not True:
        raise AssertionError("PSC1_ARENA_PROGRESS_CONTROL_FAILED " + label)
    passed += 1


def snapshot(elapsed=0, **changes):
    return {
        "format": "psc1-arena-progress-v2", "sourceSha256": SOURCE_HASH,
        "stage": "kernel-admission", "coreInvoked": True, "fuel": "4096",
        "elapsedMilliseconds": elapsed, **changes,
    }


def evidence(*snapshots):
    lines = "\n".join(COMPARE.PROGRESS_PREFIX + json.dumps(item) for item in snapshots)
    return COMPARE.progress_evidence(lines, SOURCE_HASH)


valid = evidence(snapshot(0), snapshot(0.0), snapshot(12.5))
check(valid["progress_snapshots"] == 3 and valid["invalid_progress_snapshots"] == 0
      and valid["last_progress"]["elapsedMilliseconds"] == 12.5, "monotonic finite milliseconds")
check(evidence(snapshot(9007199254740991))["progress_snapshots"] == 1, "exact upper bound")
for label, elapsed in [
    ("negative", -0.25), ("boolean", True), ("string", "1.25"), ("null", None),
    ("array", []), ("object", {}), ("nan", float("nan")),
    ("infinite", float("inf")), ("negative-infinite", float("-inf")),
    ("above-bound", 9007199254740992), ("huge-integer", 10 ** 400),
]:
    value = evidence(snapshot(elapsed))
    check(value["progress_snapshots"] == 0 and value["invalid_progress_snapshots"] == 1
          and value["last_progress"] is None, "reject " + label)
missing = snapshot()
del missing["elapsedMilliseconds"]
check(evidence(missing)["invalid_progress_snapshots"] == 1, "missing elapsed time")
for changes in [
    {"sourceSha256": "b" * 64}, {"format": "psc1-arena-progress-v1"}, {"fuel": "8192"},
]:
    value = evidence(snapshot(1, **changes))
    check(value["invalid_progress_snapshots"] == 1 and value["last_progress"] is None,
          "identity and policy still checked " + str(changes))
backwards = evidence(snapshot(5), snapshot(4), snapshot(6))
check(backwards["progress_snapshots"] == 2 and backwards["invalid_progress_snapshots"] == 1
      and backwards["last_progress"]["elapsedMilliseconds"] == 6,
      "backward sample ignored without replacing latest valid progress")
check(COMPARE.progress_evidence("ordinary stderr\n", SOURCE_HASH)["last_progress"] is None,
      "ordinary stderr is not progress")
injected = evidence(snapshot(3, verdict="accepted"))
check("verdict" not in injected["last_progress"], "progress cannot inject a verdict")
for verdict in ["timeout", "resource_exhausted", "unsupported", "internal_error"]:
    observed = {"verdict": verdict, "stage": "host-wall-time", **valid}
    check(COMPARE.classify({"verdict": "accepted"}, observed) == "pskernel_" + verdict,
          "progress does not change " + verdict)
print("PSC1_ARENA_PROGRESS_CONTROLS: PASS count=" + str(passed))
