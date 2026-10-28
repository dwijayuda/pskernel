// Finite Linux qualification of the installed standalone development cycle.
// Runs inside the bootstrap driver's fresh compiler-free, network-disabled chroot.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const distributionRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const cli = path.join(distributionRoot, 'bin/psc');
const runtime = path.join(distributionRoot, 'libexec/psc-runtime');
const checker = path.join(distributionRoot, 'kernel/checker');
const defaultProject = path.join(distributionRoot, 'compiler/project.json');
const leanCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const ordinaryTimeoutMs = 240000;
const selfhostTimeoutMs = 3600000;
const checkerTimeoutMs = 120000;
const sourceProfile = 'correctness-3600s';
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const utf8 = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
const args = process.argv.slice(2);
function argument(name) {
  const positions = args.flatMap((value, index) => value === name ? [index] : []);
  assert.equal(positions.length, 1, 'exactly one ' + name + ' is required');
  const value = args[positions[0] + 1];
  assert.ok(value && !value.startsWith('--'), 'missing ' + name);
  return value;
}
assert.equal(args.length, 4, 'usage: qualification.mjs --phase smoke|baseline|changed --out DIRECTORY');
const phase = argument('--phase'), output = path.resolve(argument('--out'));
assert.ok(['smoke', 'baseline', 'changed'].includes(phase), 'unknown phase');
assert.ok(path.isAbsolute(argument('--out')), 'output must be absolute');
assert.ok(output !== distributionRoot && !output.startsWith(distributionRoot + path.sep), 'output overlaps installed toolchain');
assert.ok(!fs.existsSync(output), 'qualification output must be new');
fs.mkdirSync(path.join(output, 'logs'), { recursive: true });
const reportPath = path.join(output, 'qualification.json');
const events = [], results = [];
const report = {
  schema: 'psc1-independent-development-qualification/1',
  phase, status: 'running', startedAt: new Date().toISOString(),
  scope: 'finite Linux compiler-development execution, independent logical admission and self-host fixed points; not a compiler semantic-preservation proof',
  resourcePolicy: { ordinaryTimeoutMs, selfhostTimeoutMs, checkerTimeoutMs, sourceProfile },
  events, results
};
function save() {
  const temporary = reportPath + '.tmp';
  fs.writeFileSync(temporary, json(report));
  fs.renameSync(temporary, reportPath);
}
function log(event) {
  events.push(event);
  save();
  console.log('PSC1_INDEPENDENT_QUALIFICATION: ' + JSON.stringify(event));
}
function boundedFile(file, limit = 128 * 1024 * 1024) {
  const stat = fs.lstatSync(file);
  assert.ok(stat.isFile() && !stat.isSymbolicLink() && stat.size > 0 && stat.size <= limit, 'invalid file ' + file);
  return fs.readFileSync(file);
}
const shaEnvironment = sha;
function environmentFacts(directory) {
  const limited = (value, maximum = 512) =>
    typeof value === 'string' ? value.slice(0, maximum) : null;
  const releasePath = '/etc/os-release';
  const releaseFd = fs.openSync(releasePath, 'r');
  let releaseBytes;
  try {
    const releaseStat = fs.fstatSync(releaseFd);
    assert.ok(releaseStat.isFile() && releaseStat.size > 0 && releaseStat.size <= 16384,
      'bounded regular OS release metadata required');
    const buffer = Buffer.alloc(16385);
    const length = fs.readSync(releaseFd, buffer, 0, buffer.length, 0);
    assert.ok(length <= 16384 && length === releaseStat.size, 'OS release metadata changed');
    releaseBytes = buffer.subarray(0, length);
  } finally { fs.closeSync(releaseFd); }
  const header = process.report.getReport().header;
  const filesystem = fs.statfsSync(directory, { bigint: true });
  const versions = Object.fromEntries(Object.entries(process.versions)
    .filter(([name, value]) => /^[A-Za-z0-9_-]{1,64}$/.test(name) && typeof value === 'string')
    .slice(0, 64).map(([name, value]) => [name, limited(value, 128)]));
  return {
    schema: 'psc1-independent-environment/1',
    platform: process.platform, arch: process.arch,
    kernel: { release: limited(os.release()), version: limited(os.version(), 1024) },
    runtime: { version: process.version, versions,
      glibcVersionRuntime: limited(header.glibcVersionRuntime, 128),
      glibcVersionCompiler: limited(header.glibcVersionCompiler, 128) },
    osRelease: { bytes: releaseBytes.length, sha256: shaEnvironment(releaseBytes),
      text: new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(releaseBytes) },
    filesystem: Object.fromEntries(['type', 'bsize', 'blocks', 'bfree', 'bavail', 'files', 'ffree']
      .map(name => [name, String(filesystem[name])])),
    user: { uid: process.getuid(), gid: process.getgid() }
  };
}
function confined(root, relative) {
  assert.equal(typeof relative, 'string');
  assert.ok(relative && !path.isAbsolute(relative) && !relative.split(/[\\/]/).includes('..'), 'escaping path');
  const resolved = path.resolve(root, relative);
  assert.ok(resolved.startsWith(root + path.sep), 'path outside root');
  for (let current = resolved; current !== root; current = path.dirname(current)) {
    assert.ok(!fs.lstatSync(current).isSymbolicLink(), 'symlink in path');
  }
  return resolved;
}
const manifestBytes = boundedFile(path.join(distributionRoot, 'toolchain.json'), 1024 * 1024);
const manifest = JSON.parse(utf8(manifestBytes));
assert.equal(path.resolve(process.execPath), runtime, 'qualification must use the private runtime');
function installedResources() {
  assert.ok(Array.isArray(manifest.resources) && manifest.resources.length > 0, 'missing distribution resource pins');
  const pins = [];
  const seen = new Set();
  for (const record of manifest.resources) {
    assert.ok(record && typeof record.path === 'string' && !seen.has(record.path), 'invalid or duplicate resource');
    seen.add(record.path);
    const bytes = boundedFile(confined(distributionRoot, record.path));
    assert.match(record.sha256, /^[a-f0-9]{64}$/);
    assert.equal(sha(bytes), record.sha256, 'installed resource hash ' + record.path);
    if (record.bytes !== undefined) assert.equal(bytes.length, record.bytes, 'installed resource length');
    pins.push({ path: record.path, bytes: bytes.length, sha256: sha(bytes) });
  }
  assert.equal(sha(boundedFile(path.join(distributionRoot, 'toolchain.json'), 1024 * 1024)), sha(manifestBytes), 'distribution manifest changed');
  return pins;
}
const initialResources = installedResources();
const checkerSha256 = sha(boundedFile(checker));
report.distribution = {
  manifestSha256: sha(manifestBytes),
  sourceCommit: manifest.sourceCommit ?? null,
  resources: initialResources,
  runtimeSha256: sha(boundedFile(runtime)),
  checkerSha256,
  leanCommit
};
const forbidden = ['lean', 'lake', 'node', 'npm', 'npx', 'bun', 'tsc', 'rustc', 'cargo', 'rustup',
  'gcc', 'clang', 'cc', 'c++', 'g++', 'clang++', 'as', 'ld', 'python', 'python3', 'git',
  'go', 'javac', 'java', 'deno', 'wasmtime', 'wasmer', 'wat2wasm', 'wasm-opt'];
