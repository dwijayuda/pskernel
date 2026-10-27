// CI-only observation of the unchanged qualified compiler/kernel and editor host.
// No compiler or provider source is rewritten. The optional spawnSync observer
// delegates each real invocation unchanged and exists only in an isolated child.
import fs from 'node:fs/promises';
import syncFs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import childProcess from 'node:child_process';
import {syncBuiltinESMExports} from 'node:module';
import {fileURLToPath, pathToFileURL} from 'node:url';

const ownFile = fileURLToPath(import.meta.url);
const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const round = value => Math.round(value * 100) / 100;
const sourceFor = value => `theorem identity(P : Prop, h : P) : P := h\ndef answer : Nat := ${value}\n`;
const requestFor = value => ({sources: [{module: 'Main', kind: 'ps', text: sourceFor(value)}],
  entryModule: 'Main', assurance: 'checked'});
const sourceDigest = sources => sha(JSON.stringify(sources.map(source => ({
  module: source.module, kind: source.kind, utf8Sha256: sha(source.text),
}))));
const cleanEnvironment = () => {
  const env = {...process.env};
  for (const key of Object.keys(env)) {
    if (key.toUpperCase() === 'PATH' || key.startsWith('PSC1_') ||
        ['NODE_OPTIONS', 'LEAN_PATH', 'ELAN_TOOLCHAIN', 'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'].includes(key)) delete env[key];
  }
  env.PATH = path.dirname(process.execPath);
  return env;
};

function classifySpawn(args) {
  const values = Array.isArray(args[1]) ? args[1].map(String) : [];
  const launcher = values.find(value => /pskernel-lean\.(cjs|mjs|js)$/.test(value));
  if (launcher && values.includes('--health')) return 'wasm-health-process';
  if (launcher && values.includes('--check')) return 'wasm-check-process';
  if (values.some(value => /(?:unified-candidate|generated-service)-runner\.mjs$/.test(value))) return 'compiler-process';
  return 'other-process';
}

