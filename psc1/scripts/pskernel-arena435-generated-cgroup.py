#!/usr/bin/env python3
"""Host-only generated-Arena cgroup-v2 launcher; never derives a kernel verdict.

The launch/drop/cleanup sequence is adapted from
pskernel-arena435-native-cgroup.py at
f2e6c44a506a53dc294ae6569f8371e81ed6bdd5. The native API is unchanged.
Production always uses 2147483648 charged bytes and no swap. The distinct
control-only API uses 134217728 bytes; its results cannot qualify a corpus.
"""
from __future__ import annotations

import json
import os
import pathlib
import re
import signal
import subprocess
import sys
import time
import uuid

LIMIT = 2147483648
CONTROL_LIMIT = 134217728
CONTROL_MODES = {"normal", "exit", "hang", "descendant", "oom"}
RUNTIME_ENV = {"PATH": "", "LANG": "C.UTF-8", "LC_ALL": "C", "TZ": "UTC"}
TIME = pathlib.Path("/usr/bin/time")


def _group(c):
    path = pathlib.Path(c["group"])
    if path.parent != pathlib.Path("/sys/fs/cgroup") or not re.fullmatch(r"psc1-generated-[0-9a-f]{32}", path.name):
        raise RuntimeError("invalid private generated cgroup")
    return path


def _file(value, executable=False):
    path = pathlib.Path(value)
    if not path.is_absolute() or not path.is_file():
        raise RuntimeError("missing absolute runtime file")
    if executable and (not os.access(path, os.X_OK) or path.stat().st_mode & 0o6000):
        raise RuntimeError("missing executable permission or privileged executable")
    return path


def _command(c):
    node = _file(c["node"], True)
    _file(str(TIME), True)
    if c["mode"] == "arena":
        if c["memoryLimit"] != LIMIT or type(c["seconds"]) is not int or not 1 <= c["seconds"] <= 60:
            raise RuntimeError("production host policy differs")
        args = [str(_file(c[key])) for key in ("runner", "kernel", "input")]
    elif c["mode"] == "control":
        if (c["memoryLimit"] != CONTROL_LIMIT or type(c["seconds"]) is not int
                or not 1 <= c["seconds"] <= 10 or c["control"] not in CONTROL_MODES):
            raise RuntimeError("control-only host policy differs")
        fixture = _file(c["fixture"])
        if fixture.name != "pskernel-arena435-host-control.mjs":
            raise RuntimeError("unexpected host-control fixture")
        args = [str(fixture), c["control"]]
    else:
        raise RuntimeError("unknown host execution mode")
    return [str(TIME), "-v", "-o", c["timeLog"], str(node), "--max-old-space-size=2048", *args]


def _launch(c):
    if (type(c["uid"]) is not int or c["uid"] <= 0
            or c["uid"] != int(os.environ["SUDO_UID"]) or c["gid"] != int(os.environ["SUDO_GID"])):
        raise RuntimeError("launch identity differs")
    command = _command(c)
    path = _group(c)
    path.mkdir()
    for key, value in [("memory.max", str(c["memoryLimit"])), ("memory.swap.max", "0"),
                       ("memory.oom.group", "1")]:
        control = path / key
        if not control.exists():
            raise RuntimeError("missing cgroup v2 control: " + key)
        control.write_text(value)
        if control.read_text().strip() != value:
            raise RuntimeError("cgroup readback failed: " + key)
    for key in ["memory.peak", "memory.events", "cgroup.events", "cgroup.kill"]:
        if not (path / key).exists():
            raise RuntimeError("missing cgroup evidence: " + key)
    (path / "cgroup.procs").write_text("0")
    if (path / "cgroup.procs").read_text().split() != [str(os.getpid())]:
        raise RuntimeError("launcher is not the sole cgroup process")
    os.setgroups([])
    os.setgid(c["gid"])
    os.setuid(c["uid"])
    if os.getresuid() != (c["uid"],) * 3 or os.getresgid() != (c["gid"],) * 3 or os.getgroups():
        raise RuntimeError("privilege drop failed")
    os.chdir(c["cwd"])
    ready = pathlib.Path(c["ready"])
    temporary = ready.with_suffix(".tmp")
    temporary.write_text(json.dumps({
        "pid": os.getpid(), "uid": os.getuid(), "gid": os.getgid(), "groups": [],
        "path": "", "memoryMax": c["memoryLimit"], "swapMax": 0, "oomGroup": 1,
        "sessionId": os.getsid(0), "phase": "before-exec", "mode": c["mode"],
        "executable": str(TIME), "nodeExecutable": c["node"],
    }))
    temporary.replace(ready)
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    signal.alarm(c["seconds"])
    try:
        os.execve(command[0], command, RUNTIME_ENV)
    except OSError as error:
        record = json.loads(ready.read_text())
        record["execError"] = repr(error)
        temporary.write_text(json.dumps(record))
        temporary.replace(ready)
        raise