const searchDirectories = [...new Set([...String(process.env.PATH || '').split(path.delimiter).filter(Boolean),
  '/bin', '/usr/bin', '/usr/local/bin'])];
const foundForbidden = [];
for (const directory of searchDirectories) for (const tool of forbidden) {
  const file = path.join(directory, tool);
  try {
    fs.accessSync(file, fs.constants.X_OK);
    foundForbidden.push(file);
  } catch (error) {
    if (!['ENOENT', 'ENOTDIR', 'EACCES'].includes(error.code)) throw error;
  }
}
assert.deepEqual(foundForbidden, [], 'external language toolchain found');
report.environment = {
  platform: process.platform, arch: process.arch, runtimeVersion: process.version,
  details: environmentFacts(output),
  runtimePath: process.execPath, path: process.env.PATH ?? '',
  forbiddenNames: forbidden, searchedDirectories: searchDirectories,
  externalToolchainsAbsent: true,
  isolation: 'caller-provided fresh chroot and network namespace; see bootstrap isolation receipt and execve trace'
};
const childEnv = { ...process.env };
for (const key of Object.keys(childEnv)) {
  if (key === 'NODE_OPTIONS' || key === 'NODE_PATH' || key === 'LD_PRELOAD' ||
      key === 'LD_LIBRARY_PATH' || key.startsWith('DYLD_') ||
      key.startsWith('PSC_') || key.startsWith('PSC1_') ||
      key.startsWith('LEAN') || key.startsWith('ELAN') || key.startsWith('RUST') ||
      key.startsWith('CARGO') || key.startsWith('BUN_')) delete childEnv[key];
}
let serial = 0;
function run(label, executable, commandArgs, options = {}) {
  assert.match(label, /^[a-z][a-z0-9-]*$/);
  const id = String(++serial).padStart(3, '0') + '-' + label;
  const started = Date.now();
  log({ type: 'process-start', id, executable, args: commandArgs });
  const result = spawnSync(executable, commandArgs, {
    cwd: output, env: childEnv, encoding: 'utf8',
    timeout: options.timeoutMs ?? ordinaryTimeoutMs + checkerTimeoutMs + 30000,
    maxBuffer: 32 * 1024 * 1024, killSignal: 'SIGKILL',
    ...(options.input === undefined ? {} : { input: options.input })
  });
  const stdout = result.stdout ?? '', stderr = result.stderr ?? '';
  fs.writeFileSync(path.join(output, 'logs', id + '.stdout.txt'), stdout);
  fs.writeFileSync(path.join(output, 'logs', id + '.stderr.txt'), stderr);
  const record = {
    type: 'process-complete', id, executable, args: commandArgs,
    status: result.status, signal: result.signal,
    elapsedMs: Date.now() - started,
    stdoutSha256: sha(stdout), stderrSha256: sha(stderr),
    error: result.error?.message ?? null
  };
  log(record);
  assert.equal(result.error, undefined, label + ': ' + String(result.error));
  if (options.expectedFailure) assert.notEqual(result.status, 0, label + ' unexpectedly succeeded');
  else assert.equal(result.status, 0, label + ': ' + (stderr || stdout).slice(-16000));
  return { stdout, stderr, record };
}
function psc(label, commandArgs, options = {}) {
  return run(label, cli, commandArgs, options);
}
function parseStdout(result) {
  return JSON.parse(result.stdout.trim());
}
function sourceSnapshot(projectFile) {
  const projectBytes = boundedFile(projectFile, 4 * 1024 * 1024);
  const project = JSON.parse(utf8(projectBytes));
  assert.equal(project.schemaVersion, 1);
  assert.deepEqual(Object.keys(project).sort(), ['entryModule', 'schemaVersion', 'sources']);
  assert.ok(Array.isArray(project.sources) && project.sources.length > 0);
  const names = new Set(), rows = [];
  for (const item of project.sources) {
    assert.deepEqual(Object.keys(item).sort(), ['module', 'path']);
    assert.ok(typeof item.module === 'string' && item.module && !names.has(item.module), 'source module');
    names.add(item.module);
    assert.ok(item.path.endsWith('.ps'), 'maintained source must be ProofScript');
    const bytes = boundedFile(confined(path.dirname(projectFile), item.path));
    const text = utf8(bytes);
    assert.equal(Buffer.byteLength(text), bytes.length, 'exact UTF-8 capture');
    rows.push({ module: item.module, kind: 'ps', text, path: item.path, bytes: bytes.length, sha256: sha(bytes) });
  }
  assert.ok(names.has(project.entryModule), 'entry module is absent');
  const sourceClosureDigest = sha(JSON.stringify(rows.map(row => ({
    module: row.module, kind: row.kind, utf8Sha256: row.sha256
  }))));
  return { project, rows, projectSha256: sha(projectBytes), sourceClosureDigest };
}
function summarizedSources(snapshot) {
  return {
    projectSha256: snapshot.projectSha256,
    sourceClosureDigest: snapshot.sourceClosureDigest,
    entryModule: snapshot.project.entryModule,
    moduleCount: snapshot.rows.length,
    utf8Bytes: snapshot.rows.reduce((sum, row) => sum + row.bytes, 0),
    files: snapshot.rows.map(({ module, path: file, bytes, sha256 }) => ({ module, path: file, bytes, sha256 }))
  };
}
function writeProject(directory, sourceText, module = 'Main') {
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, module + '.ps'), sourceText);
  const projectFile = path.join(directory, 'project.json');
  fs.writeFileSync(projectFile, json({
    schemaVersion: 1, entryModule: module, sources: [{ module, path: module + '.ps' }]
  }));
  return projectFile;
}
const canonicalFiles = ['compiler.mjs', 'admissions.json', 'original-ir.json', 'specialized-ir.json', 'sources.json'];
function readBuild(directory, expectedSnapshot) {
  const receipt = JSON.parse(utf8(boundedFile(path.join(directory, 'build.json'), 4 * 1024 * 1024)));
  assert.equal(receipt.schema, 'psc1-independent-build/1');
  assert.equal(receipt.sourceModules, expectedSnapshot.rows.length);
  assert.equal(receipt.identities.sourceClosureDigest, expectedSnapshot.sourceClosureDigest);
  assert.equal(receipt.checker.executed, true, 'a build must perform independent checking');
  assert.equal(receipt.checker.accepted, true, 'kernel did not accept this build');
  assert.equal(receipt.checker.sha256, checkerSha256);
  assert.equal(receipt.checker.leanCommit, leanCommit);
  assert.equal(receipt.checker.admissionsSha256, receipt.identities.admissionsSha256);
  assert.ok(Number.isFinite(receipt.checker.elapsedMs) && receipt.checker.elapsedMs >= 0);
  assert.match(receipt.checker.admissionReceiptSha256, /^[a-f0-9]{64}$/);
  const candidate = JSON.parse(utf8(boundedFile(path.join(directory, 'candidate.json'))));
  assert.equal(candidate.status, 'candidate');
  assert.equal(candidate.candidateOnly, true);
  assert.equal(candidate.admission, 'not-run', 'candidate cannot assert independent admission');
  assert.equal(candidate.sourceClosureDigest, expectedSnapshot.sourceClosureDigest);
  const identities = {
    sourceClosureDigest: expectedSnapshot.sourceClosureDigest,
    sourceSha256: sha(candidate.source),
    admissionsSha256: sha(candidate.admissionRequest.admissions),
    originalIrSha256: sha(JSON.stringify(candidate.originalIr)),
    specializedIrSha256: sha(JSON.stringify(candidate.specializedIr))
  };
  for (const [key, value] of Object.entries(identities)) assert.equal(receipt.identities[key], value, 'build identity ' + key);
  assert.equal(utf8(boundedFile(path.join(directory, 'compiler.mjs'))), candidate.source);
  assert.deepEqual(JSON.parse(utf8(boundedFile(path.join(directory, 'admissions.json')))),
    JSON.parse(candidate.admissionRequest.admissions));
  assert.deepEqual(JSON.parse(utf8(boundedFile(path.join(directory, 'original-ir.json')))), candidate.originalIr);
  assert.deepEqual(JSON.parse(utf8(boundedFile(path.join(directory, 'specialized-ir.json')))), candidate.specializedIr);
  const files = canonicalFiles.map(file => {
    const bytes = boundedFile(path.join(directory, file));
    return { path: file, bytes: bytes.length, sha256: sha(bytes) };
  });
  return {
    directory, identities, files, checker: receipt.checker,
    execution: receipt.execution, publicNames: receipt.publicNames,
    buildReceiptSha256: sha(boundedFile(path.join(directory, 'build.json'))),
    candidateSha256: sha(boundedFile(path.join(directory, 'candidate.json')))
  };
}
function build(label, projectFile, directory, compilerDirectory, fullCompiler = true) {
  const before = sourceSnapshot(projectFile);
  const commandArgs = ['build', projectFile, '--out', directory];
  if (compilerDirectory) commandArgs.push('--compiler', compilerDirectory);
  if (fullCompiler) commandArgs.push('--profile', sourceProfile);
  const processResult = psc(label, commandArgs, {
    timeoutMs: (fullCompiler ? selfhostTimeoutMs : ordinaryTimeoutMs) + checkerTimeoutMs + 60000
  });
  const after = sourceSnapshot(projectFile);
  assert.deepEqual(summarizedSources(after), summarizedSources(before), 'source changed during build');
  const record = readBuild(directory, before);
  record.processElapsedMs = processResult.record.elapsedMs;
  record.processLog = processResult.record.id;
  results.push({ type: 'independently-checked-build', label, ...record });
  save();
  return record;
}
function diagnostic(label, compilerDirectory) {
  const commandArgs = ['diagnostic'];
  if (compilerDirectory) commandArgs.push('--compiler', compilerDirectory);
  const response = parseStdout(psc(label, commandArgs));
  assert.equal(response.status, 'refused');
  assert.equal(response.phase, 'wire');
  assert.equal(response.admission, 'not-run');
  assert.equal(response.candidateOnly, true);
  return response;
}
function fixedPoint(label, first, second) {
  assert.deepEqual(second.identities, first.identities, label + ' semantic artifact identities differ');
  assert.deepEqual(second.files, first.files, label + ' canonical artifact bytes differ');
  results.push({
    type: 'fixed-point', label, status: 'passed',
    generations: [path.basename(first.directory), path.basename(second.directory)],
    sourceClosureDigest: first.identities.sourceClosureDigest,
    files: first.files,
    assurance: 'exact finite same-source admissions, IR and compiler artifact equality; not semantic-preservation proof'
  });
  save();
}
function notPublished(directory) {
  assert.equal(fs.existsSync(path.join(directory, 'build.json')), false, 'refused attempt published a build');
  assert.equal(fs.existsSync(path.join(directory, 'files.json')), false, 'refused attempt sealed a generation');
}
function checkerProbe(label, accepted) {
  const name = value => ({ k: 's', p: { k: 'a' }, v: value });
  const graph = {
    protocol: 'pskernel-lean/1', format: 'proofscript-checked-admissions', version: 2,
    admissions: [{
      kind: 'constant',
      declaration: {
        k: 'definition', h: { k: 'regular', h: '1' }, lp: [],
        n: name(accepted ? 'Standalone.Valid' : 'Standalone.Invalid'), s: 'safe',
        t: { k: 'const', n: name('Nat'), ls: [] },
        v: accepted ? { k: 'nat', v: '1' } : { k: 'sort', l: { k: 'z' } }
      }
    }]
  };
  const input = JSON.stringify(graph);
  const response = parseStdout(run(label, checker, ['--check'], { input, timeoutMs: checkerTimeoutMs }));
  for (const [key, value] of Object.entries({
    protocol: 'pskernel-lean/1', provider: 'lean4-cpp', leanVersion: '4.35.0',
    leanCommit, profile: 'lean4.35-core', accepted
  })) assert.equal(response[key], value, 'checker probe ' + key);
  if (!accepted) assert.equal(response.errorKind, 'kernel-rejection', 'negative must reach semantic checking');
  return { accepted, admissionsSha256: sha(input), responseSha256: sha(JSON.stringify(response)), response };
}
function copyWritable(source, destination) {
  const stat = fs.lstatSync(source);
  assert.ok(!stat.isSymbolicLink(), 'copy refuses symbolic links');
  if (stat.isDirectory()) {
    fs.mkdirSync(destination, { mode: 0o755 });
    for (const name of fs.readdirSync(source)) copyWritable(path.join(source, name), path.join(destination, name));
  } else {
    assert.ok(stat.isFile(), 'copy requires regular files');
    fs.copyFileSync(source, destination);
    fs.chmodSync(destination, (stat.mode & 0o777) | 0o200);
  }
}

