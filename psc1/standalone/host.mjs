// Independent development host. Compiler semantics remain in PSC1-generated code.
// The private distribution runtime and actual independent checker are explicit.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = fs.realpathSync(path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..'));
const MAX_WIRE = 128 * 1024 * 1024, MAX_LOG = 32 * 1024 * 1024;
const CHECKER_COMMIT = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const artifactFiles = ['admissions.json', 'build.json', 'candidate.json', 'compiler.mjs',
  'original-ir.json', 'sources.json', 'specialized-ir.json'];
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const fail = code => { throw new Error('PSC1_INDEPENDENT_' + code); };
const object = value => value && typeof value === 'object' && !Array.isArray(value);
const exists = file => fs.lstatSync(file, { throwIfNoEntry: false }) !== undefined;
const decode = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
let interrupted = null;

function sanitizeEnvironment() {
  for (const key of Object.keys(process.env))
    if (/^(NODE_|BUN_|NPM_|npm_|RUST|CARGO|DYLD_|LD_|PYTHON|LEAN_|ELAN_|PSC1_)/.test(key) ||
        ['ENV', 'BASH_ENV', 'OPENSSL_CONF', 'OPENSSL_MODULES'].includes(key)) delete process.env[key];
}
function regular(file, max = MAX_WIRE, code = 'FILE') {
  let stat;
  try { stat = fs.lstatSync(file); } catch { fail(code + ':' + file); }
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > max) fail(code + ':' + file);
  const bytes = fs.readFileSync(file);
  if (bytes.length !== stat.size) fail(code + '_CHANGED:' + file);
  return bytes;
}
function contained(base, relative, code) {
  if (typeof relative !== 'string' || !relative || relative.includes('\\') ||
      relative.includes('\0') || path.isAbsolute(relative) ||
      relative.split('/').some(part => !part || part === '.' || part === '..')) fail(code);
  let current = base;
  const parts = relative.split('/');
  for (let index = 0; index < parts.length; index++) {
    current = path.join(current, parts[index]);
    const stat = fs.lstatSync(current, { throwIfNoEntry: false });
    if (!stat || stat.isSymbolicLink() || (index < parts.length - 1 && !stat.isDirectory()))
      fail(code + ':' + relative);
  }
  return current;
}
function processIdentity(pid) {
  try {
    const text = fs.readFileSync('/proc/' + pid + '/stat', 'utf8');
    return text.slice(text.lastIndexOf(')') + 2).split(' ')[19];
  } catch { fail('PROC_REQUIRED'); }
}
function requireKeys(value, keys, code) {
  if (!object(value) || JSON.stringify(Object.keys(value).sort()) !== JSON.stringify([...keys].sort()))
    fail(code);
}
function loadToolchain() {
  if (process.platform !== 'linux' || !['x64', 'arm64'].includes(process.arch)) fail('PLATFORM');
  if (process.version !== 'v22.23.3') fail('RUNTIME_VERSION');
  const file = path.join(root, 'toolchain.json');
  const bytes = regular(file, 4 * 1024 * 1024, 'TOOLCHAIN_FILE');
  const manifest = JSON.parse(decode(bytes));
  if (!object(manifest) || manifest.schema !== 'psc1-independent-toolchain/1' ||
      manifest.platform !== 'linux-' + process.arch || manifest.nodeVersion !== '22.23.3' ||
      !Array.isArray(manifest.resources) || manifest.resources.length === 0 ||
      manifest.resources.length > 4096) fail('TOOLCHAIN_MANIFEST');
  const roles = {
    runtime: 'libexec/psc-runtime', checker: 'kernel/checker', compiler: 'engine/compiler.mjs',
  };
  const resources = new Map();
  for (const row of manifest.resources) {
    if (!object(row) || typeof row.path !== 'string' || resources.has(row.path) ||
        !/^[a-f0-9]{64}$/.test(row.sha256 || '') ||
        !Number.isSafeInteger(row.bytes) || row.bytes < 0 || row.bytes > 512 * 1024 * 1024)
      fail('TOOLCHAIN_RESOURCE');
    resources.set(row.path, { ...row });
  }
  for (const [role, expected] of Object.entries(roles)) {
    const row = manifest[role], pin = resources.get(expected);
    if (!object(row) || row.path !== expected || !pin || row.sha256 !== pin.sha256)
      fail('TOOLCHAIN_ROLE:' + role);
  }
  if (!['psCompilerServiceCandidate', 'compileCandidate'].includes(manifest.compiler.exportName))
    fail('TOOLCHAIN_COMPILER_EXPORT');
  for (const required of ['standalone/host.mjs', 'standalone/runner.mjs',
    'host-tools/compiler-host-protocol.mjs', 'host-tools/runtime-policy.mjs',
    'host-tools/contracts/compiler-closure.mjs'])
    if (!resources.has(required)) fail('TOOLCHAIN_RESOURCE_MISSING:' + required);
  const manifestHash = sha(bytes);
  function verify() {
    if (sha(regular(file, 4 * 1024 * 1024, 'TOOLCHAIN_FILE')) !== manifestHash)
      fail('TOOLCHAIN_CHANGED');
    for (const [relative, pin] of resources) {
      const absolute = contained(root, relative, 'RESOURCE_CHANGED');
      const data = regular(absolute, 512 * 1024 * 1024, 'RESOURCE_CHANGED');
      if (data.length !== pin.bytes || sha(data) !== pin.sha256)
        fail('RESOURCE_CHANGED:' + relative);
    }
  }
  verify();
  const runtime = path.join(root, roles.runtime);
  if (fs.realpathSync(process.execPath) !== runtime) fail('PRIVATE_RUNTIME_REQUIRED');
  return { manifest, manifestHash, resources, verify, runtime,
    checker: path.join(root, roles.checker), runner: path.join(root, 'standalone/runner.mjs') };
}

