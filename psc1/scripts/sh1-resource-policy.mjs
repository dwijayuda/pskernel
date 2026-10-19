import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { appendFileSync, mkdirSync, readFileSync, writeFileSync, writeSync } from 'node:fs';
import path from 'node:path';
import { performance } from 'node:perf_hooks';
import { pathToFileURL } from 'node:url';
import { getHeapStatistics } from 'node:v8';

const MiB = 1024 ** 2;
const GiB = 1024 ** 3;
export const qualificationResourcePolicy = Object.freeze({
  id: 'psc0-sh1-generated-qualification-resources/1',
  node: 'v22.23.3', platform: 'linux', architecture: 'x64',
  oldSpaceMiB: 8192, minimumAvailableBytes: 12 * GiB,
  minimumHeapLimitBytes: 8192 * MiB, maximumHeapLimitBytes: (8192 + 256) * MiB,
  checkBoundary: 'process-entry-before-generated-compiler-loading',
  automaticFallback: false, semanticContractQualified: false,
});

const digest = (value) => createHash('sha256').update(value).digest('hex');
const failure = (code) => 'PSC0_SH1_RESOURCE_' + code;

function safeBytes(value, label) {
  assert(Number.isSafeInteger(value) && value >= 0, failure(label));
  return value;
}

function physicalMemory() {
  const text = readFileSync('/proc/meminfo', 'utf8');
  const read = (name) => {
    const match = new RegExp('^' + name + ':\\s+([0-9]+) kB$', 'm').exec(text);
    assert(match, failure('MEMINFO_' + name));
    const bytes = BigInt(match[1]) * 1024n;
    assert(bytes <= BigInt(Number.MAX_SAFE_INTEGER), failure('MEMINFO_RANGE'));
    return Number(bytes);
  };
  const totalBytes = read('MemTotal');
  const availableBytes = read('MemAvailable');
  assert(totalBytes > 0 && availableBytes <= totalBytes, failure('PHYSICAL_MEMORY'));
  return { totalBytes, availableBytes };
}

function readCounter(file, allowMax = false) {
  const raw = readFileSync(file, 'utf8').trim();
  if (allowMax && raw === 'max') return { raw, value: null };
  assert(/^[0-9]+$/u.test(raw), failure('CGROUP_COUNTER'));
  return { raw, value: BigInt(raw) };
}