function smoke() {
  const initialDiagnostic = diagnostic('seed-diagnostic');
  assert.equal(initialDiagnostic.code, 'request-arity');
  const project = writeProject(path.join(output, 'smoke-source'), 'const answer : Nat := 42\n');
  const generatedDirectory = path.join(output, 'smoke-build');
  const compiled = build('small-checked-build', project, generatedDirectory, undefined, false);
  assert.ok(compiled.publicNames.includes('answer'), 'small source body was not emitted');
  const observationProgram = [
    "import {pathToFileURL} from 'node:url';",
    'const module = await import(pathToFileURL(' + JSON.stringify(path.join(generatedDirectory, 'compiler.mjs')) + ').href);',
    "const answer = typeof module.answer === 'function' ? module.answer() : module.answer;",
    "if (String(answer) !== '42') throw new Error('compiled application returned the wrong result');",
    "console.log(JSON.stringify({answer:String(answer)}));"
  ].join('\n');
  const observation = parseStdout(run('execute-compiled-application', runtime, ['--input-type=module', '--eval', observationProgram]));
  assert.equal(observation.answer, '42');
  results.push({ type: 'compiled-application-execution', observation, sourceClosureDigest: compiled.identities.sourceClosureDigest });
  const positive = checkerProbe('kernel-positive', true), negative = checkerProbe('kernel-illtyped-negative', false);
  results.push({ type: 'independent-checker-positive-and-negative', positive, negative });
  save();

  const invalidProject = writeProject(path.join(output, 'invalid-source'), 'const broken : Nat := true\n');
  const rejectedDirectory = path.join(output, 'invalid-build');
  const sourceRefusal = psc('invalid-source-refused', ['build', invalidProject, '--out', rejectedDirectory], { expectedFailure: true });
  assert.match(sourceRefusal.stderr, /PSC1_INDEPENDENT_COMPILER_REFUSED/);
  notPublished(rejectedDirectory);

  const acceptedFilesBefore = readBuild(generatedDirectory, sourceSnapshot(project));
  const overwriteRefusal = psc('existing-generation-preserved', ['build', project, '--out', generatedDirectory], { expectedFailure: true });
  assert.match(overwriteRefusal.stderr, /PSC1_INDEPENDENT_OUTPUT_EXISTS/);
  const acceptedFilesAfter = readBuild(generatedDirectory, sourceSnapshot(project));
  assert.deepEqual(acceptedFilesAfter, acceptedFilesBefore, 'refused overwrite changed an accepted generation');

  const readOnlyParent = path.join(output, 'read-only-output-parent');
  const readOnlyOutput = path.join(readOnlyParent, 'unpublished');
  fs.mkdirSync(readOnlyParent, { mode: 0o755 });
  fs.chmodSync(readOnlyParent, 0o555);
  try {
    assert.notEqual(process.getuid(), 0, 'read-only-parent refusal requires an ordinary user');
    const readOnlyRefusal = psc('read-only-parent-refused', ['build', project, '--out', readOnlyOutput], { expectedFailure: true });
    assert.match(readOnlyRefusal.stderr, /\b(?:EACCES|EPERM)\b/, 'expected an operating-system permission refusal');
    notPublished(readOnlyOutput);
    assert.deepEqual(readBuild(generatedDirectory, sourceSnapshot(project)), acceptedFilesBefore,
      'read-only-parent refusal changed an accepted generation');
    results.push({
      type: 'publication-read-only-parent', status: 'passed',
      output: readOnlyOutput, processLog: readOnlyRefusal.record.id,
      acceptedBuildReceiptSha256: acceptedFilesBefore.buildReceiptSha256,
      acceptedPayloadsSha256: sha(JSON.stringify(acceptedFilesBefore.files))
    });
    save();
  } finally { fs.chmodSync(readOnlyParent, 0o755); }


  const incomplete = path.join(output, 'incomplete-generation');
  fs.mkdirSync(incomplete);
  fs.copyFileSync(path.join(distributionRoot, 'engine/compiler.mjs'), path.join(incomplete, 'compiler.mjs'));
  const incompleteOutput = path.join(output, 'incomplete-build');
  const incompleteRefusal = psc('incomplete-generation-refused', ['build', project, '--compiler', incomplete, '--out', incompleteOutput], { expectedFailure: true });
  assert.match(incompleteRefusal.stderr, /PSC1_INDEPENDENT_ARTIFACT_(FILE|CHANGED)/);
  notPublished(incompleteOutput);

  const copyRoot = path.join(output, 'relocated toolchain with spaces');
  copyWritable(distributionRoot, copyRoot);
  const copyCli = path.join(copyRoot, 'bin/psc');
  const copiedDiagnostic = parseStdout(run('relocated-toolchain-diagnostic', copyCli, ['diagnostic']));
  assert.equal(copiedDiagnostic.code, initialDiagnostic.code, 'relocated copy must work before tamper tests');
  const relocatedDirectory = path.join(output, 'relocated checked output');
  const relocatedProcess = run('relocated-small-checked-build', copyCli,
    ['build', project, '--out', relocatedDirectory]);
  const relocated = readBuild(relocatedDirectory, sourceSnapshot(project));
  relocated.processElapsedMs = relocatedProcess.record.elapsedMs;
  relocated.processLog = relocatedProcess.record.id;
  results.push({ type: 'independently-checked-build', label: 'relocated-small-checked-build', ...relocated });
  const relocatedExecution = observeApplication('relocated-application-execute', relocatedDirectory);
  results.push({
    type: 'relocated-checked-publication', status: 'passed',
    buildLabel: 'relocated-small-checked-build',
    buildReceiptSha256: relocated.buildReceiptSha256,
    completionManifestSha256: sha(boundedFile(path.join(relocatedDirectory, 'files.json'))),
    ...relocatedExecution
  });
  save();

  const copiedEngine = path.join(copyRoot, 'engine/compiler.mjs');
  fs.chmodSync(copiedEngine, 0o644);
  const engineBytes = boundedFile(copiedEngine);
  fs.appendFileSync(copiedEngine, '\n// Deliberate integrity-test mutation.\n');
  const engineRefusal = run('tampered-engine-refused', copyCli, ['diagnostic'], { expectedFailure: true });
  assert.match(engineRefusal.stderr, /PSC1_INDEPENDENT_RESOURCE_CHANGED/);
  fs.writeFileSync(copiedEngine, engineBytes);
  assert.equal(sha(boundedFile(copiedEngine)), sha(engineBytes));
  const restoredDiagnostic = parseStdout(run('restored-engine-diagnostic', copyCli, ['diagnostic']));
  assert.equal(restoredDiagnostic.code, initialDiagnostic.code, 'restored engine must execute');
  const copiedChecker = path.join(copyRoot, 'kernel/checker');
  fs.chmodSync(copiedChecker, 0o755);
  fs.appendFileSync(copiedChecker, Buffer.from('\nPSC1_INTEGRITY_TEST\n'));
  const tamperedOutput = path.join(output, 'tampered-checker-build');
  const checkerRefusal = run('tampered-checker-refused', copyCli, ['build', project, '--out', tamperedOutput], { expectedFailure: true });
  assert.match(checkerRefusal.stderr, /PSC1_INDEPENDENT_RESOURCE_CHANGED/);
  notPublished(tamperedOutput);
  fs.rmSync(copyRoot, { recursive: true });
  results.push({
    type: 'host-refusals', status: 'passed',
    cases: ['invalid-source', 'existing-generation', 'read-only-parent', 'incomplete-generation', 'tampered-engine', 'tampered-checker'],
    refusedOutputsUnpublished: true
  });
  save();
}
function baseline() {
  const initialDiagnostic = diagnostic('seed-diagnostic');
  assert.equal(initialDiagnostic.code, 'request-arity');
  const first = build('baseline-generation-one', defaultProject, path.join(output, 'B1'));
  const converted = JSON.parse(utf8(boundedFile(path.join(distributionRoot, 'metadata/SOURCE_MANIFEST.json'))));
  assert.equal(first.identities.admissionsSha256, converted.admissionsSha256,
    'generated compiler admissions must match the independently checked current canonical source analysis');
  results.push({ type: 'bootstrap-admission-correspondence', status: 'passed',
    admissionsSha256: first.identities.admissionsSha256,
    nativeOriginalIrSha256: converted.originalIrSha256,
    generatedOriginalIrSha256: first.identities.originalIrSha256,
    originalIrBytesEqual: first.identities.originalIrSha256 === converted.originalIrSha256 });
  save();
  const second = build('baseline-generation-two', defaultProject, path.join(output, 'B2'), first.directory);
  const firstDiagnostic = diagnostic('baseline-one-diagnostic', first.directory);
  const secondDiagnostic = diagnostic('baseline-two-diagnostic', second.directory);
  assert.equal(firstDiagnostic.code, initialDiagnostic.code);
  assert.equal(secondDiagnostic.code, initialDiagnostic.code);
  fixedPoint('unmodified-compiler', first, second);
}
function applicationObservationProgram(directory) {
  return [
    "import {pathToFileURL} from 'node:url';",
    'const module = await import(pathToFileURL(' + JSON.stringify(path.join(directory, 'compiler.mjs')) + ').href);',
    "const answer = typeof module.answer === 'function' ? module.answer() : module.answer;",
    "if (String(answer) !== '42') throw new Error('compiled application returned the wrong result');",
    "console.log(JSON.stringify({answer:String(answer)}));"
  ].join('\n');
}
function observeApplication(label, directory) {
  const executed = run(label, runtime, ['--input-type=module', '--eval', applicationObservationProgram(directory)]);
  const observation = parseStdout(executed);
  assert.deepEqual(observation, { answer: '42' });
  return { observation, processLog: executed.record.id };
}
function compilerSourcePatch(projectFile, moduleName, replacements) {
  const project = JSON.parse(utf8(boundedFile(projectFile)));
  const matches = project.sources.filter(item => item.module === moduleName);
  assert.equal(matches.length, 1, 'exactly one owned source required: ' + moduleName);
  const entry = matches[0], sourceFile = confined(path.dirname(projectFile), entry.path);
  const beforeBytes = boundedFile(sourceFile);
  let text = utf8(beforeBytes);
  for (const { previous, replacement } of replacements) {
    assert.equal(text.split(previous).length - 1, 1, 'mutation anchor must occur once in ' + moduleName + ': ' + previous);
    text = text.replace(previous, replacement);
  }
  fs.chmodSync(sourceFile, 0o644);
  fs.writeFileSync(sourceFile, text);
  return {
    module: moduleName, path: entry.path,
    beforeSourceSha256: sha(beforeBytes), afterSourceSha256: sha(boundedFile(sourceFile)),
    edits: replacements
  };
}
function regressionRefusal(label, sourceText, compilerDirectory, expectedPhase, expectedCode) {
  const project = writeProject(path.join(output, 'regression-fixtures', label), sourceText);
  const directory = path.join(output, 'regression-builds', label);
  const commandArgs = ['build', project, '--out', directory];
  if (compilerDirectory) commandArgs.push('--compiler', compilerDirectory);
  const rejected = psc(label, commandArgs, { expectedFailure: true });
  const marker = 'PSC1_INDEPENDENT_COMPILER_REFUSED:';
  const offset = rejected.stderr.indexOf(marker);
  assert.ok(offset >= 0, 'expected structured compiler refusal: ' + label);
  const response = JSON.parse(rejected.stderr.slice(offset + marker.length).split('\n')[0]);
  const snapshot = sourceSnapshot(project);
  for (const [key, value] of Object.entries({
    status: 'refused', phase: expectedPhase, code: expectedCode, module: 'Main',
    target: 'js', admission: 'not-run', candidateOnly: true,
    sourceClosureDigest: snapshot.sourceClosureDigest,
    requestId: 'psc1-independent-' + snapshot.sourceClosureDigest.slice(0, 24)
  })) assert.equal(response[key], value, 'refusal field ' + key + ': ' + label);
  notPublished(directory);
  return { label, outcome: 'refused', sourceClosureDigest: snapshot.sourceClosureDigest,
    response, processLog: rejected.record.id };
}
function regressionApplication(label, sourceText, compilerDirectory) {
  const project = writeProject(path.join(output, 'regression-fixtures', label), sourceText);
  const directory = path.join(output, 'regression-builds', label);
  const compiled = build(label, project, directory, compilerDirectory, false);
  assert.ok(compiled.publicNames.includes('answer'), 'application export missing: ' + label);
  const executed = observeApplication(label + '-execute', directory);
  return {
    label, buildLabel: label, outcome: 'accepted-and-executed', ...executed,
    sourceClosureDigest: compiled.identities.sourceClosureDigest,
    admissionsSha256: compiled.identities.admissionsSha256,
    compilerSha256: compiled.identities.sourceSha256,
    buildReceiptSha256: compiled.buildReceiptSha256, checker: compiled.checker
  };
}
function frontendCompilerRegressions(generation, compilerDirectory, aliasSupported) {
  const prefix = generation.toLowerCase() + '-';
  const parseCode = aliasSupported ? 'parse-source-refused' : 'source-refused';
  const observations = [];
  const accepted = (name, sourceText) =>
    observations.push({ case: name, ...regressionApplication(prefix + name, sourceText, compilerDirectory) });
  const refused = (name, sourceText, expectedPhase = 'parse', expectedCode = parseCode) =>
    observations.push({ case: name, ...regressionRefusal(prefix + name, sourceText, compilerDirectory, expectedPhase, expectedCode) });
  accepted('existing-const', 'const answer : Nat := 42\n');
  const addition = 'function inc(value : Nat) : Nat := Nat.add(value, 1)\n' +
    'defconst answer : Nat := inc(41)\n';
  if (aliasSupported) accepted('new-declaration', addition);
  else refused('new-declaration', addition);
  refused('existing-malformed', 'const broken : Nat :=\n');
  refused('new-missing-type', 'defconst broken := 42\n');
  refused('new-parameters-forbidden', 'defconst broken(value : Nat) : Nat := value\n');
  refused('new-illtyped', 'defconst broken : Nat := true\n',
    aliasSupported ? 'elaboration' : 'parse', aliasSupported ? 'source-refused' : parseCode);
  assert.equal(observations.length, 6);
  results.push({
    type: 'frontend-compiler-regressions', generation, aliasSupported,
    grammarExperiment: 'test-only defconst alias in copied compiler sources; installed grammar is unchanged',
    observations
  });
  save();
}
function changed() {
  const original = sourceSnapshot(defaultProject);
  const seedDiagnostic = diagnostic('seed-before-change');
  assert.equal(seedDiagnostic.code, 'request-arity');
  frontendCompilerRegressions('seed', undefined, false);
  const changedRoot = path.join(output, 'changed-compiler-source');
  copyWritable(path.dirname(defaultProject), changedRoot);
  const projectFile = path.join(changedRoot, 'project.json');
  const changes = [
    compilerSourcePatch(projectFile, 'Ps.CompilerUnified.Service', [
      { previous: '"request-arity"', replacement: '"request-arity:expected-three-fields"' }
    ]),
    compilerSourcePatch(projectFile, 'Ps.Syntax.ParseProofScript', [
      { previous: 'psStringEq(keyword.text, "const")',
        replacement: 'psProofScriptBoolOr(psStringEq(keyword.text, "const"), psStringEq(keyword.text, "defconst"))' },
      { previous: 'psStringEq(text, "const")',
        replacement: 'psProofScriptBoolOr(psStringEq(text, "const"), psStringEq(text, "defconst"))' }
    ]),
    compilerSourcePatch(projectFile, 'Ps.Compiler.Service', [
      { previous: '"parse", "source-refused"', replacement: '"parse", "parse-source-refused"' }
    ])
  ];
  const modified = sourceSnapshot(projectFile);
  assert.equal(modified.rows.length, original.rows.length, 'compiler closure size changed');
  const changedRows = modified.rows.filter((row, index) => {
    assert.equal(row.module, original.rows[index].module, 'source module order changed');
    assert.equal(row.path, original.rows[index].path, 'source ownership path changed');
    return row.sha256 !== original.rows[index].sha256;
  });
  assert.deepEqual(changedRows.map(row => row.module).sort(), [
    'Ps.Compiler.Service', 'Ps.CompilerUnified.Service', 'Ps.Syntax.ParseProofScript'
  ]);
  assert.notEqual(modified.sourceClosureDigest, original.sourceClosureDigest);
  const wireChange = changes[0];
  const mutation = {
    type: 'real-compiler-source-modification', module: wireChange.module, path: wireChange.path,
    previous: 'request-arity', replacement: 'request-arity:expected-three-fields',
    beforeSourceSha256: wireChange.beforeSourceSha256, afterSourceSha256: wireChange.afterSourceSha256,
    originalSourceClosureDigest: original.sourceClosureDigest,
    changedSourceClosureDigest: modified.sourceClosureDigest,
    changedFileCount: changes.length, retainedModuleCount: modified.rows.length, changes
  };
  results.push(mutation);
  report.changedSource = summarizedSources(modified);
  save();
  const first = build('changed-generation-one', projectFile, path.join(output, 'C1'));
  const firstDiagnostic = diagnostic('changed-one-diagnostic', first.directory);
  assert.equal(firstDiagnostic.code, mutation.replacement, 'rebuilt compiler did not exercise changed source');
  assert.notEqual(firstDiagnostic.code, seedDiagnostic.code);
  results.push({ type: 'changed-behavior', generation: 'C1', seed: seedDiagnostic, actual: firstDiagnostic });
  save();
  frontendCompilerRegressions('C1', first.directory, true);
  const second = build('changed-generation-two', projectFile, path.join(output, 'C2'), first.directory);
  const secondDiagnostic = diagnostic('changed-two-diagnostic', second.directory);
  assert.equal(secondDiagnostic.code, mutation.replacement, 'self-rebuilt compiler lost its change');
  fixedPoint('modified-compiler', first, second);
  results.push({ type: 'changed-behavior', generation: 'C2', actual: secondDiagnostic });
  frontendCompilerRegressions('C2', second.directory, true);
  assert.deepEqual(summarizedSources(sourceSnapshot(defaultProject)), summarizedSources(original), 'installed source changed');
  save();
}