function captureProject(input) {
  let project = path.resolve(input);
  if (fs.lstatSync(project).isDirectory()) project = path.join(project, 'project.json');
  const base = fs.realpathSync(path.dirname(project));
  project = contained(base, path.basename(project), 'PROJECT_PATH');
  const bytes = regular(project, 1024 * 1024, 'PROJECT_FILE');
  const manifest = JSON.parse(decode(bytes));
  requireKeys(manifest, ['schemaVersion', 'entryModule', 'sources'], 'PROJECT_FIELDS');
  if (manifest.schemaVersion !== 1 || typeof manifest.entryModule !== 'string' ||
      !Array.isArray(manifest.sources) || manifest.sources.length === 0 ||
      manifest.sources.length > 512) fail('PROJECT_SCHEMA');
  const names = new Set(), paths = new Set(), records = [], sources = [];
  let total = 0;
  for (const row of manifest.sources) {
    requireKeys(row, ['module', 'path'], 'PROJECT_SOURCE_FIELDS');
    if (!/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$/.test(row.module || '') ||
        names.has(row.module) || paths.has(row.path) || typeof row.path !== 'string' || !row.path.endsWith('.ps'))
      fail('PROJECT_SOURCE');
    names.add(row.module); paths.add(row.path);
    const file = contained(base, row.path, 'SOURCE_PATH');
    const data = regular(file, 1024 * 1024, 'SOURCE_FILE');
    total += data.length;
    if (total > MAX_LOG) fail('SOURCE_CLOSURE_LIMIT');
    records.push({ file, bytes: data.length, sha256: sha(data) });
    sources.push(Object.freeze({ module: row.module, kind: 'ps', text: decode(data) }));
  }
  if (!names.has(manifest.entryModule)) fail('PROJECT_ENTRY');
  const projectHash = sha(bytes);
  return {
    project, base, entryModule: manifest.entryModule, sources: Object.freeze(sources),
    sourceBytes: total,
    verify() {
      if (sha(regular(project, 1024 * 1024, 'PROJECT_FILE')) !== projectHash)
        fail('PROJECT_CHANGED');
      for (const row of records) {
        if (fs.realpathSync(row.file) !== row.file) fail('SOURCE_CHANGED');
        const data = regular(row.file, 1024 * 1024, 'SOURCE_FILE');
        if (data.length !== row.bytes || sha(data) !== row.sha256) fail('SOURCE_CHANGED');
      }
    },
  };
}