function cgroupMemory(totalBytes) {
  const membership = readFileSync('/proc/self/cgroup', 'utf8').trim().split('\n')
    .map((line) => {
      const match = /^([^:]+):([^:]*):(\/.*)$/u.exec(line);
      assert(match, failure('CGROUP_MEMBERSHIP'));
      return { controllers: match[2].split(','), directory: match[3], unified: match[1] === '0' && match[2] === '' };
    });
  const legacy = membership.find((entry) => entry.controllers.includes('memory'));
  const group = legacy ?? membership.find((entry) => entry.unified);
  assert(group, failure('CGROUP_MEMORY_HIERARCHY'));
  const version = legacy ? 1 : 2;
  const unescapeMount = (value) => value.replace(/\\([0-7]{3})/gu,
    (_, octal) => String.fromCharCode(parseInt(octal, 8)));
  const mounts = readFileSync('/proc/self/mountinfo', 'utf8').trim().split('\n')
    .map((line) => {
      const parts = line.split(' - ');
      assert(parts.length === 2, failure('MOUNTINFO'));
      const left = parts[0].split(' ');
      const right = parts[1].split(' ');
      return { root: unescapeMount(left[3]), mount: unescapeMount(left[4]),
        type: right[0], options: right[2].split(',') };
    }).filter((entry) => version === 2 ? entry.type === 'cgroup2'
      : entry.type === 'cgroup' && entry.options.includes('memory'));
  const contains = (parent, child) => parent === '/' || child === parent || child.startsWith(parent + '/');
  assert(path.posix.normalize(group.directory) === group.directory, failure('CGROUP_MEMBERSHIP_PATH'));
  const choices = mounts.filter((entry) => contains(entry.root, group.directory))
    .sort((left, right) => left.root.length - right.root.length);
  assert(choices.length > 0, failure('CGROUP_MOUNT_MAPPING'));
  const selected = choices[0];
  assert(path.posix.isAbsolute(selected.root) && path.posix.isAbsolute(selected.mount) &&
    path.posix.normalize(selected.root) === selected.root &&
    path.posix.normalize(selected.mount) === selected.mount, failure('CGROUP_MOUNT_PATH'));
  const relative = group.directory.slice(selected.root === '/' ? 1 : selected.root.length + 1);
  let directory = path.posix.join(selected.mount, relative);
  const observations = [];
  const total = BigInt(totalBytes);
  for (;;) {
    assert(contains(selected.mount, directory), failure('CGROUP_ANCESTOR_PATH'));
    const names = version === 2
      ? { current: 'memory.current', limits: ['memory.max', 'memory.high'] }
      : { current: 'memory.usage_in_bytes', limits: ['memory.limit_in_bytes', 'memory.soft_limit_in_bytes'] };
    let current;
    try {
      current = readCounter(path.posix.join(directory, names.current));
    } catch (error) {
      // A true global cgroup-v2 root has no memory controller counters or limit.
      // A bind-mounted/namespace root is not treated as the global root.
      if (error.code === 'ENOENT' && version === 2 && directory === selected.mount && selected.root === '/') {
        // These interfaces exist on every real non-root cgroup, including a
        // namespace root, even when that cgroup has no memory controller files.
        const absent = [...names.limits, 'cgroup.type', 'cgroup.events'].every((name) => {
          try { readFileSync(path.posix.join(directory, name)); return false; }
          catch (missing) { if (missing.code === 'ENOENT') return true; throw missing; }
        });
        assert(absent, failure('CGROUP_ROOT_COUNTER'));
        observations.push({ directory, globalRootWithoutMemoryController: true });
        break;
      }
      throw error;
    }
    for (const name of names.limits) {
      const limit = readCounter(path.posix.join(directory, name), version === 2);
      const remaining = limit.value === null ? total
        : limit.value > current.value ? limit.value - current.value : 0n;
      observations.push({
        directory, limitFile: name, limitBytes: limit.raw, currentBytes: current.raw,
        capacityBytes: Number(limit.value === null || limit.value > total ? total : limit.value),
        availableBytes: Number(remaining > total ? total : remaining),
      });
    }
    if (directory === selected.mount) break;
    directory = path.posix.dirname(directory);
  }
  return { version, membership: group.directory, mountRoot: selected.root,
    mountPoint: selected.mount, visibility: 'current-and-visible-ancestor-cgroups', observations };
}

