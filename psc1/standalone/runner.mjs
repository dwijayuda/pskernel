// Private-runtime compiler execution and Linux supervision. No compiler semantics.
// The generated compiler is never given checker or publication authority.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const MAX_WIRE = 128 * 1024 * 1024;
const MAX_LOG = 32 * 1024 * 1024;
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error('PSC1_INDEPENDENT_' + code); };
const object = value => value && typeof value === 'object' && !Array.isArray(value);
const self = fileURLToPath(import.meta.url);

function read(file, max = MAX_WIRE) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > max) fail('WORKER_FILE');
  const bytes = fs.readFileSync(file);
  if (bytes.length !== stat.size) fail('WORKER_FILE_CHANGED');
  return bytes;
}
function same(file, expected, max) {
  if (!/^[a-f0-9]{64}$/.test(expected || '') || sha(read(file, max)) !== expected)
    fail('WORKER_IDENTITY');
}
function decode(bytes) {
  return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
}
function environment() {
  const env = { ...process.env };
  for (const key of Object.keys(env))
    if (/^(NODE_|BUN_|NPM_|npm_|RUST|CARGO|DYLD_|LD_|PYTHON|LEAN_|ELAN_|PSC1_)/.test(key) ||
        ['ENV', 'BASH_ENV', 'OPENSSL_CONF', 'OPENSSL_MODULES'].includes(key)) delete env[key];
  return env;
}
function identity(pid) {
  try {
    const text = fs.readFileSync('/proc/' + pid + '/stat', 'utf8');
    return text.slice(text.lastIndexOf(')') + 2).split(' ')[19];
  } catch { return null; }
}
function memory(pid) {
  try {
    const value = fs.readFileSync('/proc/' + pid + '/status', 'utf8');
    const field = name => Number(new RegExp('^' + name + ':\\s+(\\d+)\\s+kB$', 'm').exec(value)?.[1] || 0);
    return { rssKiB: field('VmRSS'), highWaterKiB: field('VmHWM') };
  } catch { return { rssKiB: 0, highWaterKiB: 0 }; }
}
function loadJob(file, digest) {
  same(file, digest, 1024 * 1024);
  const job = JSON.parse(decode(read(file, 1024 * 1024)));
  if (!object(job) || job.schema !== 'psc1-independent-worker-job/1' ||
      !['compile', 'inspect'].includes(job.operation) ||
      !path.isAbsolute(job.compiler || '') || !path.isAbsolute(job.root || '') ||
      !['psCompilerServiceCandidate', 'compileCandidate'].includes(job.exportName) ||
      !/^[a-f0-9]{64}$/.test(job.compilerSha256 || '') ||
      ![240000, 3600000].includes(job.timeoutMs)) fail('WORKER_JOB');
  if (job.operation === 'compile') {
    if (!path.isAbsolute(job.request || '') || !path.isAbsolute(job.output || '') ||
        !/^[a-f0-9]{64}$/.test(job.requestSha256 || '')) fail('WORKER_JOB');
  } else if (!Array.isArray(job.publicNames) ||
      job.publicNames.some(name => typeof name !== 'string' || !name) ||
      new Set(job.publicNames).size !== job.publicNames.length) fail('WORKER_JOB');
  return job;
}

