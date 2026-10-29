// Deliver only the exact tested root; no package rebuild or registry publication.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { readQualifiedArtifact, sha256 } from '../../psc1/scripts/kernel435-qualified-artifact.mjs';

const repository = 'dwijayuda/pskernel', head = process.env.GITHUB_SHA;
assert.equal(process.env.GITHUB_REPOSITORY, repository);
assert.match(head, /^[0-9a-f]{40}$/);
const runId = Number(process.env.GITHUB_RUN_ID);
assert.ok(Number.isSafeInteger(runId) && runId > 0);
async function api(route, json = true) {
  const response = await fetch('https://api.github.com/repos/' + repository + route, {
    headers: { Authorization: 'Bearer ' + process.env.GH_TOKEN,
      Accept: 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28' },
    signal: AbortSignal.timeout(120000),
  });
  assert.equal(response.status, 200, route);
  const text = await response.text();
  assert.ok(Buffer.byteLength(text) <= 33554432);
  return json ? JSON.parse(text) : text;
}
const jobs = await api('/actions/runs/' + runId + '/jobs?per_page=100');
const required = ['package', 'qualify (node)', 'qualify (bun)', 'boundaries (node)',
  'boundaries (bun)', 'applications (node)', 'applications (bun)',
  'compatibility (24)', 'compatibility (26)'];
assert.ok(jobs.total_count <= 100);
for (const name of required) assert.equal(jobs.jobs.find(job => job.name === name)?.conclusion, 'success', name);

// Wait for the separate required PR source gate; never ship on a failed/pending gate.
let sourceRun;
const deadline = Date.now() + 2700000;
for (;;) {
  const runs = await api('/actions/runs?head_sha=' + head + '&event=pull_request&per_page=100');
  sourceRun = runs.workflow_runs.filter(run => run.path === '.github/workflows/psc1-development.yml')
    .sort((a, b) => b.id - a.id)[0];
  if (sourceRun?.status === 'completed') {
    assert.equal(sourceRun.head_sha, head);
    assert.equal(sourceRun.conclusion, 'success', 'PSC1_DELIVERY_SOURCE_GATE');
    break;
  }
  assert.ok(Date.now() < deadline, 'PSC1_DELIVERY_SOURCE_GATE_WAIT_EXHAUSTED');
  console.log('PSC1_DELIVERY_WAIT_SOURCE ' + JSON.stringify({head, status: sourceRun?.status || 'not-created'}));
  await new Promise(resolve => setTimeout(resolve, 30000));
}
const sourceJobs = await api('/actions/runs/' + sourceRun.id + '/jobs?per_page=100');
assert.ok(sourceJobs.total_count <= 100);
assert.ok(sourceJobs.jobs.every(job => ['success', 'skipped'].includes(job.conclusion)));
const full = sourceJobs.jobs.find(job => job.name === 'full / linux-scoped');
assert.equal(full?.conclusion, 'success');
const fullLog = await api('/actions/jobs/' + full.id + '/logs', false);
const parse = (text, marker) => {
  const rows = text.split('\n').filter(line => line.includes(marker));
  assert.equal(rows.length, 1, marker);
  return JSON.parse(rows[0].slice(rows[0].indexOf(marker) + marker.length));
};
const readiness = parse(fullLog, 'PSC1_PRACTICAL_CORE_READINESS: ');
const source = parse(fullLog, 'PSC1_SEVEN_BACKEND_QUALIFICATION: ');
assert.equal(source.branchHeadCommit, head);
assert.equal(source.qualification, 'passed-scoped-execution');
assert.deepEqual(readiness.counts, {implemented: 0, tested: 0, qualified: 37, blocked: 0});
assert.equal(readiness.releaseReady, true); // Finite Practical Core contract only.

const out = path.resolve('dist/selfhosted-delivery');
fs.mkdirSync(out, {recursive: true});
const artifacts = await api('/actions/runs/' + runId + '/artifacts?per_page=100');
assert.ok(artifacts.total_count <= 100);
function pin(name, jobName) {
  const found = artifacts.artifacts.filter(row => row.name === name && !row.expired);
  assert.equal(found.length, 1, name);
  const artifact = found[0], job = jobs.jobs.find(row => row.name === jobName);
  assert.equal(job?.conclusion, 'success');
  assert.match(artifact.digest, /^sha256:[0-9a-f]{64}$/);
  return {run: runId, job: job.id, artifact: artifact.id, commit: head, zipSha256: artifact.digest.slice(7)};
}
async function read(name, jobName, destination) {
  const descriptor = pin(name, jobName);
  return {root: await readQualifiedArtifact(descriptor, path.join(out, destination)), pin: descriptor};
}
const packaged = await read('psc1-modular-toolchain-package-' + head, 'package', 'package-input');
const receipt = JSON.parse(fs.readFileSync(path.join(packaged.root, 'package-receipt.json')));
assert.equal(receipt.testedCommit, head);
assert.equal(receipt.version, '0.1.0-psc1-modular.3');
assert.equal(receipt.corePackages, 20);
assert.equal(receipt.sourceUnits, 134);
assert.equal(receipt.compilerSourceClosureDigest, '1f2f1e4a035a32faa6035aeae000e9c92305f8fb34e58b8cc2210504e38213cb');
assert.equal(receipt.compilerSelfHosting.status, 'qualified-finite-linux-modular-js-ts');
assert.equal(receipt.referenceCompilerExecuted, false);
const readJson = (root, file) => JSON.parse(fs.readFileSync(path.join(root, file)));
const checks = {}, pins = {package: packaged.pin};
for (const runtime of ['node', 'bun']) {
  const smoke = readJson(packaged.root, 'smoke-' + runtime + '.json');
  assert.equal(smoke.status, 'passed'); assert.equal(smoke.tarballSha256, receipt.sha256);
  const qualified = await read('psc1-modular-installed-' + runtime + '-' + head,
    'qualify (' + runtime + ')', 'qualification-' + runtime);
  const q = readJson(qualified.root, 'qualification-' + runtime + '.json');
  const watch = readJson(qualified.root, 'watch-' + runtime + '.json');
  const resources = readJson(qualified.root, 'resources.json');
  assert.equal(q.status, 'passed'); assert.equal(q.testedCommit, head);
  assert.equal(q.sourceGraph, receipt.compilerSourceClosureDigest);
  assert.equal(q.records.length, 64); assert.equal(q.negatives.length, 10);
  assert.equal(q.globalRootOnlyCheckAndBuild, true);
  assert.equal(q.fullCompilerWasmAdmissionSha256, receipt.compilerAdmissionsSha256);
  assert.equal(watch.cases.length, 9); assert.equal(resources.rustResources, 61);
  assert.equal(resources.referenceCompilerExecuted, false);
  const boundaries = await read('psc1-modular-boundaries-' + runtime + '-' + head,
    'boundaries (' + runtime + ')', 'boundaries-' + runtime);
  const boundary = readJson(boundaries.root, 'boundaries-' + runtime + '.json');
  const io = readJson(boundaries.root, 'io-types-' + runtime + '.json');
  for (const result of [boundary, io]) {
    assert.equal(result.status, 'passed'); assert.equal(result.inputCommit, head);
    assert.equal(result.testedCommit, head);
  }
  assert.equal(boundary.cases.length, 23);
  assert.equal(io.records.length, 8); assert.equal(io.negatives.length, 4);
  assert.deepEqual(io.typeConsumers, ['NodeNext', 'Bundler']); assert.equal(io.tsWatch.builds, 2);
  const applications = await read('psc1-modular-installed-applications-' + runtime + '-' + head,
    'applications (' + runtime + ')', 'applications-' + runtime);
  const app = readJson(applications.root, 'installed-applications-' + runtime + '.json');
  assert.equal(app.status, 'passed'); assert.equal(app.inputCommit, head); assert.equal(app.testedCommit, head);
  assert.equal(app.records.length, 16); assert.equal(app.records.reduce((n, row) => n + row.cases.length, 0), 264);
  checks[runtime] = {smoke, qualification: q, watch, boundary, io, applications: app};
  pins[runtime] = {qualification: qualified.pin, boundaries: boundaries.pin, applications: applications.pin};
}
for (const major of [24, 26]) {
  const runtime = await read('psc1-modular-runtime-node' + major + '-' + head,
    'compatibility (' + major + ')', 'node-' + major);
  const smoke = readJson(runtime.root, 'smoke-node.json');
  assert.equal(smoke.status, 'passed'); assert.equal(smoke.tarballSha256, receipt.sha256);
  assert.ok(smoke.runtimeVersion.startsWith('v' + major + '.'));
  checks['node' + major] = {smoke}; pins['node' + major] = runtime.pin;
}
const targets = pin('psc1-modular-target-resources-' + head, 'package');
const installable = path.join(out, 'installable');
fs.mkdirSync(installable);
const tar = fs.readFileSync(path.join(packaged.root, 'tarballs', receipt.tarball));
assert.equal(tar.length, receipt.bytes); assert.equal(sha256(tar), receipt.sha256);
fs.writeFileSync(path.join(installable, receipt.tarball), tar);
for (const file of ['LICENSE', 'NOTICE']) fs.copyFileSync(file, path.join(installable, file));
const sourceQualification = fs.readFileSync('docs/PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json');
assert.equal(sha256(sourceQualification), receipt.compilerSelfHosting.receiptSha256);
fs.writeFileSync(path.join(installable, 'COMPILER_SELFHOST_QUALIFICATION.json'), sourceQualification);
fs.writeFileSync(path.join(installable, 'INSTALL.txt'), [
  'ProofScript ' + receipt.version + ' — qualified Linux modular compiler preview',
  'Verify SHA256SUMS. In this directory install ONLY the root tarball:',
  '  npm install --offline --ignore-scripts ./' + receipt.tarball,
  '  npx --no-install psc --help',
  '  npx --no-install psc init',
  '  npx --no-install psc check',
  '  npx --no-install psc build --out out --publication-protocol portable-file',
  '  npx --no-install psc build --out out --engine ts --watch',
  '',
  'Node >=22.23.3 or Bun >=1.4.4. Tested Node minimum/24/26 and Bun1.4.4 on Linux.',
  'The root bundles all20 core packages, JS/TS source-owned compiler engines, JS/TS/Rust/Wasm backends, and the genuine independent Lean4.35.0 C++/Emscripten linear-memory Wasm kernel.',
  'Core packages are under node_modules/proofscript/node_modules/@proofscript. Use proofscript/* subpaths; npm hoisting is not required.',
  'The thin psc command delegates to @proofscript/cli. No hidden whole-compiler module.js bundle.',
  'Both compiler graphs have genuine independently checked G1/G2/G3 and exact graph/npm fixed-point evidence in COMPILER_SELFHOST_QUALIFICATION.json.',
  'Installed host and application evidence is recorded separately in QUALIFICATION.json.',
  '',
  'Optional target SDKs and Python/PHP providers:',
  '  https://github.com/' + repository + '/actions/runs/' + runId + '/artifacts/' + targets.artifact,
  'Install the matching .tgz resources explicitly. TS validation and Rust/component outputs require their matching SDKs. Nothing downloads missing tools during compilation.',
  'Python/PHP are optional. Rust/Wasm output backends are core; older Rust/Wasm compiler executors still refuse this source cohort and remain preserved with.13.',
  'Standalone checked-host installation, other-platform consumers/durability, native binary reproduction, universal release and240-second self-compilation remain unqualified.',
  'The previous .13 reference and M4.1 preview are preserved. No merge or npm registry publication.',
].join('\n') + '\n');
const report = {schema: 'psc1-selfhosted-installed-delivery/1', status: 'qualified-finite-linux-installed-preview',
  testedCommit: head, run: runId, package: receipt, checks, pins, optionalTargets: targets,
  sourceGate: {run: sourceRun.id, testedCommit: source.testedCommit, branchHeadCommit: head, readiness},
  compilerQualification: receipt.compilerSelfHosting, noMerge: true, noRegistryPublication: true,
  notQualified: ['universal release', 'other platforms', 'standalone checked host', 'native binary reproduction',
    '240-second self-compilation performance', 'new Rust/Wasm executor source cohort', 'full M3 semantic-family matrix for this installed cohort']};
fs.writeFileSync(path.join(installable, 'QUALIFICATION.json'), JSON.stringify(report, null, 2) + '\n');
fs.writeFileSync(path.join(installable, 'SHA256SUMS'), fs.readdirSync(installable).sort().map(name =>
  sha256(fs.readFileSync(path.join(installable, name))) + '  ' + name).join('\n') + '\n');
const zip = path.join(out, 'proofscript-' + receipt.version + '-installable.zip');
const py = 'import pathlib,sys,zipfile\nroot=pathlib.Path(sys.argv[1])\n' +
  'with zipfile.ZipFile(sys.argv[2],"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:\n' +
  ' for p in sorted(root.iterdir()): z.write(p,p.name)\n' +
  'with zipfile.ZipFile(sys.argv[2]) as z:\n assert z.testzip() is None\n z.extractall(sys.argv[3])\n';
const extracted = path.join(out, 'fresh-zip');
const execute = (command, args, cwd) => {
  const result = spawnSync(command, args, {cwd, encoding: 'utf8', timeout: 240000, maxBuffer: 33554432});
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, result.stdout + result.stderr); return result.stdout;
};
execute('python3', ['-c', py, installable, zip, extracted]);
for (const line of fs.readFileSync(path.join(extracted, 'SHA256SUMS'), 'utf8').trim().split('\n')) {
  const [digest, name] = line.split('  ');
  assert.match(name, /^[A-Za-z0-9_.-]+$/);
  assert.equal(sha256(fs.readFileSync(path.join(extracted, name))), digest);
}
const consumer = path.join(out, 'fresh-consumer'); fs.mkdirSync(consumer);
fs.writeFileSync(path.join(consumer, 'package.json'), '{"private":true,"type":"module"}');
const npm = path.resolve(path.dirname(process.execPath), '../lib/node_modules/npm/bin/npm-cli.js');
execute(process.execPath, [npm, 'install', '--offline', '--ignore-scripts', '--no-audit', '--no-fund',
  '--registry', 'http://127.0.0.1:9', '--cache', path.join(consumer, 'empty-cache'), path.join(extracted, receipt.tarball)], consumer);