function verifyBuiltCompiler(directory, tc) {
  const base = fs.realpathSync(path.resolve(directory));
  const fileListBytes = regular(path.join(base, 'files.json'), 1024 * 1024, 'ARTIFACT_FILE');
  const list = JSON.parse(decode(fileListBytes));
  if (!object(list) || list.schema !== 'psc1-independent-files/1' ||
      !Array.isArray(list.files) ||
      JSON.stringify(list.files.map(row => row.path).sort()) !== JSON.stringify(artifactFiles))
    fail('ARTIFACT_FILES');
  const expected = new Map();
  for (const row of list.files) {
    if (!object(row) || expected.has(row.path) || !Number.isSafeInteger(row.bytes) ||
        row.bytes < 0 || row.bytes > MAX_WIRE || !/^[a-f0-9]{64}$/.test(row.sha256 || ''))
      fail('ARTIFACT_FILES');
    expected.set(row.path, { ...row });
  }
  const listHash = sha(fileListBytes);
  function verify() {
    if (sha(regular(path.join(base, 'files.json'), 1024 * 1024, 'ARTIFACT_FILE')) !== listHash)
      fail('ARTIFACT_CHANGED');
    for (const [relative, pin] of expected) {
      const file = contained(base, relative, 'ARTIFACT_FILE');
      const bytes = regular(file, MAX_WIRE, 'ARTIFACT_FILE');
      if (bytes.length !== pin.bytes || sha(bytes) !== pin.sha256) fail('ARTIFACT_CHANGED:' + relative);
    }
  }
  verify();
  const build = JSON.parse(decode(regular(path.join(base, 'build.json'))));
  if (build.schema !== 'psc1-independent-build/1' || build.target !== 'js' ||
      build.checker?.sha256 !== tc.manifest.checker.sha256 ||
      build.checker?.leanCommit !== CHECKER_COMMIT ||
      build.checker?.accepted !== true || build.checker?.executed !== true ||
      JSON.stringify(build.publicNames) !== JSON.stringify(['psCompilerServiceCandidate']) ||
      build.identities?.sourceSha256 !== expected.get('compiler.mjs').sha256 ||
      build.identities?.admissionsSha256 !== expected.get('admissions.json').sha256 ||
      build.identities?.originalIrSha256 !== expected.get('original-ir.json').sha256 ||
      build.identities?.specializedIrSha256 !== expected.get('specialized-ir.json').sha256)
    fail('ARTIFACT_COMPILER');
  const storedSources = JSON.parse(decode(regular(path.join(base, 'sources.json'))));
  const storedCandidate = JSON.parse(decode(regular(path.join(base, 'candidate.json'))));
  if (!Array.isArray(storedSources) || storedSources.length !== build.sourceModules ||
      storedSources.some(row => !object(row) || row.kind !== 'ps' ||
        typeof row.module !== 'string' || typeof row.text !== 'string'))
    fail('ARTIFACT_SOURCE');
  const sourceDigest = sha(JSON.stringify(storedSources.map(row => ({
    module: row.module, kind: row.kind, utf8Sha256: sha(row.text),
  }))));
  if (sourceDigest !== build.identities.sourceClosureDigest ||
      storedCandidate.sourceClosureDigest !== sourceDigest ||
      sha(storedCandidate.source || '') !== build.identities.sourceSha256 ||
      storedCandidate.admissionRequest?.admissions !== decode(regular(path.join(base, 'admissions.json'))) ||
      JSON.stringify(storedCandidate.originalIr) !== decode(regular(path.join(base, 'original-ir.json'))) ||
      JSON.stringify(storedCandidate.specializedIr) !== decode(regular(path.join(base, 'specialized-ir.json'))))
    fail('ARTIFACT_CORRESPONDENCE');
  // These editable receipts establish integrity relative to the selected files.
  // They are not signed certificates and never authorize checking/publication.
  return { file: path.join(base, 'compiler.mjs'), sha256: build.identities.sourceSha256,
    exportName: 'psCompilerServiceCandidate', verify, provenance: 'user-selected-built-compiler' };
}
function compiler(tc, selected) {
  if (selected) return verifyBuiltCompiler(selected, tc);
  return { file: path.join(root, 'engine/compiler.mjs'), sha256: tc.manifest.compiler.sha256,
    exportName: tc.manifest.compiler.exportName, verify: tc.verify, provenance: 'pinned-bootstrap' };
}