def _cleanup(c):
    path = _group(c)
    result = {"cleanupOk": True}
    if not path.exists():
        return result
    if (path / "cgroup.kill").exists():
        (path / "cgroup.kill").write_text("1")
    until = time.monotonic() + 5
    while "populated 1" in (path / "cgroup.events").read_text():
        if time.monotonic() >= until:
            raise RuntimeError("private cgroup remains populated")
        time.sleep(.02)
    if (path / "memory.events").exists():
        result["memoryEvents"] = dict((key, int(value)) for key, value in
            (line.split() for line in (path / "memory.events").read_text().splitlines()))
    if (path / "memory.peak").exists():
        result["memoryPeakBytes"] = int((path / "memory.peak").read_text())
    path.rmdir()
    return result


def _sample_node(launch, node):
    """Only the direct Node child of GNU time; a sampled lower bound, not cgroup RSS."""
    high = 0
    try:
        pid = launch["pid"]
        children = pathlib.Path(f"/proc/{pid}/task/{pid}/children").read_text().split()
        for child in children:
            if pathlib.Path(f"/proc/{child}/exe").resolve() == node:
                status = pathlib.Path(f"/proc/{child}/status").read_text()
                match = re.search(r"^VmHWM:\s+(\d+) kB$", status, re.M)
                if match:
                    high = max(high, int(match[1]) * 1024)
    except OSError:
        pass
    return high