const cli = args => execute(process.execPath, [npm, 'exec', '--offline', '--', 'psc', ...args], consumer);
assert.ok(cli(['--help']).includes('psc check')); cli(['init']);
assert.equal(JSON.parse(cli(['check'])).logicalAdmission, 'accepted');
const build = JSON.parse(cli(['build', '--out', 'out', '--publication-protocol', 'portable-file']));
const artifact = build.runtimeArtifact || build.artifact;
assert.equal(execute(process.execPath, ['--input-type=module', '-e',
  'let m=await import(' + JSON.stringify(pathToFileURL(artifact).href) + ');if(m.default)m=m.default;console.log(String(m.answer));'], consumer).trim(), '42');
const bytes = fs.readFileSync(zip);
const final = {...report, checks: Object.fromEntries(Object.entries(checks).map(([runtime, value]) =>
  [runtime, {qualified: true, runtimeVersion: value.smoke?.runtimeVersion}])),
  freshExtractedZip: {checksums: true, rootOnlyOfflineInstall: true, npmExecHelpInitCheckBuild: true, answer: '42'},
  zip: path.basename(zip), zipBytes: bytes.length, zipSha256: sha256(bytes)};
fs.writeFileSync(path.join(out, 'delivery.json'), JSON.stringify(final, null, 2) + '\n');
console.log('PSC1_SELFHOSTED_NPM_DELIVERY ' + JSON.stringify(final));