async function runWorker(tc, selected, job, work) {
  tc.verify(); selected.verify();
  const jobFile = path.join(work, 'job-' + crypto.randomUUID() + '.json');
  const wire = JSON.stringify({ schema: 'psc1-independent-worker-job/1', root,
    compiler: selected.file, compilerSha256: selected.sha256, exportName: selected.exportName, ...job });
  fs.writeFileSync(jobFile, wire, { flag: 'wx', mode: 0o600 });
  const args = [tc.runner, 'supervise', jobFile, sha(wire), String(process.pid), processIdentity(process.pid)];
  const started = Date.now();
  const child = spawn(tc.runtime, args, { cwd: work, env: { ...process.env },
    stdio: ['ignore', 'pipe', 'pipe'] });
  const chunks = { stdout: [], stderr: [] }, counts = { stdout: 0, stderr: 0 };
  let failure = null, escalation;
  function stop(code) {
    if (!failure) failure = code;
    child.kill('SIGTERM');
    escalation ??= setTimeout(() => child.kill('SIGKILL'), 2000);
  }
  for (const name of ['stdout', 'stderr']) child[name].on('data', chunk => {
    const room = Math.max(0, MAX_LOG - counts[name]), take = Math.min(room, chunk.length);
    if (take) chunks[name].push(chunk.subarray(0, take));
    counts[name] += take;
    if (take !== chunk.length) stop('HOST_LOG_LIMIT');
    if (name === 'stderr' && take) process.stderr.write(chunk.subarray(0, take));
  });
  const listeners = new Map();
  for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
    const listener = () => { interrupted = signal; stop('INTERRUPTED:' + signal); };
    listeners.set(signal, listener); process.on(signal, listener);
  }
  const timer = setTimeout(() => stop('HOST_DEADLINE'), job.timeoutMs + 10000);
  let result;
  try {
    result = await new Promise(resolve => {
      child.once('error', error => { failure = 'HOST_SPAWN:' + error.message; resolve({ code: null }); });
      child.once('close', (code, signal) => resolve({ code, signal }));
    });
  } finally {
    clearTimeout(timer); if (escalation) clearTimeout(escalation);
    for (const [signal, listener] of listeners) process.removeListener(signal, listener);
  }
  if (failure || result.code !== 0)
    fail((failure || 'COMPILER_PROCESS:' + result.code + ':' + result.signal) + ':' +
      Buffer.concat(chunks.stderr).toString('utf8').slice(-8192));
  tc.verify(); selected.verify();
  if (sha(regular(jobFile, 1024 * 1024)) !== sha(wire)) fail('JOB_CHANGED');
  const event = JSON.parse(Buffer.concat(chunks.stdout).toString('utf8').trim());
  if (event.protocol !== 'psc1-independent-worker/1' ||
      event.operation !== job.operation || event.compilerSha256 !== selected.sha256)
    fail('WORKER_EVENT');
  return { ...event, hostElapsedMs: Date.now() - started };
}

