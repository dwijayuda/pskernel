import { Session } from "node:inspector";
import { getHeapStatistics, getHeapSpaceStatistics } from "node:v8";
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { performance } from "node:perf_hooks";
import { pathToFileURL } from "node:url";
import path from "node:path";

// Diagnostic sampling only. This module is dynamically imported only in profile mode.
export async function profileCheckedOperation({
  perform, calls, modulePath, outputDirectory, identity
}) {
  if (typeof global.gc !== "function" || typeof perform !== "function")
    throw Error("PSC1_PROFILE_REQUIRES_GC_AND_CHECKED_OPERATION");
  if (!Number.isSafeInteger(calls) || calls < 1 || calls > 16)
    throw Error("PSC1_PROFILE_INVALID_CALL_COUNT");
  if (identity.fuel !== 4096) throw Error("PSC1_PROFILE_RESOURCE_POLICY_CHANGED");
  const absolute = path.resolve(modulePath);
  const generatedUrl = pathToFileURL(absolute).href;
  const generatedText = readFileSync(absolute, "utf8");
  const moduleSha256 = createHash("sha256").update(generatedText).digest("hex");
  const generatedLines = generatedText.split("\n");
  let currentOwner = null;
  const ownersByLine = generatedLines.map(line => {
    const match = /^(?:export\s+)?(?:function\s*\*?\s*([A-Za-z_$][\w$]*)|const\s+([A-Za-z_$][\w$]*)\s*=)/.exec(line);
    if (match) currentOwner = match[1] || match[2];
    return currentOwner;
  });
  const label = [identity.variant, identity.shape, identity.depth, identity.operation].join("-");
  if (!/^[A-Za-z0-9_-]+$/.test(label)) throw Error("PSC1_PROFILE_INVALID_LABEL");
  mkdirSync(outputDirectory, { recursive: true });
  const base = path.join(outputDirectory, label);
  const session = new Session();
  session.connect();
  const post = (method, params = {}) => new Promise((resolve, reject) => {
    session.post(method, params, (error, result) => error ? reject(error) : resolve(result));
  });
  const snapshot = () => ({
    memory: process.memoryUsage(),
    heap: getHeapStatistics(),
    spaces: getHeapSpaceStatistics()
  });
  const frameInfo = frame => {
    const generated = frame.url === generatedUrl || frame.url === absolute;
    const line = Number.isInteger(frame.lineNumber) ? frame.lineNumber : -1;
    return {
      function_name: frame.functionName || "(anonymous)",
      url: frame.url || "",
      line: line + 1,
      column: Number.isInteger(frame.columnNumber) ? frame.columnNumber + 1 : 0,
      generated,
      // Nearest preceding top-level generated declaration, a source-location hint.
      generated_owner_hint: generated && line >= 0 ? ownersByLine[line] || null : null,
      generated_source_line: generated && line >= 0 ?
        (generatedLines[line] || "").trim().slice(0, 220) : null
    };
  };
  const frameKey = frame => JSON.stringify([
    frame.functionName, frame.url, frame.lineNumber, frame.columnNumber
  ]);
  const run = () => {
    let checksum = 0;
    const start = performance.now();
    for (let i = 0; i < calls; i++) checksum += perform(i);
    const instrumentedMs = performance.now() - start;
    if (checksum !== calls) throw Error("PSC1_PROFILE_CHECKSUM_FAILED");
    return { calls, checksum, all_correct: true, instrumented_ms: instrumentedMs };
  };
  const cpuSummary = profile => {
    const nodes = new Map(profile.nodes.map(node => [node.id, node]));
    const samples = profile.samples || [];
    const deltas = profile.timeDeltas || [];
    if (samples.length === 0) throw Error("PSC1_PROFILE_CPU_SAMPLES_MISSING");
    const frames = new Map();
    let sampledUs = 0;
    for (let i = 0; i < samples.length; i++) {
      const node = nodes.get(samples[i]);
      if (!node) throw Error("PSC1_PROFILE_UNKNOWN_CPU_NODE");
      const key = frameKey(node.callFrame);
      const entry = frames.get(key) || {
        ...frameInfo(node.callFrame), self_samples: 0, approximate_self_us: 0
      };
      const delta = Number.isFinite(deltas[i]) && deltas[i] >= 0 ? deltas[i] : 0;
      entry.self_samples++;
      entry.approximate_self_us += delta;
      sampledUs += delta;
      frames.set(key, entry);
    }
    const ordered = [...frames.values()].sort((a, b) =>
      b.approximate_self_us - a.approximate_self_us || b.self_samples - a.self_samples);
    return {
      sample_count: samples.length,
      sampled_us: sampledUs,
      top_frames: ordered.slice(0, 20),
      top_generated_frames: ordered.filter(frame => frame.generated).slice(0, 20)
    };
  };
  const allocationSummary = profile => {
    const frames = new Map();
    const stacks = [];
    const pending = [{ node: profile.head, parents: [] }];
    let estimatedBytes = 0;
    while (pending.length !== 0) {
      const { node, parents } = pending.pop();
      const selfBytes = node.selfSize || 0;
      const chain = [node.callFrame, ...parents].slice(0, 10);
      if (selfBytes > 0) {
        estimatedBytes += selfBytes;
        const key = frameKey(node.callFrame);
        const entry = frames.get(key) || {
          ...frameInfo(node.callFrame), estimated_self_bytes: 0
        };
        entry.estimated_self_bytes += selfBytes;
        frames.set(key, entry);
        stacks.push({
          estimated_self_bytes: selfBytes,
          leaf_to_root: chain.map(frameInfo)
        });
      }
      for (const child of node.children || [])
        pending.push({ node: child, parents: chain });
    }
    const ordered = [...frames.values()].sort((a, b) =>
      b.estimated_self_bytes - a.estimated_self_bytes);
    return {
      sample_count: (profile.samples || []).length,
      estimated_total_bytes: estimatedBytes,
      top_frames: ordered.slice(0, 20),
      top_generated_frames: ordered.filter(frame => frame.generated).slice(0, 20),
      top_allocation_stacks: stacks.sort((a, b) =>
        b.estimated_self_bytes - a.estimated_self_bytes).slice(0, 12)
    };
  };
  async function allocationPass(includeCollected) {
    const phase = includeCollected ? "allocations" : "survivors";
    const samplingInterval = includeCollected ? 32768 : 4096;
    global.gc();
    const before = snapshot();
    await post("HeapProfiler.startSampling", {
      samplingInterval,
      includeObjectsCollectedByMajorGC: includeCollected,
      includeObjectsCollectedByMinorGC: includeCollected
    });
    const execution = run();
    const beforeGc = process.memoryUsage();
    global.gc();
    // Snapshot before stopSampling creates the JavaScript profile result.
    const afterGc = snapshot();
    const { profile } = await post("HeapProfiler.stopSampling");
    const file = base + "." + phase + ".heapprofile";
    writeFileSync(file, JSON.stringify(profile));
    return {
      ...execution, phase, sampling_interval_bytes: samplingInterval,
      include_collected_objects: includeCollected,
      before, before_gc: beforeGc, after_gc: afterGc,
      heap_used_delta_after_gc_bytes: afterGc.memory.heapUsed - before.memory.heapUsed,
      heap_reserved_delta_after_gc_bytes: afterGc.heap.total_heap_size - before.heap.total_heap_size,
      rss_delta_after_gc_bytes: afterGc.memory.rss - before.memory.rss,
      profile_file: path.basename(file),
      ...allocationSummary(profile)
    };
  }
  try {
    await post("Profiler.enable");
    await post("Profiler.setSamplingInterval", { interval: 1000 });
    global.gc();
    await post("Profiler.start");
    const cpuExecution = run();
    const { profile } = await post("Profiler.stop");
    const cpuFile = base + ".cpuprofile";
    writeFileSync(cpuFile, JSON.stringify(profile));
    const cpu = {
      ...cpuExecution, sampling_interval_us: 1000,
      profile_file: path.basename(cpuFile), ...cpuSummary(profile)
    };
    await post("Profiler.disable");
    await post("HeapProfiler.enable");
    const allocations = await allocationPass(true);
    const survivors = await allocationPass(false);
    const report = {
      format: "psc1-generated-profile-v1",
      node: process.version, v8: process.versions.v8,
      generated_module_sha256: moduleSha256,
      identity,
      scope: "Separate warmed runs of the existing correctness-guarded public checker operation; fresh semantic caches per call.",
      limitations: [
        "Instrumented times are diagnostics, not ordinary A-B-B-A performance measurements.",
        "Heap sizes are V8 statistical sampling estimates, not exact allocation counts.",
        "Survivors cover newly sampled allocations still live after GC, not a census or dominator analysis of the existing heap.",
        "CPU weights approximate sampled self time; generated_owner_hint is a nearby source declaration, not a parsed scope proof.",
        "Memory snapshots include inspector and diagnostic overhead; heap/RSS deltas alone do not establish object-retention ownership."
      ],
      cpu, allocations, survivors
    };
    writeFileSync(base + ".summary.json", JSON.stringify(report, null, 2) + "\n");
    return report;
  } finally {
    session.disconnect();
  }
}