try {
  save();
  report.identity = parseStdout(psc('identity', ['identity']));
  report.authoritativeSource = summarizedSources(sourceSnapshot(defaultProject));
  if (phase === 'smoke') smoke();
  else if (phase === 'baseline') baseline();
  else changed();
  assert.deepEqual(installedResources(), initialResources, 'installed distribution changed');
  report.status = 'passed';
  report.finishedAt = new Date().toISOString();
  report.elapsedMs = Date.parse(report.finishedAt) - Date.parse(report.startedAt);
  save();
  console.log('PSC1_INDEPENDENT_QUALIFICATION_RESULT: ' + JSON.stringify({
    phase, status: report.status, report: reportPath,
    reportSha256: sha(fs.readFileSync(reportPath)), elapsedMs: report.elapsedMs
  }));
} catch (error) {
  report.status = 'failed';
  report.finishedAt = new Date().toISOString();
  report.elapsedMs = Date.parse(report.finishedAt) - Date.parse(report.startedAt);
  report.failure = { message: error.message, stack: error.stack };
  try { save(); } catch (saveError) { console.error('Could not retain failure receipt: ' + saveError.message); }
  console.error('PSC1_INDEPENDENT_QUALIFICATION_FAILED: ' + error.stack);
  process.exitCode = 1;
}