function validateCandidate(value, capture, request, validateClosureCounts) {
  if (!object(value)) fail('RESPONSE_OBJECT');
  if (value.status !== 'candidate')
    fail('COMPILER_REFUSED:' + JSON.stringify(value));
  requireKeys(value, ['admission', 'admissionRequest', 'assurance', 'candidateOnly', 'grammar',
    'logicalDeclarations', 'originalIr', 'origins', 'partialNames', 'protocol', 'publicNames',
    'requestId', 'runtimeRequirements', 'source', 'sourceClosureDigest', 'sourceDeclarations',
    'specializedIr', 'status', 'target'], 'RESPONSE_FIELDS');
  for (const [key, expected] of Object.entries({
    protocol: 'psc1-compiler-service/1', requestId: request.id, sourceClosureDigest: request.digest,
    grammar: 'ps', assurance: 'ordinary-checked', target: 'js', candidateOnly: true, admission: 'not-run',
  })) if (value[key] !== expected) fail('RESPONSE_IDENTITY:' + key);
  if (typeof value.source !== 'string' || !value.source || Buffer.byteLength(value.source) > MAX_WIRE ||
      !Array.isArray(value.publicNames) || value.publicNames.some(name => typeof name !== 'string' || !name) ||
      new Set(value.publicNames).size !== value.publicNames.length ||
      !Array.isArray(value.runtimeRequirements) || value.runtimeRequirements.some(name => typeof name !== 'string') ||
      !Array.isArray(value.origins) || value.origins.length !== capture.sources.length) fail('RESPONSE_SHAPE');
  let sourceCount = 0;
  value.origins.forEach((row, index) => {
    if (!Array.isArray(row) || row.length !== 4 || row[0] !== capture.sources[index].module ||
        row[1] !== Buffer.byteLength(capture.sources[index].text) || !Array.isArray(row[3])) fail('ORIGIN');
    row[3].forEach((origin, sourceIndex) => {
      if (!Array.isArray(origin) || origin.length !== 5 || origin[0] !== sourceIndex ||
          typeof origin[1] !== 'string' || !Array.isArray(origin[4])) fail('ORIGIN');
      origin[4].forEach((member, memberIndex) => {
        if (!Array.isArray(member) || member.length !== 2 || member[0] !== memberIndex ||
            typeof member[1] !== 'string') fail('ORIGIN_MEMBER');
        sourceCount++;
      });
    });
  });
  validateClosureCounts({ assurance: 'ordinary-checked',
    sourceCoreDeclarations: value.sourceDeclarations, coreDeclarations: value.logicalDeclarations,
    partialNames: value.partialNames }, sourceCount, 'ordinary-checked');
  for (const graph of [value.originalIr, value.specializedIr])
    if (!Array.isArray(graph) || graph.length !== 5 || graph[0] !== 'psc1-ir/1' ||
        !graph.slice(1).every(Array.isArray)) fail('IR_SHAPE');
  if (typeof value.admissionRequest?.admissions !== 'string' ||
      !value.admissionRequest.admissions || Buffer.byteLength(value.admissionRequest.admissions) > MAX_WIRE)
    fail('ADMISSIONS_SHAPE');
}

