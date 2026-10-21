#!/usr/bin/env python3
"""Host-only cgroup-v2 launcher; never derives a kernel verdict."""
import json, os, pathlib, re, signal, subprocess, sys, time, uuid

LIMIT = 2147483648

def _group(c):
    p = pathlib.Path(c["group"])
    if p.parent != pathlib.Path("/sys/fs/cgroup") or not re.fullmatch(r"psc1-native-[0-9a-f]{32}", p.name):
        raise RuntimeError("invalid private cgroup")
    return p

def _launch(c):
    if (type(c["uid"]) is not int or c["uid"] <= 0
            or c["uid"] != int(os.environ["SUDO_UID"]) or c["gid"] != int(os.environ["SUDO_GID"])
            or type(c["seconds"]) is not int or not 1 <= c["seconds"] <= 60
            or c["args"] not in [[], ["--controls"], ["--stage-controls"], ["--stages"]]):
        raise RuntimeError("launch identity, deadline or arguments differ")
    p = _group(c); p.mkdir()
    for key, value in [("memory.max", str(LIMIT)), ("memory.swap.max", "0"), ("memory.oom.group", "1")]:
        f = p / key
        if not f.exists(): raise RuntimeError("missing cgroup v2 control: " + key)
        f.write_text(value)
        if f.read_text().strip() != value: raise RuntimeError("cgroup readback failed: " + key)
    for key in ["memory.peak", "memory.events", "cgroup.events", "cgroup.kill"]:
        if not (p / key).exists(): raise RuntimeError("missing cgroup evidence: " + key)
    (p / "cgroup.procs").write_text("0")
    if (p / "cgroup.procs").read_text().split() != [str(os.getpid())]:
        raise RuntimeError("launcher is not the sole cgroup process")
    os.setgroups([]); os.setgid(c["gid"]); os.setuid(c["uid"])
    if os.getresuid() != (c["uid"],)*3 or os.getresgid() != (c["gid"],)*3 or os.getgroups():
        raise RuntimeError("privilege drop failed")
    os.chdir(c["cwd"])
    ready = pathlib.Path(c["ready"]); temporary = ready.with_suffix(".tmp")
    temporary.write_text(json.dumps({"pid": os.getpid(), "uid": os.getuid(), "gid": os.getgid(),
        "groups": [], "path": "", "memoryMax": LIMIT, "swapMax": 0, "oomGroup": 1,
        "sessionId": os.getsid(0), "phase": "before-exec"}))
    temporary.replace(ready)
    signal.signal(signal.SIGPIPE, signal.SIG_DFL); signal.alarm(c["seconds"])
    try:
        os.execve(c["exe"], [c["exe"], *c["args"]], {"PATH": "", "LANG": "C.UTF-8"})
    except OSError as error:
        record = json.loads(ready.read_text()); record["execError"] = repr(error)
        temporary.write_text(json.dumps(record)); temporary.replace(ready)
        raise

def _cleanup(c):
    p = _group(c); result = {"cleanupOk": True}
    if not p.exists(): return result
    if (p / "cgroup.kill").exists(): (p / "cgroup.kill").write_text("1")
    until = time.monotonic() + 5
    while "populated 1" in (p / "cgroup.events").read_text():
        if time.monotonic() >= until: raise RuntimeError("private cgroup remains populated")
        time.sleep(.02)
    if (p / "memory.events").exists():
        result["memoryEvents"] = dict((k, int(v)) for k, v in
            (line.split() for line in (p / "memory.events").read_text().splitlines()))
    if (p / "memory.peak").exists(): result["memoryPeakBytes"] = int((p / "memory.peak").read_text())
    p.rmdir()
    return result