function checkHeapOptions() {
  const normalized = process.execArgv.map((value) => value.replaceAll('_', '-'));
  const environmentOptions = (process.env.NODE_OPTIONS ?? '').replaceAll('_', '-');
  // The qualification environment intentionally accepts only unquoted options.
  // Node removes double quotes before parsing, which could hide a heap override.
  assert(!/["'\\]/u.test(environmentOptions), failure('NODE_OPTIONS_QUOTING'));
  const resourceFlag = /--(?:max-(?:old-space-size(?:-percentage)?|heap-size|semi-space-size)|huge-max-old-generation-size)(?:[=\s]|$)/u;
  assert(!resourceFlag.test(environmentOptions), failure('NODE_OPTIONS_HEAP_OVERRIDE'));
  const relevant = normalized.filter((value) => resourceFlag.test(value));
  assert.deepEqual(relevant, ['--max-old-space-size=8192'], failure('EXPLICIT_HEAP_FLAG'));
  const heapLimitBytes = safeBytes(getHeapStatistics().heap_size_limit, 'HEAP_LIMIT');
  assert(heapLimitBytes >= qualificationResourcePolicy.minimumHeapLimitBytes &&
    heapLimitBytes <= qualificationResourcePolicy.maximumHeapLimitBytes, failure('OBSERVED_HEAP_LIMIT'));
  return { explicitOldSpaceMiB: 8192, observedHeapLimitBytes: heapLimitBytes,
    inheritedHeapOverride: false };
}

// This preflight measures a process-entry budget, not a peak-RSS guarantee.
// Intra-atomic execution remains synchronous and opaque to host checkpoints.
export function enforceQualificationResourcePolicy({ command, receiptPath }) {
  const receipt = { schemaVersion: 1, evidence: 'generated-qualification-resource-preflight',
    command, policy: qualificationResourcePolicy, node: process.version,
    platform: process.platform, architecture: process.arch, pid: process.pid,
    passed: false, strictSh1Qualified: false, semanticContractQualified: false };
  let refusal;
  try {
    assert.equal(process.version, qualificationResourcePolicy.node, failure('NODE_VERSION'));
    assert.equal(process.platform, qualificationResourcePolicy.platform, failure('PLATFORM'));
    assert.equal(process.arch, qualificationResourcePolicy.architecture, failure('ARCHITECTURE'));
    receipt.heap = checkHeapOptions();
    receipt.physical = physicalMemory();
    const availableBytes = safeBytes(process.availableMemory(), 'NODE_AVAILABLE');
    const constrainedBytes = process.constrainedMemory();
    assert(Number.isFinite(constrainedBytes) && constrainedBytes >= 0, failure('NODE_CONSTRAINED'));
    const bindingConstraint = constrainedBytes > 0 && constrainedBytes < receipt.physical.totalBytes
      ? safeBytes(constrainedBytes, 'NODE_CONSTRAINED_RANGE') : null;
    receipt.nodeMemory = { availableBytes, constrainedBytes: String(constrainedBytes),
      bindingConstraintBytes: bindingConstraint };
    receipt.cgroup = cgroupMemory(receipt.physical.totalBytes);
    const finite = receipt.cgroup.observations.filter((row) => row.availableBytes !== undefined);
    receipt.effectiveCapacityBytes = Math.min(receipt.physical.totalBytes,
      bindingConstraint ?? receipt.physical.totalBytes, ...finite.map((row) => row.capacityBytes));
    receipt.effectiveAvailableBytes = Math.min(receipt.physical.availableBytes, availableBytes,
      receipt.effectiveCapacityBytes, ...finite.map((row) => row.availableBytes));
    assert(receipt.effectiveAvailableBytes >= qualificationResourcePolicy.minimumAvailableBytes,
      failure('AVAILABLE_MEMORY_REQUIRED'));
    receipt.passed = true;
  } catch (error) {
    receipt.refusal = { name: error.name, message: error.message };
    refusal = error;
  }
  mkdirSync(path.dirname(receiptPath), { recursive: true });
  writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
  writeSync(1, 'PSC0_SH1_RESOURCE_POLICY: ' + JSON.stringify(receipt) + '\n');
  if (refusal) throw refusal;
  return { report: path.basename(receiptPath), sha256: digest(readFileSync(receiptPath)),
    policy: qualificationResourcePolicy.id, passed: true };
}

export function createQualificationResourceTrace(directory, context) {
  const file = path.join(directory, 'resource-usage.jsonl');
  mkdirSync(directory, { recursive: true });
  writeFileSync(file, '');
  const started = performance.now();
  let sequence = 0;
  const checkpoint = (phase, details = {}) => {
    for (const value of [...Object.values(context), ...Object.values(details)]) {
      assert(value === null || ['string', 'number', 'boolean'].includes(typeof value), failure('TRACE_SCALAR'));
      if (typeof value === 'number') assert(Number.isFinite(value), failure('TRACE_NUMBER'));
    }
    const memory = process.memoryUsage();
    const row = { schemaVersion: 1, evidence: 'host-resource-boundary-observation',
      ...context, ...details, sequence: ++sequence, phase, pid: process.pid,
      elapsedMs: performance.now() - started, ...memory,
      heapLimitBytes: getHeapStatistics().heap_size_limit,
      maxRssBytes: process.resourceUsage().maxRSS * 1024 };
    const line = JSON.stringify(row) + '\n';
    appendFileSync(file, line);
    writeSync(1, 'PSC0_SH1_RESOURCE: ' + line);
  };
  return { checkpoint, reference: () => ({
    report: 'resource-usage.jsonl', sha256: digest(readFileSync(file)), checkpoints: sequence,
    measurement: 'host-process-boundaries-with-process-rss-high-water-mark',
    atomicInternalsObserved: false, semanticContractQualified: false,
  }) };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  assert(process.argv.length === 4 && process.argv[2] === '--preflight',
    'usage: node --max-old-space-size=8192 scripts/sh1-resource-policy.mjs --preflight receipt.json');
  enforceQualificationResourcePolicy({ command: 'workflow-preflight', receiptPath: path.resolve(process.argv[3]) });
}
