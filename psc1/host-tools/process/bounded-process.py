"""Linux host supervision only. This code never parses compiler source or IR."""
import json
import os
import resource
import glob
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
policy = request.get("timeoutPolicy", "standard-240s")
policy_limits = {"standard-240s": 240000, "g2g3-correctness-1800s": 1800000, "g2g3-correctness-3600s": 3600000}
assert policy in policy_limits
assert isinstance(timeout_ms, int) and 0 < timeout_ms <= policy_limits[policy]
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

# Sample actual descendants, including nested supervisors with their own session.
# RSS sum is a sampled resident upper bound (shared pages can be counted twice).
peak_tree_rss_kib = 0
descendants = {}
sampled_cpu_ticks = {}
current_tree_rss_kib = 0
current_processes = 0
next_heartbeat = started
clock_ticks = os.sysconf("SC_CLK_TCK")
def sample_tree():
    global peak_tree_rss_kib, current_tree_rss_kib, current_processes, next_heartbeat
    rows = {}
    for file in glob.glob("/proc/[0-9]*/stat"):
        try:
            pid = int(file.split("/")[2])
            fields = open(file).read().rsplit(")", 1)[1].split()
            rows[pid] = (int(fields[1]), int(fields[21]), fields[19], int(fields[11]) + int(fields[12]))
        except (OSError, ValueError, IndexError):
            continue
    live = {proc.pid}
    while True:
        extra = {pid for pid, (parent, _, _, _) in rows.items() if parent in live}
        if extra.issubset(live):
            break
        live.update(extra)
    descendants.update({pid: rows[pid][2] for pid in live if pid in rows})
    rss = sum(max(0, rows.get(pid, (0, 0))[1]) for pid in live)
    current_tree_rss_kib = rss * os.sysconf("SC_PAGE_SIZE") // 1024
    peak_tree_rss_kib = max(peak_tree_rss_kib, current_tree_rss_kib)
    current_processes = sum(pid in rows for pid in live)
    for pid in live:
        if pid in rows:
            identity = (pid, rows[pid][2])
            sampled_cpu_ticks[identity] = max(sampled_cpu_ticks.get(identity, 0), rows[pid][3])
    now = time.monotonic()
    if policy != "standard-240s" and now >= next_heartbeat:
        event = {"kind": "resource-heartbeat-not-semantic-progress", "timeoutPolicy": policy,
                 "supervisorPid": os.getpid(), "childPid": proc.pid,
                 "elapsedMs": round((now - started) * 1000), "timeoutMs": timeout_ms,
                 "sampledCpuSeconds": round(sum(sampled_cpu_ticks.values()) / clock_ticks, 3),
                 "currentTreeRssKiB": current_tree_rss_kib, "peakTreeRssKiB": peak_tree_rss_kib,
                 "liveProcesses": current_processes,
                 "stdoutBytes": counts["stdout"], "stderrBytes": counts["stderr"]}
        line = json.dumps(event)
        print("PSC1_PROCESS_HEARTBEAT: " + line, file=sys.stderr, flush=True)
        with open(os.path.join(directory, "resource-heartbeats.jsonl"), "a") as output:
            output.write(line + "\n")
        next_heartbeat = now + 60

def kill_tree():
    sample_tree()
    for pid, identity in list(descendants.items()):
        if pid == proc.pid:
            continue
        try:
            current = open('/proc/' + str(pid) + '/stat').read().rsplit(')', 1)[1].split()
            if current[19] == identity:
                os.kill(pid, signal.SIGKILL)
        except (OSError, IndexError):
            pass
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass

try:
    deadline = started + timeout_ms / 1000
    while selector.get_map():
        sample_tree()
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
    while not error and proc.poll() is None:
        sample_tree()
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            error = {"code": "ETIMEDOUT", "message": "process tree exceeded hard deadline"}
            kill_tree()
            break
        try:
            proc.wait(timeout=min(0.1, remaining))
        except subprocess.TimeoutExpired:
            pass
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
                  "timeoutMs": timeout_ms, "timeoutPolicy": policy, "maxBuffer": limit,
                  "maxRssKiB": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
                  "sampledCpuSeconds": round(sum(sampled_cpu_ticks.values()) / clock_ticks, 3),
                  "peakTreeRssKiB": peak_tree_rss_kib,
                  "memoryMeasurement": "Linux wait4 child maxRSS plus sampled descendant RSS sum; 100ms sampling target; shared pages may be counted twice",
                  "processGroup": proc.pid}))