async function profilePublicApis({compilerRoot, values}) {
  const manifest = JSON.parse(syncFs.readFileSync(path.join(compilerRoot, 'package.json'), 'utf8'));
  assert.equal(manifest.name, 'proofscript');
  assert.equal(manifest.version, '0.1.0-psc1.12');
  const original = childProcess.spawnSync;
  const calls = [];
  let phase = 'import';
  childProcess.spawnSync = function (...args) {
    const started = performance.now();
    let result, failure;
    try { result = Reflect.apply(original, this, args); return result; }
    catch (error) { failure = error; throw error; }
    finally {
      calls.push({phase, kind: classifySpawn(args), wallMs: round(performance.now() - started),
        status: result?.status ?? null, signal: result?.signal ?? null,
        errorCode: result?.error?.code || failure?.code || null});
    }
  };
  syncBuiltinESMExports();
  try {
    const importedAt = performance.now();
    const api = await import(pathToFileURL(path.join(compilerRoot, 'dist/index.js')).href);
    const apiImportMs = round(performance.now() - importedAt);
    const samples = [];
    for (const value of values) {
      const request = requestFor(value);
      const options = {...request, engine: 'js', target: 'js', kernel: 'wasm'};
      const start = performance.now();
      const cpu = process.cpuUsage();
      const firstCall = calls.length;
      phase = 'candidate';
      const candidateStarted = performance.now();
      const prepared = api.compileCandidate(options);
      const candidateMs = performance.now() - candidateStarted;
      assert.equal(prepared.status, 'candidate-only');
      assert.equal(prepared.logicalAdmission, 'not-run');
      assert.equal(prepared.publicationAuthority, false);
      assert.equal(prepared.compilerSourceClosureDigest, manifest.proofscript.compilerSourceClosureDigest);
      const candidate = prepared.candidate;
      assert.equal(candidate.status, 'candidate', JSON.stringify(candidate));
      assert.equal(candidate.sourceClosureDigest, sourceDigest(request.sources));
      const admissionsSha256 = sha(candidate.admissionRequest.admissions);
      phase = 'kernel';
      const kernelStarted = performance.now();
      const checked = await api.checkCanonicalAdmissions(candidate.admissionRequest.admissions, {provider: 'wasm'});
      const kernelMs = performance.now() - kernelStarted;
      assert.equal(checked.accepted, true, JSON.stringify(checked));
      assert.equal(checked.agreement, true);
      assert.equal(checked.provider, 'wasm');
      assert.equal(checked.leanVersion, '4.35.0');
      assert.equal(checked.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
      assert.equal(checked.wasmMemoryModel, 'linear');
      assert.equal(checked.admissionsSha256, admissionsSha256);
      const sampleCalls = calls.slice(firstCall);
      const compilerProcesses = sampleCalls.filter(call => call.kind === 'compiler-process');
      const healthProcesses = sampleCalls.filter(call => call.kind === 'wasm-health-process');
      const checkProcesses = sampleCalls.filter(call => call.kind === 'wasm-check-process');
      assert.equal(compilerProcesses.length, 1, 'The qualified candidate API still launches its genuine compiler');
      assert.equal(healthProcesses.length, 1, 'The unchanged public checker performs its health check');
      assert.equal(checkProcesses.length, 1, 'Each distinct graph receives an actual Wasm check');
      const sum = rows => rows.reduce((total, row) => total + row.wallMs, 0);
      const usedCpu = process.cpuUsage(cpu);
      samples.push({sourceValue: value, wallMs: round(performance.now() - start),
        candidateMs: round(candidateMs), kernelMs: round(kernelMs),
        compilerProcessMs: round(sum(compilerProcesses)),
        wasmHealthProcessMs: round(sum(healthProcesses)), wasmCheckProcessMs: round(sum(checkProcesses)),
        candidateHostResidualMs: round(candidateMs - sum(sampleCalls.filter(call => call.phase === 'candidate'))),
        kernelHostResidualMs: round(kernelMs - sum(sampleCalls.filter(call => call.phase === 'kernel'))),
        outerProcessCpuMs: round((usedCpu.user + usedCpu.system) / 1000),
        sourceClosureDigest: candidate.sourceClosureDigest, admissionsSha256, subprocesses: sampleCalls});
    }
    return {apiImportMs, samples, outerProcessMaxRssKiB: process.resourceUsage().maxRSS,
      observationOnly: true, realSubprocessCallsPreserved: true,
      interpretation: 'One outer process retains imported API modules. Each candidate and each Wasm health/check command still executes its real subprocess. Command times include process and Wasm startup. Host residual includes pin verification, hashing, serialization, and other host work; it is not a pure hashing measurement.'};
  } finally {
    childProcess.spawnSync = original;
    syncBuiltinESMExports();
  }
}

function makePeer(file, args, directory, requireJobId = true) {
  const env = {...cleanEnvironment(), TMPDIR: directory, TMP: directory, TEMP: directory};
  const child = childProcess.fork(file, args, {cwd: toolsRoot, env, detached: true,
    execArgv: ['--max-old-space-size=1024'], stdio: ['ignore', 'ignore', 'pipe', 'ipc']});
  let pending, ended, stderr = '';
  child.stderr.on('data', bytes => {stderr = (stderr + bytes).slice(-16000);});
  const failPending = error => {
    if (pending) {const current = pending; pending = null; clearTimeout(current.timer); current.reject(error);}
  };
  child.once('error', error => {ended = error.message; failPending(error);});
  child.once('exit', (code, signal) => {
    ended = `exit ${signal || code}`;
    failPending(Error(`Profile child ${ended}: ${stderr}`));
  });
  child.on('message', result => {
    if (!pending) return;
    const current = pending; pending = null; clearTimeout(current.timer);
    if (requireJobId && result.jobId !== current.jobId) current.reject(Error('Profile worker response jobId mismatch'));
    else current.resolve({result, wallMs: round(performance.now() - current.started)});
  });
  return {
    request(request) {
      assert.ok(!pending, 'Profile sends one request at a time');
      if (ended) return Promise.reject(Error(`Profile worker already ended: ${ended}`));
      return new Promise((resolve, reject) => {
        const started = performance.now();
        const timer = setTimeout(() => failPending(Error(`Profile request exceeded 90 seconds: ${stderr}`)), 90000);
        pending = {resolve, reject, timer, started, jobId: request.jobId};
        child.send(request, error => {if (error) failPending(error);});
      });
    },
    close() {
      failPending(Error('Profile peer closed'));
      try {process.kill(-child.pid, 'SIGKILL');} catch {}
    },
  };
}

function assertWorkerResult(result, value) {
  assert.equal(result.state, 'checked', JSON.stringify(result));
  assert.equal(result.compilerVersion, '0.1.0-psc1.12');
  assert.equal(result.receipt.logicalAdmission, 'accepted');
  assert.deepEqual(result.receipt.kernelProviders, ['wasm']);
  assert.equal(result.receipt.targetValidation, 'not-run');
  assert.equal(result.receipt.publication, 'not-requested');
  assert.equal(result.receipt.sourceClosureDigest, sourceDigest(requestFor(value).sources));
  assert.match(result.receipt.admissionsSha256, /^[a-f0-9]{64}$/);
  assert.ok(result.declarations.some(row => row.name === 'identity' && row.verified));
}

function workerSample(observation, value) {
  const {result, wallMs} = observation;
  assertWorkerResult(result, value);
  return {sourceValue: value, wallMs, workerElapsedMs: result.elapsedMs, phases: result.timings,
    reusedKernelHealth: result.reusedKernelHealth ?? null,
    sourceClosureDigest: result.receipt.sourceClosureDigest, admissionsSha256: result.receipt.admissionsSha256};
}

async function main() {
  assert.equal(process.platform, 'linux', 'This focused stage profile runs in the Linux Actions job');
  const baseline = process.env.PSC1_PROFILE_BASELINE === '1';
  const label = process.env.PSC1_PROFILE_LABEL || (baseline ? 'baseline-0.1.1' : 'candidate-0.1.2');
  const lspRoot = path.resolve(process.env.PSC1_PROFILE_LSP_ROOT || path.join(toolsRoot, 'lsp'));
  const output = path.resolve(process.env.PSC1_PROFILE_OUTPUT || path.join(toolsRoot, 'dist/checking-startup-profile-receipt.json'));
  const compilerRoot = path.join(lspRoot, 'compiler/package');
  const manifest = JSON.parse(await fs.readFile(path.join(lspRoot, 'package.json'), 'utf8'));
  assert.equal(manifest.version, baseline ? '0.1.1' : '0.1.2');
  const values = [201, 202, 203, 204, 205];
  const temporary = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-startup-profile-'));
  const receipt = {schema: 'psc1-checking-startup-profile/1', status: 'running', label, baseline,
    measurementHarnessCommit: process.env.GITHUB_SHA || null, serverVersion: manifest.version,
    compiler: 'proofscript@0.1.0-psc1.12', compilerAndKernelSourceUnchanged: true,
    node: process.version, platform: process.platform, architecture: process.arch,
    cpu: os.cpus()[0]?.model, freshWorkers: [], retainedWorker: null, publicApis: null};
  try {
    if (process.env.PSC1_PROFILE_E2E_RECEIPT) {
      const existing = JSON.parse(await fs.readFile(path.resolve(process.env.PSC1_PROFILE_E2E_RECEIPT), 'utf8'));
      assert.equal(existing.status, 'passed');
      assert.equal(existing.measuredServer.version, manifest.version);
      receipt.endToEnd = existing;
    }
    for (const [index, value] of values.entries()) {
      const directory = path.join(temporary, `fresh-${index}`); await fs.mkdir(directory);
      const peer = makePeer(path.join(lspRoot, 'dist/worker.mjs'), [], directory, !baseline);
      try {receipt.freshWorkers.push(workerSample(await peer.request({...requestFor(value), jobId: index + 1}), value));}
      finally {peer.close();}
      if (!baseline) assert.equal(receipt.freshWorkers.at(-1).reusedKernelHealth, false);
    }
    if (!baseline) {
      const directory = path.join(temporary, 'retained'); await fs.mkdir(directory);
      const peer = makePeer(path.join(lspRoot, 'dist/worker.mjs'), [], directory);
      const samples = [];
      try {
        for (const [index, value] of values.entries())
          samples.push(workerSample(await peer.request({...requestFor(value), jobId: index + 1}), value));
      } finally {peer.close();}
      samples.forEach((sample, index) => assert.equal(sample.reusedKernelHealth, index > 0,
        'Only subsequent genuine checks in this worker reuse qualified health'));
      receipt.retainedWorker = {samples};
    }
    const directory = path.join(temporary, 'public-api'); await fs.mkdir(directory);
    const peer = makePeer(ownFile, ['--public-api'], directory);
    try {
      const {result} = await peer.request({jobId: 1, compilerRoot, values});
      assert.equal(result.status, 'passed', result.error);
      receipt.publicApis = result.profile;
    } finally {peer.close();}
    for (const [index, fresh] of receipt.freshWorkers.entries()) {
      for (const comparison of [receipt.publicApis.samples[index], receipt.retainedWorker?.samples[index]].filter(Boolean)) {
        assert.equal(comparison.sourceClosureDigest, fresh.sourceClosureDigest);
        assert.equal(comparison.admissionsSha256, fresh.admissionsSha256);
      }
    }
    assert.equal(new Set(receipt.freshWorkers.map(row => row.sourceClosureDigest)).size, values.length);
    assert.equal(new Set(receipt.freshWorkers.map(row => row.admissionsSha256)).size, values.length);
    receipt.identicalSourceAndAdmissionHashesAcrossModes = true;
    receipt.status = 'passed';
    receipt.interpretation = 'Five distinct checked graphs per mode. Fresh-worker timings include worker launch; retained-worker samples 2–5 reuse only the host process and qualified kernel health. Every graph still receives genuine compiler analysis and kernel admission. API tracing is exploratory and is not the uninstrumented end-to-end performance gate.';
  } catch (error) {
    receipt.status = 'failed'; receipt.error = String(error.stack || error);
    process.exitCode = 1;
  } finally {
    await fs.mkdir(path.dirname(output), {recursive: true});
    await fs.writeFile(output, JSON.stringify(receipt, null, 2) + '\n');
    await fs.rm(temporary, {recursive: true, force: true, maxRetries: 5, retryDelay: 100});
  }
  console.log('PSC1_CHECKING_STARTUP_PROFILE', JSON.stringify({label, status: receipt.status,
    freshMs: receipt.freshWorkers.map(row => row.wallMs),
    retainedMs: receipt.retainedWorker?.samples.map(row => row.wallMs),
    apiImportMs: receipt.publicApis?.apiImportMs, publicApiMs: receipt.publicApis?.samples.map(row => row.wallMs),
    error: receipt.error}));
}

if (process.argv[2] === '--public-api') {
  process.once('message', async request => {
    let response;
    try {response = {jobId: request.jobId, status: 'passed', profile: await profilePublicApis(request)};}
    catch (error) {response = {jobId: request.jobId, status: 'failed', error: String(error.stack || error)};}
    process.send(response, () => {process.disconnect(); process.exit(0);});
  });
} else await main();