async function execute(jobFile, jobSha256) {
  const job = loadJob(jobFile, jobSha256), started = Date.now();
  same(job.compiler, job.compilerSha256);
  const input = job.operation === 'compile' ? read(job.request) : null;
  if (input && sha(input) !== job.requestSha256) fail('WORKER_REQUEST_CHANGED');
  const module = await import(pathToFileURL(job.compiler).href);
  let output;
  if (job.operation === 'inspect') {
    const names = Object.keys(module).sort();
    if (JSON.stringify(names) !== JSON.stringify([...job.publicNames].sort()))
      fail('OUTPUT_API_MISMATCH');
  } else {
    if (typeof module[job.exportName] !== 'function') fail('WORKER_EXPORT');
    output = module[job.exportName](decode(input));
    if (typeof output !== 'string' || Buffer.byteLength(output) > MAX_WIRE)
      fail('WORKER_RESPONSE_LIMIT');
  }
  same(job.compiler, job.compilerSha256);
  same(jobFile, jobSha256, 1024 * 1024);
  if (input) {
    same(job.request, job.requestSha256);
    const fd = fs.openSync(job.output, 'wx', 0o600);
    try { fs.writeFileSync(fd, output); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  }
  process.stdout.write(JSON.stringify({
    protocol: 'psc1-independent-worker/1', operation: job.operation,
    compilerSha256: job.compilerSha256,
    ...(input ? { requestSha256: job.requestSha256, responseSha256: sha(output),
      responseUtf8Bytes: Buffer.byteLength(output) } : { publicNames: job.publicNames }),
    elapsedMs: Date.now() - started, maxRssKiB: process.resourceUsage().maxRSS,
  }) + '\n');
}

async function supervise(jobFile, jobSha256, parentPidText, parentIdentity) {
  const job = loadJob(jobFile, jobSha256);
  const parentPid = Number(parentPidText);
  if (process.platform !== 'linux' || !Number.isSafeInteger(parentPid) || parentPid <= 0 ||
      !parentIdentity || identity(parentPid) !== parentIdentity) fail('SUPERVISOR_PARENT');
  const started = Date.now();
  // Permission flags limit accidental effects. Node's permission model is not
  // represented as a security sandbox against malicious native/runtime code.
  const reads = [self, jobFile, job.compiler, ...(job.request ? [job.request] : [])];
  const args = ['--max-old-space-size=4096', '--permission',
    ...reads.map(file => '--allow-fs-read=' + file),
    ...(job.output ? ['--allow-fs-write=' + job.output] : []),
    self, 'execute', jobFile, jobSha256];
  const child = spawn(process.execPath, args, {
    cwd: path.dirname(jobFile), env: environment(), detached: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let childIdentity = child.pid ? identity(child.pid) : null;
  let stdout = [], stderr = [], stdoutBytes = 0, stderrBytes = 0;
  let peakRssKiB = 0, failure = null, nextHeartbeat = started + 60000;
  let finishing = false;
  const kill = () => {
    if (!child.pid) return;
    const current = identity(child.pid);
    if (childIdentity && current && current !== childIdentity) return;
    try { process.kill(-child.pid, 'SIGKILL'); } catch (error) {
      if (error.code !== 'ESRCH') throw error;
    }
  };
  const refuse = code => {
    if (!failure) failure = code;
    kill();
  };
  const collect = (name, chunk) => {
    const count = name === 'stdout' ? stdoutBytes : stderrBytes;
    const take = Math.min(chunk.length, Math.max(0, MAX_LOG - count));
    if (take) (name === 'stdout' ? stdout : stderr).push(chunk.subarray(0, take));
    if (name === 'stdout') stdoutBytes += take; else stderrBytes += take;
    if (take !== chunk.length) refuse('SUPERVISOR_OUTPUT_LIMIT');
  };
  child.stdout.on('data', chunk => collect('stdout', chunk));
  child.stderr.on('data', chunk => collect('stderr', chunk));
  const signals = new Map();
  for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
    const listener = () => refuse('SUPERVISOR_' + signal);
    signals.set(signal, listener); process.on(signal, listener);
  }
  const timer = setInterval(() => {
    if (finishing) return;
    if (!childIdentity && child.pid) childIdentity = identity(child.pid);
    const observed = memory(child.pid);
    peakRssKiB = Math.max(peakRssKiB, observed.rssKiB, observed.highWaterKiB);
    if (identity(parentPid) !== parentIdentity) refuse('SUPERVISOR_PARENT_EXITED');
    if (Date.now() - started >= job.timeoutMs) refuse('SUPERVISOR_DEADLINE');
    if (Date.now() >= nextHeartbeat) {
      process.stderr.write('PSC1_INDEPENDENT_HEARTBEAT: ' + JSON.stringify({
        elapsedMs: Date.now() - started, timeoutMs: job.timeoutMs,
        rssKiB: observed.rssKiB, peakRssKiB,
        observation: 'process resources; not semantic progress',
      }) + '\n');
      nextHeartbeat = Date.now() + 60000;
    }
  }, 100);
  try {
    const result = await new Promise(resolve => {
      child.once('error', error => {
        failure = 'SUPERVISOR_SPAWN:' + error.message;
        resolve({ code: null, signal: null });
      });
      child.once('close', (code, signal) => resolve({ code, signal }));
    });
    finishing = true; clearInterval(timer);
    if (failure || result.code !== 0) {
      const detail = Buffer.concat(stderr).toString('utf8').slice(-8192);
      fail((failure || 'WORKER_FAILED:' + result.code + ':' + result.signal) + ':' + detail);
    }
    const event = JSON.parse(Buffer.concat(stdout).toString('utf8').trim());
    if (event.protocol !== 'psc1-independent-worker/1' ||
        event.operation !== job.operation || event.compilerSha256 !== job.compilerSha256)
      fail('SUPERVISOR_EVENT');
    same(jobFile, jobSha256, 1024 * 1024);
    process.stdout.write(JSON.stringify({
      ...event, supervisorElapsedMs: Date.now() - started,
      peakRssKiB: Math.max(peakRssKiB, event.maxRssKiB || 0),
      timeoutMs: job.timeoutMs, stdoutBytes, stderrBytes,
      memoryMeasurement: 'worker getrusage maxRSS plus sampled Linux /proc VmRSS/VmHWM',
      runtime: { node: process.versions.node, embedded: true },
    }) + '\n');
  } finally {
    finishing = true; clearInterval(timer);
    for (const [signal, listener] of signals) process.removeListener(signal, listener);
    kill();
  }
}

try {
  const [mode, ...args] = process.argv.slice(2);
  if (process.version !== 'v22.23.3') fail('WORKER_RUNTIME');
  if (mode === 'execute' && args.length === 2) await execute(...args);
  else if (mode === 'supervise' && args.length === 4) await supervise(...args);
  else fail('WORKER_ARGUMENTS');
} catch (error) {
  process.stderr.write(String(error?.stack || error) + '\n');
  process.exitCode = 1;
}
