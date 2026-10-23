"""Linux host supervision only. This code never parses compiler source or IR."""
import json
import os
import selectors
import signal
import subprocess
import sys
import time

request = json.loads(sys.argv[1])
command = request["command"]
assert isinstance(command, list) and command and all(isinstance(a, str) for a in command)
limit = request.get("maxBuffer", 32 * 1024 * 1024)
timeout_ms = request.get("timeoutMs", 240000)
assert 0 < limit <= 32 * 1024 * 1024
assert 0 < timeout_ms <= 240000
directory = request["directory"]
os.makedirs(directory, exist_ok=True)
started = time.monotonic()
counts = {"stdout": 0, "stderr": 0}
error = None
proc = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, start_new_session=True)
selector = selectors.DefaultSelector()
outputs = {}
for name, stream in [("stdout", proc.stdout), ("stderr", proc.stderr)]:
    os.set_blocking(stream.fileno(), False)
    selector.register(stream, selectors.EVENT_READ, name)
    outputs[name] = open(os.path.join(directory, "tool." + name + ".txt"), "wb")

def kill_tree():
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass

try:
    deadline = started + timeout_ms / 1000
    while selector.get_map():
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            error = {"code": "ETIMEDOUT", "message": "process tree exceeded hard deadline"}
            kill_tree()
            break
        for key, _ in selector.select(min(remaining, 0.1)):
            block = os.read(key.fileobj.fileno(), 65536)
            if not block:
                selector.unregister(key.fileobj)
                continue
            name = key.data
            available = limit - counts[name]
            outputs[name].write(block[:available])
            counts[name] += min(len(block), available)
            if len(block) > available:
                error = {"code": "ENOBUFS", "message": "process tree exceeded output bound"}
                kill_tree()
                break
        if error:
            break
    # A tool may close stdout/stderr while continuing to run.
    if not error:
        remaining = deadline - time.monotonic()
        try:
            proc.wait(timeout=max(0, remaining))
        except subprocess.TimeoutExpired:
            error = {"code": "ETIMEDOUT", "message": "process tree exceeded hard deadline"}
            kill_tree()
    if error:
        proc.wait()
finally:
    # Also remove descendants after a parent exits with inherited live children.
    kill_tree()
    for stream in outputs.values():
        stream.close()
    selector.close()
status = proc.returncode
print(json.dumps({"status": status if status is not None and status >= 0 else None,
                  "signal": signal.Signals(-status).name if status is not None and status < 0 else None,
                  "error": error, "elapsedMs": round((time.monotonic() - started) * 1000),
                  "stdoutBytes": counts["stdout"], "stderrBytes": counts["stderr"],
                  "timeoutMs": timeout_ms, "maxBuffer": limit,
                  "processGroup": proc.pid}))