function writeSynced(file, bytes) {
  const fd = fs.openSync(file, 'wx', 0o600);
  try { fs.writeFileSync(fd, bytes); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}
function syncDirectory(directory) {
  const fd = fs.openSync(directory, 'r');
  try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}
function publish(stage, destination) {
  if (exists(destination)) fail('OUTPUT_EXISTS');
  // Exclusive directory creation reserves the destination without replacing any
  // existing path. files.json is the completion marker and is always written last.
  fs.mkdirSync(destination, { mode: 0o700 });
  const owned = fs.statSync(destination), created = [];
  let committed = false;
  try {
    const pins = [];
    for (const name of artifactFiles) {
      const bytes = regular(path.join(stage, name));
      writeSynced(path.join(destination, name), bytes);
      created.push({ name, sha256: sha(bytes) });
      pins.push({ path: name, bytes: bytes.length, sha256: sha(bytes) });
    }
    const manifest = json({ schema: 'psc1-independent-files/1', files: pins });
    writeSynced(path.join(destination, 'files.json'), manifest);
    created.push({ name: 'files.json', sha256: sha(manifest) });
    committed = true;
    syncDirectory(destination); syncDirectory(path.dirname(destination));
  } catch (error) {
    if (committed) fail('PUBLICATION_COMMITTED_UNCERTAIN:' + destination + ':' + error.message);
    // Remove only our own unchanged files. A concurrently altered destination
    // remains visibly incomplete and is never accepted as a compiler.
    const current = fs.lstatSync(destination, { throwIfNoEntry: false });
    if (current?.isDirectory() && current.dev === owned.dev && current.ino === owned.ino) {
      for (const row of created.reverse()) {
        const file = path.join(destination, row.name);
        try {
          const bytes = regular(file);
          if (sha(bytes) === row.sha256) fs.unlinkSync(file);
        } catch {}
      }
      try { fs.rmdirSync(destination); } catch {}
    }
    throw error;
  }
}

async function build(tc, helpers, project, output, selectedDirectory, profile = 'ordinary-240s') {
  if (!['ordinary-240s', 'correctness-3600s'].includes(profile)) fail('PROFILE');
  const capture = captureProject(project), selected = compiler(tc, selectedDirectory);
  const destination = output ? path.resolve(output) : null;
  if (destination && exists(destination)) fail('OUTPUT_EXISTS');
  const temporaryParent = destination ? path.dirname(destination) : os.tmpdir();
  fs.mkdirSync(temporaryParent, { recursive: true });
  const work = fs.mkdtempSync(path.join(temporaryParent, '.psc-independent-'));
  fs.chmodSync(work, 0o700);
  const digest = helpers.compilerSourceClosureDigest(capture.sources);
  const id = 'psc1-independent-' + digest.slice(0, 24);
  const wire = JSON.stringify(['psc1-unified-compiler-service/2', 'js',
    ['psc1-compiler-service/1', id, digest, 'ps', 'ordinary-checked', capture.entryModule,
      capture.sources.map(row => [row.module, row.text])]]);
  if (Buffer.byteLength(wire) > MAX_WIRE) {
    fs.rmSync(work, { recursive: true, force: true }); fail('REQUEST_LIMIT');
  }
  const requestFile = path.join(work, 'request.json'), candidateFile = path.join(work, 'candidate.json');
  writeSynced(requestFile, wire);
  const started = Date.now();
  process.stderr.write('PSC1_INDEPENDENT_BUILD_STARTED: ' + JSON.stringify({
    sourceModules: capture.sources.length, sourceClosureDigest: digest, profile,
    compilerSha256: selected.sha256,
  }) + '\n');
  try {
    const execution = await runWorker(tc, selected, {
      operation: 'compile', request: requestFile, requestSha256: sha(wire), output: candidateFile,
      timeoutMs: profile === 'correctness-3600s' ? 3600000 : 240000,
    }, work);
    const candidateBytes = regular(candidateFile);
    if (execution.requestSha256 !== sha(wire) || execution.responseSha256 !== sha(candidateBytes) ||
        sha(regular(requestFile)) !== sha(wire)) fail('EXECUTION_CORRESPONDENCE');
    const candidate = JSON.parse(decode(candidateBytes));
    validateCandidate(candidate, capture, { id, digest }, helpers.validateClosureCounts);
    capture.verify(); tc.verify(); selected.verify();
    const admissions = candidate.admissionRequest.admissions;
    const checkerStart = Date.now();
    const session = helpers.createCompilerHostSession({
      requestId: id, target: 'js', sources: capture.sources, canonicalAdmissions: admissions,
      checkerExecutable: tc.checker,
    });
    const accepted = session.admit(JSON.stringify(candidate.admissionRequest));
    const checker = {
      path: 'kernel/checker', sha256: tc.manifest.checker.sha256,
      leanCommit: accepted.checkerCommit, accepted: accepted.accepted === true, executed: true,
      admissionsSha256: accepted.admissionsDigest, elapsedMs: Date.now() - checkerStart,
      admissionReceiptSha256: sha(JSON.stringify(accepted)),
    };
    if (!checker.accepted || checker.leanCommit !== CHECKER_COMMIT) fail('CHECKER_ACCEPTANCE');
    tc.verify(); selected.verify(); capture.verify();
    const emitted = path.join(work, 'compiler.mjs');
    writeSynced(emitted, candidate.source);
    const emittedCompiler = {
      file: emitted, sha256: sha(candidate.source), exportName: 'psCompilerServiceCandidate',
      verify() { if (sha(regular(emitted)) !== sha(candidate.source)) fail('CANDIDATE_CHANGED'); },
    };
    const api = await runWorker(tc, emittedCompiler, {
      operation: 'inspect', publicNames: candidate.publicNames, timeoutMs: 240000,
    }, work);
    tc.verify(); selected.verify(); capture.verify();
    const original = JSON.stringify(candidate.originalIr), specialized = JSON.stringify(candidate.specializedIr);
    const identities = {
      sourceClosureDigest: digest, sourceSha256: sha(candidate.source), admissionsSha256: sha(admissions),
      originalIrSha256: sha(original), specializedIrSha256: sha(specialized),
    };
    const receipt = {
      schema: 'psc1-independent-build/1', target: 'js', grammar: 'ps', assurance: 'ordinary-checked',
      entryModule: capture.entryModule, sourceModules: capture.sources.length, sourceBytes: capture.sourceBytes,
      publicNames: candidate.publicNames, identities, checker, execution, api,
      producer: { sha256: selected.sha256, provenance: selected.provenance },
      toolchainSha256: tc.manifestHash, profile, elapsedMs: Date.now() - started,
      authority: { actualIndependentAdmission: true, compilerPreservationProof: false,
        receiptIsCertificate: false, sourceAndIrChecks: 'generated strict original and transformed IR validation' },
    };
    if (destination) {
      const stage = path.join(work, 'publication'); fs.mkdirSync(stage);
      const payloads = {
        'compiler.mjs': candidate.source, 'candidate.json': candidateBytes,
        'admissions.json': admissions, 'original-ir.json': original, 'specialized-ir.json': specialized,
        'sources.json': JSON.stringify(capture.sources), 'build.json': json(receipt),
      };
      for (const [name, bytes] of Object.entries(payloads)) writeSynced(path.join(stage, name), bytes);
      capture.verify(); tc.verify(); selected.verify();
      publish(stage, destination);
    }
    return { ...receipt, ...(destination ? { output: destination } : {}), checked: true };
  } finally {
    // This unique private directory is host-created, never supplied in generated wire.
    fs.rmSync(work, { recursive: true, force: true });
  }
}

async function diagnostic(tc, selectedDirectory) {
  const selected = compiler(tc, selectedDirectory);
  const work = fs.mkdtempSync(path.join(os.tmpdir(), '.psc-diagnostic-'));
  fs.chmodSync(work, 0o700);
  try {
    const wire = JSON.stringify(['psc1-unified-compiler-service/2', 'js']);
    const request = path.join(work, 'request.json'), output = path.join(work, 'response.json');
    writeSynced(request, wire);
    const event = await runWorker(tc, selected, {
      operation: 'compile', request, requestSha256: sha(wire), output, timeoutMs: 240000,
    }, work);
    const bytes = regular(output);
    if (event.responseSha256 !== sha(bytes)) fail('DIAGNOSTIC_CORRESPONDENCE');
    const response = JSON.parse(decode(bytes));
    if (response.status !== 'refused' || response.phase !== 'wire' ||
        typeof response.code !== 'string' || response.admission !== 'not-run' ||
        response.candidateOnly !== true || Object.hasOwn(response, 'source'))
      fail('DIAGNOSTIC_REFUSAL');
    return response;
  } finally { fs.rmSync(work, { recursive: true, force: true }); }
}
function parseOptions(args, projectRequired) {
  const result = { project: projectRequired ? args.shift() : undefined };
  if (projectRequired && (!result.project || result.project.startsWith('--'))) fail('PROJECT_REQUIRED');
  while (args.length) {
    const flag = args.shift();
    const key = { '--out': 'out', '--compiler': 'compiler', '--profile': 'profile' }[flag];
    if (!key || result[key] !== undefined || !args.length || args[0].startsWith('--')) fail('ARGUMENTS');
    result[key] = args.shift();
  }
  return result;
}
async function main() {
  sanitizeEnvironment();
  const [command = 'help', ...args] = process.argv.slice(2);
  if (command === 'help' || command === '--help') {
    process.stdout.write('usage: psc identity | build PROJECT --out DIR [--compiler DIR] [--profile correctness-3600s]\n' +
      '       psc check PROJECT [--compiler DIR] [--profile correctness-3600s]\n' +
      '       psc selfhost PROJECT --out DIR [--compiler DIR]\n' +
      '       psc diagnostic [--compiler DIR]\n');
    return;
  }
  const tc = loadToolchain();
  if (command === 'identity') {
    if (args.length) fail('ARGUMENTS');
    process.stdout.write(json({
      schema: 'psc1-independent-identity/1', platform: tc.manifest.platform,
      sourceCommit: tc.manifest.sourceCommit, toolchainSha256: tc.manifestHash,
      runtime: { implementation: 'Node.js', version: process.versions.node, embedded: true,
        sha256: tc.manifest.runtime.sha256 },
      compiler: tc.manifest.compiler,
      checker: { ...tc.manifest.checker, leanCommit: CHECKER_COMMIT },
      separatelyInstalledLanguageTools: [], authority: 'distribution identity; not a proof certificate',
    }));
    return;
  }
  if (command === 'diagnostic') {
    const options = parseOptions(args, false);
    if (options.out || options.profile) fail('ARGUMENTS');
    process.stdout.write(json(await diagnostic(tc, options.compiler))); return;
  }
  if (!['build', 'check', 'selfhost'].includes(command)) fail('COMMAND');
  const options = parseOptions(args, true);
  if (command === 'check' ? options.out !== undefined : !options.out) fail('OUTPUT_ARGUMENT');
  const protocol = await import(pathToFileURL(path.join(root, 'host-tools/compiler-host-protocol.mjs')).href);
  const contract = await import(pathToFileURL(path.join(root, 'host-tools/contracts/compiler-closure.mjs')).href);
  const helpers = { ...protocol, ...contract };
  tc.verify();
  if (command !== 'selfhost') {
    process.stdout.write(json(await build(tc, helpers, options.project, options.out,
      options.compiler, options.profile || 'ordinary-240s')));
    return;
  }
  const destination = path.resolve(options.out);
  if (exists(destination)) fail('OUTPUT_EXISTS');
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.mkdirSync(destination);
  const first = await build(tc, helpers, options.project, path.join(destination, 'generation-1'),
    options.compiler, options.profile || 'correctness-3600s');
  const second = await build(tc, helpers, options.project, path.join(destination, 'generation-2'),
    first.output, options.profile || 'correctness-3600s');
  if (JSON.stringify(first.identities) !== JSON.stringify(second.identities)) fail('FIXED_POINT_IDENTITY');
  const compared = ['compiler.mjs', 'admissions.json', 'original-ir.json', 'specialized-ir.json', 'sources.json'];
  for (const file of compared)
    if (!regular(path.join(first.output, file)).equals(regular(path.join(second.output, file))))
      fail('FIXED_POINT_BYTES:' + file);
  const receipt = {
    schema: 'psc1-independent-selfhost/1', status: 'passed', generations: [first.output, second.output],
    identities: second.identities, compared, compilerSourceModified: false, formalCompilerPreservation: false,
  };
  writeSynced(path.join(destination, 'selfhost.json'), json(receipt)); syncDirectory(destination);
  process.stdout.write(json(receipt));
}

try { await main(); }
catch (error) {
  process.stderr.write(String(error?.stack || error) + '\n');
  process.exitCode = interrupted === 'SIGINT' ? 130 : interrupted === 'SIGTERM' ? 143 : 1;
}