def run_native(executable: pathlib.Path, cwd: pathlib.Path, stdout: pathlib.Path,
               stderr: pathlib.Path, seconds: int = 60, *, arguments=()) -> dict:
    if not 1 <= seconds <= 60 or tuple(arguments) not in [(), ("--controls",), ("--stage-controls",), ("--stages",)]:
        raise ValueError("only <=60s and exact native diagnostic modes are permitted")
    if os.getuid() == 0: raise RuntimeError("native checker must run as an unprivileged user")
    exe, work = pathlib.Path(executable).resolve(), pathlib.Path(cwd).resolve()
    stdout, stderr = pathlib.Path(stdout).resolve(), pathlib.Path(stderr).resolve()
    if not exe.is_file() or not os.access(exe, os.X_OK) or not work.is_dir() or exe.stat().st_mode & 0o6000:
        raise RuntimeError("missing/privileged executable or missing detached cwd")
    token = uuid.uuid4().hex
    config, ready = work / (token + ".config.json"), work / (token + ".ready.json")
    c = {"group": "/sys/fs/cgroup/psc1-native-" + token, "ready": str(ready), "exe": str(exe),
         "cwd": str(work), "uid": os.getuid(), "gid": os.getgid(), "seconds": seconds, "args": list(arguments)}
    config.write_text(json.dumps(c))
    command = ["/usr/bin/sudo", "-n", "/usr/bin/python3", "-I", str(pathlib.Path(__file__).resolve())]
    r = {"status": "setup_failed", "limitBytes": LIMIT, "wallSeconds": seconds,
         "stdoutPath": str(stdout), "stderrPath": str(stderr), "cgroup": c["group"],
         "memoryPeakScope": "isolated launcher/exec process and descendants"}
    process, timed, high = None, False, 0
    started = time.monotonic()
    try:
        with pathlib.Path(stdout).open("xb") as out, pathlib.Path(stderr).open("xb") as err:
            process = subprocess.Popen(command + ["--root-launch", str(config)], cwd=work,
                stdin=subprocess.DEVNULL, stdout=out, stderr=err, start_new_session=True)
            while process.poll() is None:
                if ready.exists():
                    r["launch"] = json.loads(ready.read_text()); pid = r["launch"]["pid"]
                    try:
                        if pathlib.Path(f"/proc/{pid}/exe").resolve() == exe:
                            m = re.search(r"^VmHWM:\s+(\d+) kB$", pathlib.Path(f"/proc/{pid}/status").read_text(), re.M)
                            if m: high = max(high, int(m[1])*1024)
                    except OSError: pass
                if time.monotonic() - started >= (seconds if ready.exists() else 10):
                    timed = True; break
                time.sleep(.02)
            if ready.exists():
                r["launch"] = json.loads(ready.read_text()); r["status"] = "process_exit"
    except Exception as error: r["error"] = repr(error)
    finally:
        elapsed = time.monotonic() - started
        if timed and not ready.exists() and process is not None:
            try: process.wait(timeout=3)  # independent 10s setup alarm in root shim
            except Exception as error: r["setupWaitError"] = repr(error)
        try:
            done = subprocess.run(command + ["--root-cleanup", str(config)],
                check=True, capture_output=True, text=True, timeout=8)
            r.update(json.loads(done.stdout))
        except Exception as error:
            r.update(status="host_error" if ready.exists() else "setup_failed", cleanupOk=False, cleanupError=repr(error))
        if process is not None:
            try: r["returncode"] = process.wait(timeout=5)
            except Exception as error: r.update(status="host_error" if ready.exists() else "setup_failed", waitError=repr(error))
        events = r.get("memoryEvents", {})
        if ready.exists():
            r["launch"] = json.loads(ready.read_text())
            if r["launch"].get("execError"): r["status"] = "setup_failed"
        if ready.exists() and r.get("cleanupOk") and r["status"] not in ["host_error", "setup_failed"]:
            if events.get("oom_kill", 0) or events.get("oom_group_kill", 0): r["status"] = "cgroup_oom"
            elif timed or (r.get("returncode") in [-14, 142] and elapsed >= seconds-.1): r["status"] = "timedout"
            elif events.get("oom", 0): r["status"] = "resource_limit"
        r.update(elapsedSeconds=elapsed, wallTimedOut=timed and ready.exists(), setupTimedOut=timed and not ready.exists(),
                 sampledNativeVmHwmBytesLowerBound=high)
    return r

if __name__ == "__main__":
    if os.geteuid() != 0 or len(sys.argv) != 3 or sys.argv[1] not in ["--root-launch", "--root-cleanup"]:
        raise SystemExit("internal root shim requires root, mode and config")
    signal.signal(signal.SIGALRM, signal.SIG_DFL); signal.alarm(10)
    c = json.loads(pathlib.Path(sys.argv[2]).read_text())
    if sys.argv[1] == "--root-launch": _launch(c)
    else: print(json.dumps(_cleanup(c)))