def _run(c, cwd, stdout, stderr, time_log):
    work = pathlib.Path(cwd).resolve()
    stdout, stderr, time_log = (pathlib.Path(value).resolve() for value in (stdout, stderr, time_log))
    result = {
        "status": "setup_failed", "limitBytes": c["memoryLimit"], "wallSeconds": c["seconds"],
        "stdoutPath": str(stdout), "stderrPath": str(stderr), "timePath": str(time_log),
        "memoryPeakScope": "charged memory of isolated launcher/time/Node and descendants",
        "sampledVmHwmScope": "direct Node process only; sampled lower bound including mapped/shared pages",
        "testOnly": c["mode"] == "control", "hardLimitVerified": False,
    }
    if os.getuid() == 0:
        result["error"] = "generated checker must run as an unprivileged user"
        return result
    token = uuid.uuid4().hex
    host_dir = stdout.parent / (stdout.stem + "-host")
    c.update(group="/sys/fs/cgroup/psc1-generated-" + token,
             ready=str(host_dir / "ready.json"), cwd=str(work), uid=os.getuid(), gid=os.getgid(),
             timeLog=str(time_log))
    result["cgroup"] = c["group"]
    try:
        if not work.is_dir():
            raise RuntimeError("missing detached cwd")
        _command(c)
        host_dir.mkdir()
        config = host_dir / "config.json"
        config.write_text(json.dumps(c))
    except Exception as error:
        result.update(error=repr(error), cleanupOk=True)
        return result
    ready = pathlib.Path(c["ready"])
    command = ["/usr/bin/sudo", "-n", "/usr/bin/python3", "-I", str(pathlib.Path(__file__).resolve())]
    process, timed, high = None, False, 0
    started = time.monotonic()
    try:
        with stdout.open("xb") as out, stderr.open("xb") as err:
            process = subprocess.Popen(command + ["--root-launch", str(config)], cwd=work,
                stdin=subprocess.DEVNULL, stdout=out, stderr=err, start_new_session=True,
                env={"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8"})
            while process.poll() is None:
                if ready.exists():
                    result["launch"] = json.loads(ready.read_text())
                    high = max(high, _sample_node(result["launch"], pathlib.Path(c["node"])))
                if time.monotonic() - started >= (c["seconds"] if ready.exists() else 10):
                    timed = True
                    break
                time.sleep(.02)
            if ready.exists():
                result["launch"] = json.loads(ready.read_text())
                result["status"] = "process_exit"
    except Exception as error:
        result["error"] = repr(error)
        if ready.exists():
            result["status"] = "host_error"
    finally:
        elapsed = time.monotonic() - started
        if timed and not ready.exists() and process is not None:
            try:
                process.wait(timeout=3)
            except Exception as error:
                result["setupWaitError"] = repr(error)
        try:
            done = subprocess.run(command + ["--root-cleanup", str(config)], check=True,
                capture_output=True, text=True, timeout=8, env={"PATH": "/usr/bin:/bin", "LANG": "C.UTF-8"})
            result.update(json.loads(done.stdout))
        except Exception as error:
            result.update(status="host_error" if ready.exists() else "setup_failed",
                          cleanupOk=False, cleanupError=repr(error))
        if process is not None:
            try:
                result["returncode"] = process.wait(timeout=5)
            except Exception as error:
                result.update(status="host_error" if ready.exists() else "setup_failed", waitError=repr(error))
        if ready.exists():
            result["launch"] = json.loads(ready.read_text())
            launch = result["launch"]
            verified = (launch.get("memoryMax") == c["memoryLimit"]
                and launch.get("swapMax") == 0 and launch.get("oomGroup") == 1
                and launch.get("uid") == c["uid"] and launch.get("gid") == c["gid"]
                and launch.get("groups") == [] and launch.get("path") == ""
                and launch.get("mode") == c["mode"])
            result["hardLimitVerified"] = verified
            if launch.get("execError") or not verified:
                result["status"] = "setup_failed"
        events = result.get("memoryEvents", {})
        if (ready.exists() and result.get("cleanupOk") and
                result["status"] not in ["host_error", "setup_failed"]):
            if events.get("oom_kill", 0) or events.get("oom_group_kill", 0):
                result["status"] = "cgroup_oom"
            elif events.get("oom", 0):
                result["status"] = "resource_limit"
            elif timed or (result.get("returncode") in [-14, 142] and elapsed >= c["seconds"] - .1):
                result["status"] = "timedout"
        result.update(elapsedSeconds=elapsed, wallTimedOut=timed and ready.exists(),
                      setupTimedOut=timed and not ready.exists(), sampledNodeVmHwmBytesLowerBound=high)
    return result


def run_generated(node, runner, kernel, case, cwd, stdout, stderr, time_log, seconds=60):
    """Production API: fixed 2 GiB cgroup, swap zero, no caller-supplied memory policy."""
    config = {"mode": "arena", "memoryLimit": LIMIT, "seconds": seconds}
    config.update({key: str(pathlib.Path(value).resolve()) for key, value in
                   [("node", node), ("runner", runner), ("kernel", kernel), ("input", case)]})
    return _run(config, cwd, stdout, stderr, time_log)


def run_control(node, fixture, mode, cwd, stdout, stderr, time_log, seconds=10):
    """Host tests only: fixed 128 MiB cgroup; never used by the corpus wrapper."""
    config = {"mode": "control", "memoryLimit": CONTROL_LIMIT, "seconds": seconds,
              "node": str(pathlib.Path(node).resolve()), "fixture": str(pathlib.Path(fixture).resolve()),
              "control": mode}
    return _run(config, cwd, stdout, stderr, time_log)


if __name__ == "__main__":
    if os.geteuid() != 0 or len(sys.argv) != 3 or sys.argv[1] not in ["--root-launch", "--root-cleanup"]:
        raise SystemExit("internal root shim requires root, mode and config")
    signal.signal(signal.SIGALRM, signal.SIG_DFL)
    signal.alarm(10)
    config = json.loads(pathlib.Path(sys.argv[2]).read_text())
    if sys.argv[1] == "--root-launch":
        _launch(config)
    else:
        print(json.dumps(_cleanup(config)))
