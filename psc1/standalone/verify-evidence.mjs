// Aggregate actual same-run isolated evidence; this does not run a compiler.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] || 'dist/independent-development/gate');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const leanCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const hashPattern = /^[a-f0-9]{64}$/;
const bootstrap = read(path.join(root, 'bootstrap/bootstrap.json'));
assert.equal(bootstrap.schema, 'psc1-independent-bootstrap/1');
assert.equal(bootstrap.sourceCommit, process.env.GITHUB_SHA);
const seedRecord = read(new URL('../docs/PSC1_TYPE_KEY_LATENCY_QUALIFICATION_2026-10-28.json', import.meta.url));
assert.equal(seedRecord.schema, 'psc1-type-key-qualification-record/1');
assert.equal(seedRecord.status, 'passed');
assert.equal(bootstrap.compilerSelection.strategy, 'qualified-type-key-O2');
assert.deepEqual(bootstrap.compilerSelection.input, seedRecord.artifact);
assert.equal(bootstrap.compilerSelection.compilerSha256, seedRecord.result.qualifiedCompiler.compilerSha256);
assert.equal(bootstrap.compilerSha256, seedRecord.result.qualifiedCompiler.compilerSha256);
assert.equal(bootstrap.compilerSelection.sourceClosureDigest, seedRecord.result.qualifiedCompiler.sourceClosureDigest);
assert.equal(bootstrap.sourceClosureDigest, seedRecord.result.qualifiedCompiler.sourceClosureDigest);
assert.equal(bootstrap.compilerSelection.filesManifestSha256, seedRecord.result.qualifiedCompiler.filesManifestSha256);
assert.equal(bootstrap.compilerSelection.selectedCanonicalSourceSha256, seedRecord.result.qualifiedCompiler.selectedCanonicalSourceSha256);
assert.equal(bootstrap.compilerSelection.receiptGrantsAdmissionAuthority, false);

assert.match(bootstrap.platform, /^linux-(x64|arm64)$/);
const expectedArch = bootstrap.platform.slice('linux-'.length);
assert.equal(bootstrap.tarball, 'psc1-independent-' + bootstrap.platform + '.tar.gz');
const environmentId = process.env.PSC1_QUALIFICATION_ENVIRONMENT;
const environments = {
  'ubuntu-24.04-x64': {platform:'linux-x64',osId:'ubuntu',versionId:'24.04'},
  'ubuntu-22.04-x64': {platform:'linux-x64',osId:'ubuntu',versionId:'22.04'},
  'ubuntu-24.04-arm64': {platform:'linux-arm64',osId:'ubuntu',versionId:'24.04'},
};
assert.ok(Object.hasOwn(environments,environmentId),'Explicit supported qualification environment required');
const expectedEnvironment=environments[environmentId];
assert.equal(bootstrap.platform,expectedEnvironment.platform);
const archive = fs.readFileSync(path.join(root, 'bootstrap', bootstrap.tarball));
assert.equal(archive.length, bootstrap.bytes);
assert.equal(sha(archive), bootstrap.sha256);

function one(rows, predicate, description) {
  const matches = rows.filter(predicate);
  assert.equal(matches.length, 1, 'exactly one ' + description + ' required');
  return matches[0];
}
function validateEnvironment(value) {
  assert.equal(value.schema, 'psc1-independent-environment/1');
  assert.equal(value.platform, 'linux');
  assert.equal(value.arch, expectedArch);
  const bounded = (text, maximum) => assert.ok(typeof text === 'string' && text.length <= maximum);
  bounded(value.kernel.release, 512);
  bounded(value.kernel.version, 1024);
  assert.equal(value.runtime.version, 'v22.23.3');
  assert.equal(value.runtime.versions.node, '22.23.3');
  assert.ok(Object.keys(value.runtime.versions).length > 0 && Object.keys(value.runtime.versions).length <= 64);
  for (const [name, version] of Object.entries(value.runtime.versions)) {
    assert.match(name, /^[A-Za-z0-9_-]{1,64}$/);
    bounded(version, 128);
  }
  for (const key of ['glibcVersionRuntime', 'glibcVersionCompiler']) {
    bounded(value.runtime[key], 128);
    assert.ok(value.runtime[key].length > 0);
  }
  bounded(value.osRelease.text, 16384);
  const release = Buffer.from(value.osRelease.text);
  assert.ok(release.length > 0 && release.length <= 16384);
  assert.equal(value.osRelease.bytes, release.length);
  assert.equal(value.osRelease.sha256, sha(release));
  const osFields={};
  for(const line of value.osRelease.text.split('\n')){
    const match=line.match(/^([A-Z][A-Z0-9_]*)=(.*)$/);
    if(!match)continue;
    assert.ok(!Object.hasOwn(osFields,match[1]),'Duplicate os-release field');
    let field=match[2];
    if(field.startsWith('"')&&field.endsWith('"'))field=field.slice(1,-1);
    else if(field.startsWith("'")&&field.endsWith("'"))field=field.slice(1,-1);
    osFields[match[1]]=field;
  }
  assert.equal(osFields.ID,expectedEnvironment.osId,'Actual operating system must match the environment label');
  assert.equal(osFields.VERSION_ID,expectedEnvironment.versionId,'Actual OS version must match the environment label');
  assert.deepEqual(Object.keys(value.filesystem).sort(), ['bavail', 'bfree', 'blocks', 'bsize', 'ffree', 'files', 'type']);
  for (const count of Object.values(value.filesystem)) assert.match(count, /^[0-9]{1,40}$/);
  for (const id of [value.user.uid, value.user.gid]) assert.ok(Number.isSafeInteger(id) && id >= 0);
}
validateEnvironment(bootstrap.environment);
const phases = {};
for (const phase of ['smoke', 'baseline', 'changed']) {
  const directory = path.join(root, phase);
  const isolation = read(path.join(directory, 'isolation.json'));
  const input = read(path.join(directory, 'isolation-input.json'));
  assert.equal(input.schema, 'psc1-independent-isolation-input/1');
  assert.equal(input.namespaceTool.path, '/usr/bin/unshare');
  assert.ok(Number.isSafeInteger(input.namespaceTool.bytes) &&
    input.namespaceTool.bytes > 0 && input.namespaceTool.bytes <= 10 * 1024 * 1024);
  assert.match(input.namespaceTool.sha256, hashPattern);
  assert.match(input.namespaceTool.version, /^unshare from util-linux [^\r\n]{1,128}$/);
  assert.equal(input.phase, phase);
  assert.equal(input.platform, bootstrap.platform);
  assert.equal(input.distributionSha256, bootstrap.toolchainSha256);
  const qualification = read(path.join(directory, phase, 'qualification.json'));
  assert.equal(isolation.schema, 'psc1-independent-isolation-result/1');
  assert.equal(isolation.status, 'passed');
  assert.equal(isolation.phase, phase);
  assert.equal(isolation.exitStatus, 0);
  assert.equal(isolation.processError, null);
  assert.equal(isolation.namespaceToolUnchanged, true);
  assert.deepEqual(isolation.unexpectedExecutions, []);
  const trace = fs.readFileSync(path.join(directory, 'execve.log'), 'utf8');
  assert.equal(sha(trace), isolation.traceSha256);
  assert.ok(!trace.includes('execveat('), 'unexpected execveat call');
  const executions = [...trace.matchAll(/execve\("([^"]+)"/g)].map(match => match[1]);
  assert.deepEqual(isolation.executions, executions);
  assert.ok(executions.length > 0);
  for (const executable of executions) assert.ok(
    ['/usr/bin/unshare', '/usr/sbin/chroot', '/bin/sh'].includes(executable) ||
    /^\/(?:toolchain|work\/[^\"]+)\/(?:libexec\/psc-runtime|kernel\/checker|bin\/psc)$/.test(executable),
    'unexpected executable: ' + executable);
  assert.deepEqual(isolation.qualification, qualification);
  assert.equal(qualification.schema, 'psc1-independent-development-qualification/1');
  assert.equal(qualification.status, 'passed');
  assert.equal(qualification.phase, phase);
  assert.equal(qualification.environment.externalToolchainsAbsent, true);
  assert.equal(qualification.environment.platform, 'linux');
  assert.equal(qualification.environment.arch, expectedArch);
  assert.equal(qualification.environment.runtimeVersion, 'v22.23.3');
  assert.equal(qualification.environment.runtimePath, '/toolchain/libexec/psc-runtime');
  validateEnvironment(input.environment);
  validateEnvironment(qualification.environment.details);
  const outside = input.environment, inside = qualification.environment.details;
  assert.deepEqual(inside.kernel, outside.kernel);
  assert.deepEqual(inside.osRelease, outside.osRelease);
  assert.equal(inside.runtime.glibcVersionRuntime, outside.runtime.glibcVersionRuntime);
  assert.equal(inside.filesystem.type, outside.filesystem.type);
  assert.equal(inside.filesystem.bsize, outside.filesystem.bsize);
  assert.deepEqual(inside.user, { uid: 65534, gid: 65534 });
  assert.equal(input.ordinaryUser, '65534:65534');
  assert.equal(qualification.distribution.manifestSha256, bootstrap.toolchainSha256);
  assert.equal(qualification.distribution.sourceCommit, bootstrap.sourceCommit);
  assert.equal(qualification.distribution.runtimeSha256, bootstrap.privateRuntimeSha256);
  assert.equal(qualification.distribution.checkerSha256, bootstrap.checkerSha256);
  assert.equal(qualification.distribution.leanCommit, leanCommit);
  assert.equal(qualification.authoritativeSource.moduleCount, bootstrap.sourceModules);
  assert.equal(qualification.authoritativeSource.sourceClosureDigest, bootstrap.sourceClosureDigest);
  assert.ok(Array.isArray(input.availableFiles) && input.availableFiles.length > 0);
  const installedPin = relative => one(input.availableFiles, row => row.path === relative, 'isolation file ' + relative);
  assert.equal(installedPin('toolchain/toolchain.json').sha256, bootstrap.toolchainSha256);
  assert.equal(installedPin('toolchain/libexec/psc-runtime').sha256, bootstrap.privateRuntimeSha256);
  assert.equal(installedPin('toolchain/kernel/checker').sha256, bootstrap.checkerSha256);
  assert.equal(installedPin('etc/os-release').sha256, outside.osRelease.sha256);
  assert.equal(installedPin('etc/os-release').bytes, outside.osRelease.bytes);
  assert.equal(installedPin('bin/sh').sha256, input.shell.sha256);
  assert.ok(Array.isArray(input.systemLibraries) && input.systemLibraries.length > 0);
  for (const library of input.systemLibraries) {
    assert.match(library.path, /^\/(?:lib\/|lib64\/|usr\/lib\/(?:x86_64|aarch64)-linux-gnu\/)/);
    assert.match(library.sha256, hashPattern);
    const pin = installedPin(library.path.slice(1));
    assert.equal(pin.bytes, library.bytes);
    assert.equal(pin.sha256, library.sha256);
  }
  const checks = executions.filter(file => file.endsWith('/kernel/checker')).length;
  assert.ok(checks >= ({ smoke: 4, baseline: 2, changed: 7 })[phase], 'actual checker process count: ' + phase);
  phases[phase] = { directory, isolation, input, qualification, checks };
}
function evidencePath(phase, absolute) {
  const prefix = '/work/' + phase + '/';
  assert.equal(typeof absolute, 'string');
  assert.ok(absolute.startsWith(prefix) && !absolute.includes('\\') && !absolute.includes('\0'));
  const relative = absolute.slice(prefix.length);
  assert.ok(relative && relative.split('/').every(part => part && part !== '.' && part !== '..'));
  const base = path.join(phases[phase].directory, phase);
  const resolved = path.resolve(base, relative);
  assert.ok(resolved.startsWith(base + path.sep));
  return resolved;
}
function verifiedProcess(phase, id) {
  assert.match(id, /^[0-9]{3,6}-[a-z][a-z0-9-]*$/);
  const events = phases[phase].qualification.events;
  const start = one(events, row => row.type === 'process-start' && row.id === id, 'process start ' + id);
  const complete = one(events, row => row.type === 'process-complete' && row.id === id, 'process completion ' + id);
  assert.equal(complete.executable, start.executable);
  assert.deepEqual(complete.args, start.args);
  assert.equal(complete.error, null);
  assert.equal(complete.signal, null);
  assert.ok(Number.isSafeInteger(complete.status));
  assert.ok(Number.isFinite(complete.elapsedMs) && complete.elapsedMs >= 0);
  const logRoot = path.join(phases[phase].directory, phase, 'logs');
  const stdout = fs.readFileSync(path.join(logRoot, id + '.stdout.txt'), 'utf8');
  const stderr = fs.readFileSync(path.join(logRoot, id + '.stderr.txt'), 'utf8');
  assert.equal(sha(stdout), complete.stdoutSha256);
  assert.equal(sha(stderr), complete.stderrSha256);
  return { ...complete, stdout, stderr };
}
const expectedFiles = ['compiler.mjs', 'admissions.json', 'original-ir.json', 'specialized-ir.json', 'sources.json'];
const publicationFiles = ['admissions.json', 'build.json', 'candidate.json', 'compiler.mjs',
  'original-ir.json', 'sources.json', 'specialized-ir.json'];
function checkedBuild(phase, label, options = {}) {
  const fullCompiler = options.fullCompiler !== false;
  const item = one(phases[phase].qualification.results, row =>
    row.type === 'independently-checked-build' && row.label === label, 'independently checked build ' + label);
  assert.equal(item.checker.executed, true);
  assert.equal(item.checker.accepted, true);
  assert.equal(item.checker.sha256, bootstrap.checkerSha256);
  assert.equal(item.checker.leanCommit, leanCommit);
  assert.equal(item.checker.admissionsSha256, item.identities.admissionsSha256);
  assert.match(item.checker.admissionReceiptSha256, hashPattern);
  assert.equal(item.execution.timeoutMs, fullCompiler ? 3600000 : 240000);
  if (fullCompiler) assert.deepEqual(item.publicNames, ['psCompilerServiceCandidate']);
  else assert.ok(item.publicNames.includes('answer'));
  assert.deepEqual(item.files.map(row => row.path), expectedFiles);
  const directory = evidencePath(phase, item.directory);
  for (const pin of item.files) {
    const bytes = fs.readFileSync(path.join(directory, pin.path));
    assert.equal(bytes.length, pin.bytes);
    assert.equal(sha(bytes), pin.sha256, label + ':' + pin.path);
  }
  const receiptBytes = fs.readFileSync(path.join(directory, 'build.json'));
  assert.equal(sha(receiptBytes), item.buildReceiptSha256);
  const receipt = JSON.parse(receiptBytes.toString('utf8'));
  assert.equal(receipt.schema, 'psc1-independent-build/1');
  assert.equal(receipt.target, 'js');
  assert.equal(receipt.grammar, 'ps');
  assert.equal(receipt.assurance, 'ordinary-checked');
  assert.equal(receipt.toolchainSha256, bootstrap.toolchainSha256);
  for (const key of ['identities', 'checker', 'execution', 'publicNames']) assert.deepEqual(receipt[key], item[key]);
  assert.equal(receipt.authority.actualIndependentAdmission, true);
  assert.equal(receipt.authority.sourceAndIrChecks, 'generated strict original and transformed IR validation');
  const sources = read(path.join(directory, 'sources.json'));
  assert.ok(Array.isArray(sources) && sources.length === receipt.sourceModules);
  const sourceClosureDigest = sha(JSON.stringify(sources.map(source => {
    assert.deepEqual(Object.keys(source).sort(), ['kind', 'module', 'text']);
    assert.equal(source.kind, 'ps');
    assert.equal(typeof source.text, 'string');
    return { module: source.module, kind: source.kind, utf8Sha256: sha(source.text) };
  })));
  assert.equal(sourceClosureDigest, item.identities.sourceClosureDigest);
  if (options.sourceText !== undefined) assert.deepEqual(sources, [{ module: 'Main', kind: 'ps', text: options.sourceText }]);
  for (const [identity, file] of Object.entries({
    sourceSha256: 'compiler.mjs', admissionsSha256: 'admissions.json',
    originalIrSha256: 'original-ir.json', specializedIrSha256: 'specialized-ir.json'
  })) assert.equal(item.identities[identity], sha(fs.readFileSync(path.join(directory, file))));
  const candidateBytes = fs.readFileSync(path.join(directory, 'candidate.json'));
  assert.equal(sha(candidateBytes), item.candidateSha256);
  const candidate = JSON.parse(candidateBytes.toString('utf8'));
  assert.equal(candidate.status, 'candidate');
  assert.equal(candidate.candidateOnly, true);
  assert.equal(candidate.admission, 'not-run');
  assert.equal(candidate.sourceClosureDigest, sourceClosureDigest);
  assert.equal(sha(candidate.source), item.identities.sourceSha256);
  assert.equal(sha(candidate.admissionRequest.admissions), item.identities.admissionsSha256);
  assert.equal(sha(JSON.stringify(candidate.originalIr)), item.identities.originalIrSha256);
  assert.equal(sha(JSON.stringify(candidate.specializedIr)), item.identities.specializedIrSha256);
  const completionBytes = fs.readFileSync(path.join(directory, 'files.json'));
  const completion = JSON.parse(completionBytes.toString('utf8'));
  assert.equal(completion.schema, 'psc1-independent-files/1');
  assert.deepEqual(completion.files.map(pin => pin.path), publicationFiles);
  for (const pin of completion.files) {
    const bytes = fs.readFileSync(path.join(directory, pin.path));
    assert.equal(bytes.length, pin.bytes);
    assert.equal(sha(bytes), pin.sha256);
  }
  const buildProcess = verifiedProcess(phase, item.processLog);
  assert.equal(buildProcess.status, 0);
  assert.equal(buildProcess.elapsedMs, item.processElapsedMs);
  assert.ok(buildProcess.executable === '/toolchain/bin/psc' ||
    buildProcess.executable === '/work/smoke/relocated toolchain with spaces/bin/psc');
  assert.equal(buildProcess.args[0], 'build');
  assert.equal(buildProcess.args[2], '--out');
  assert.equal(buildProcess.args[3], item.directory);
  assert.deepEqual(JSON.parse(buildProcess.stdout), { ...receipt, output: item.directory, checked: true });
  const projectFile = options.projectFile ?? (phase === 'baseline'
    ? '/toolchain/compiler/project.json' : '/work/changed/changed-compiler-source/project.json');
  const expectedArgs = ['build', projectFile, '--out', item.directory];
  if (options.compilerDirectory) expectedArgs.push('--compiler', options.compilerDirectory);
  if (fullCompiler) expectedArgs.push('--profile', 'correctness-3600s');
  assert.deepEqual(buildProcess.args, expectedArgs);
  assert.equal(buildProcess.executable, options.executable ?? '/toolchain/bin/psc');
  const expectedProducer = options.producerSha256 ?? bootstrap.compilerSha256;
  assert.equal(receipt.producer.sha256, expectedProducer);
  assert.equal(receipt.producer.provenance, options.compilerDirectory
    ? 'user-selected-built-compiler' : 'pinned-bootstrap');
  assert.equal(receipt.execution.protocol, 'psc1-independent-worker/1');
  assert.equal(receipt.execution.operation, 'compile');
  assert.equal(receipt.execution.compilerSha256, expectedProducer);
  assert.equal(receipt.execution.responseSha256, sha(candidateBytes));
  assert.equal(receipt.execution.responseUtf8Bytes, candidateBytes.length);
  const requestId = 'psc1-independent-' + sourceClosureDigest.slice(0, 24);
  const request = JSON.stringify(['psc1-unified-compiler-service/2', 'js',
    ['psc1-compiler-service/1', requestId, sourceClosureDigest, 'ps', 'ordinary-checked',
      receipt.entryModule, sources.map(source => [source.module, source.text])]]);
  assert.equal(receipt.execution.requestSha256, sha(request));
  assert.equal(receipt.api.protocol, 'psc1-independent-worker/1');
  assert.equal(receipt.api.operation, 'inspect');
  assert.equal(receipt.api.compilerSha256, item.identities.sourceSha256);
  assert.equal(receipt.api.timeoutMs, 240000);
  assert.deepEqual(receipt.api.publicNames, item.publicNames);
  assert.equal(receipt.profile, fullCompiler ? 'correctness-3600s' : 'ordinary-240s');
  return { ...item, artifactDirectory: directory, completionManifestSha256: sha(completionBytes) };
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
function checkApplicationObservation(phase, observation, build) {
  assert.deepEqual(observation.observation, { answer: '42' });
  const executed = verifiedProcess(phase, observation.processLog);
  assert.equal(executed.status, 0);
  assert.equal(executed.executable, '/toolchain/libexec/psc-runtime');
  assert.deepEqual(executed.args, ['--input-type=module', '--eval', applicationObservationProgram(build.directory)]);
  assert.deepEqual(JSON.parse(executed.stdout), observation.observation);
}

const original = phases.baseline.qualification.authoritativeSource;
assert.deepEqual(phases.changed.qualification.authoritativeSource, original);
assert.deepEqual(phases.smoke.qualification.authoritativeSource, original);
const B1 = checkedBuild('baseline', 'baseline-generation-one');
const B2 = checkedBuild('baseline', 'baseline-generation-two', {
  compilerDirectory: B1.directory, producerSha256: B1.identities.sourceSha256
});
const C1 = checkedBuild('changed', 'changed-generation-one');
const C2 = checkedBuild('changed', 'changed-generation-two', {
  compilerDirectory: C1.directory, producerSha256: C1.identities.sourceSha256
});
assert.deepEqual(B1.identities, B2.identities);
assert.deepEqual(B1.files, B2.files);
assert.deepEqual(C1.identities, C2.identities);
assert.deepEqual(C1.files, C2.files);
assert.equal(B1.identities.sourceClosureDigest, original.sourceClosureDigest);
assert.equal(B1.identities.admissionsSha256, bootstrap.sourceAdmissionsSha256);
const bootstrapAgreement = one(phases.baseline.qualification.results,
  row => row.type === 'bootstrap-admission-correspondence', 'bootstrap admission correspondence');
assert.equal(bootstrapAgreement.status, 'passed');
assert.equal(bootstrapAgreement.admissionsSha256, bootstrap.sourceAdmissionsSha256);
assert.notEqual(C1.identities.sourceClosureDigest, B1.identities.sourceClosureDigest);
assert.notEqual(C1.identities.sourceSha256, B1.identities.sourceSha256);
const changed = phases.changed.qualification;
assert.equal(C1.identities.sourceClosureDigest, changed.changedSource.sourceClosureDigest);
assert.equal(changed.changedSource.projectSha256, original.projectSha256);
assert.equal(changed.changedSource.files.length, original.files.length);
const beforeSources = read(path.join(B1.artifactDirectory, 'sources.json'));
const afterSources = read(path.join(C1.artifactDirectory, 'sources.json'));
assert.equal(beforeSources.length, original.files.length);
assert.equal(afterSources.length, changed.changedSource.files.length);
const differences = original.files.flatMap((file, index) => {
  const next = changed.changedSource.files[index], before = beforeSources[index], after = afterSources[index];
  assert.equal(next.module, file.module);
  assert.equal(next.path, file.path);
  assert.equal(before.module, file.module);
  assert.equal(after.module, next.module);
  assert.equal(sha(before.text), file.sha256);
  assert.equal(sha(after.text), next.sha256);
  assert.equal(Buffer.byteLength(before.text), file.bytes);
  assert.equal(Buffer.byteLength(after.text), next.bytes);
  return next.sha256 === file.sha256 ? [] : [{ before: file, after: next }];
});
const expectedEdits = {
  'Ps.CompilerUnified.Service': [
    { previous: '"request-arity"', replacement: '"request-arity:expected-three-fields"' }
  ],
  'Ps.Syntax.ParseProofScript': [
    { previous: 'psStringEq(keyword.text, "const")',
      replacement: 'psProofScriptBoolOr(psStringEq(keyword.text, "const"), psStringEq(keyword.text, "defconst"))' },
    { previous: 'psStringEq(text, "const")',
      replacement: 'psProofScriptBoolOr(psStringEq(text, "const"), psStringEq(text, "defconst"))' }
  ],
  'Ps.Compiler.Service': [
    { previous: '"parse", "source-refused"', replacement: '"parse", "parse-source-refused"' }
  ]
};
assert.deepEqual(differences.map(row => row.before.module).sort(), Object.keys(expectedEdits).sort());
const mutation = one(changed.results, row => row.type === 'real-compiler-source-modification', 'source modification');
assert.equal(mutation.changedFileCount, 3);
assert.equal(mutation.retainedModuleCount, original.moduleCount);
assert.equal(mutation.originalSourceClosureDigest, original.sourceClosureDigest);
assert.equal(mutation.changedSourceClosureDigest, C1.identities.sourceClosureDigest);
assert.equal(mutation.changes.length, 3);
for (const difference of differences) {
  const edit = one(mutation.changes, row => row.module === difference.before.module, 'source edit');
  assert.equal(edit.path, difference.before.path);
  assert.equal(edit.beforeSourceSha256, difference.before.sha256);
  assert.equal(edit.afterSourceSha256, difference.after.sha256);
  assert.deepEqual(edit.edits, expectedEdits[edit.module]);
  let expectedText = one(beforeSources, row => row.module === edit.module, 'captured original source').text;
  for (const replacement of edit.edits) {
    assert.equal(expectedText.split(replacement.previous).length - 1, 1);
    expectedText = expectedText.replace(replacement.previous, replacement.replacement);
  }
  assert.equal(one(afterSources, row => row.module === edit.module, 'captured changed source').text, expectedText);
}
const wireDifference = differences.find(row => row.before.module === 'Ps.CompilerUnified.Service');
assert.equal(mutation.beforeSourceSha256, wireDifference.before.sha256);
assert.equal(mutation.afterSourceSha256, wireDifference.after.sha256);
assert.equal(mutation.previous, 'request-arity');
assert.equal(mutation.replacement, 'request-arity:expected-three-fields');
for (const generation of ['C1', 'C2']) {
  const behavior = one(changed.results, row => row.type === 'changed-behavior' && row.generation === generation, 'changed wire behavior');
  assert.equal(behavior.actual.code, mutation.replacement);
  assert.equal(behavior.actual.status, 'refused');
  if (generation === 'C1') assert.equal(behavior.seed.code, mutation.previous);
}
for (const phase of ['baseline', 'changed']) {
  const fixed = one(phases[phase].qualification.results, row => row.type === 'fixed-point', 'fixed point');
  assert.equal(fixed.status, 'passed');
  assert.deepEqual(fixed.files, phase === 'baseline' ? B1.files : C1.files);
}
const fixtureSources = {
  'existing-const': 'const answer : Nat := 42\n',
  'new-declaration': 'function inc(value : Nat) : Nat := Nat.add(value, 1)\ndefconst answer : Nat := inc(41)\n',
  'existing-malformed': 'const broken : Nat :=\n',
  'new-missing-type': 'defconst broken := 42\n',
  'new-parameters-forbidden': 'defconst broken(value : Nat) : Nat := value\n',
  'new-illtyped': 'defconst broken : Nat := true\n'
};
const frontendRegressions = [];
assert.equal(changed.results.filter(row => row.type === 'frontend-compiler-regressions').length, 3);
for (const generation of ['seed', 'C1', 'C2']) {
  const row = one(changed.results, item => item.type === 'frontend-compiler-regressions' && item.generation === generation,
    'frontend/compiler regression generation');
  const aliasSupported = generation !== 'seed';
  assert.equal(row.aliasSupported, aliasSupported);
  assert.deepEqual(row.observations.map(item => item.case), Object.keys(fixtureSources));
  const selected = generation === 'C1' ? C1 : generation === 'C2' ? C2 : null;
  for (const observation of row.observations) {
    const label = generation.toLowerCase() + '-' + observation.case;
    assert.equal(observation.label, label);
    const sourceText = fixtureSources[observation.case];
    const projectFile = '/work/changed/regression-fixtures/' + label + '/project.json';
    const project = read(evidencePath('changed', projectFile));
    assert.deepEqual(project, { schemaVersion: 1, entryModule: 'Main', sources: [{ module: 'Main', path: 'Main.ps' }] });
    assert.equal(fs.readFileSync(evidencePath('changed', '/work/changed/regression-fixtures/' + label + '/Main.ps'), 'utf8'), sourceText);
    const sourceClosureDigest = sha(JSON.stringify([{ module: 'Main', kind: 'ps', utf8Sha256: sha(sourceText) }]));
    assert.equal(observation.sourceClosureDigest, sourceClosureDigest);
    const accepted = observation.case === 'existing-const' || (aliasSupported && observation.case === 'new-declaration');
    if (accepted) {
      assert.equal(observation.outcome, 'accepted-and-executed');
      assert.equal(observation.buildLabel, label);
      const built = checkedBuild('changed', label, {
        fullCompiler: false, sourceText, projectFile,
        compilerDirectory: selected?.directory, producerSha256: selected?.identities.sourceSha256
      });
      assert.equal(observation.buildReceiptSha256, built.buildReceiptSha256);
      assert.equal(observation.sourceClosureDigest, built.identities.sourceClosureDigest);
      assert.equal(observation.admissionsSha256, built.identities.admissionsSha256);
      assert.equal(observation.compilerSha256, built.identities.sourceSha256);
      assert.deepEqual(observation.checker, built.checker);
      checkApplicationObservation('changed', observation, built);
    } else {
      assert.equal(observation.outcome, 'refused');
      const execution = verifiedProcess('changed', observation.processLog);
      assert.notEqual(execution.status, 0);
      assert.equal(execution.executable, '/toolchain/bin/psc');
      const outputDirectory = '/work/changed/regression-builds/' + label;
      const expectedArgs = ['build', projectFile, '--out', outputDirectory];
      if (selected) expectedArgs.push('--compiler', selected.directory);
      assert.deepEqual(execution.args, expectedArgs);
      const marker = 'PSC1_INDEPENDENT_COMPILER_REFUSED:', offset = execution.stderr.indexOf(marker);
      assert.ok(offset >= 0);
      const actual = JSON.parse(execution.stderr.slice(offset + marker.length).split('\n')[0]);
      assert.deepEqual(actual, observation.response);
      const expectedPhase = aliasSupported && observation.case === 'new-illtyped' ? 'elaboration' : 'parse';
      const expectedCode = expectedPhase === 'parse' && aliasSupported ? 'parse-source-refused' : 'source-refused';
      for (const [key, value] of Object.entries({
        status: 'refused', phase: expectedPhase, code: expectedCode,
        target: 'js', module: 'Main', admission: 'not-run', candidateOnly: true,
        sourceClosureDigest, requestId: 'psc1-independent-' + sourceClosureDigest.slice(0, 24)
      })) assert.equal(actual[key], value);
      const refusedDirectory = evidencePath('changed', outputDirectory);
      assert.equal(fs.existsSync(path.join(refusedDirectory, 'build.json')), false);
      assert.equal(fs.existsSync(path.join(refusedDirectory, 'files.json')), false);
    }
  }
  frontendRegressions.push(row);
}
const small = checkedBuild('smoke', 'small-checked-build', {
  fullCompiler: false, sourceText: fixtureSources['existing-const'], projectFile: '/work/smoke/smoke-source/project.json'
});
const relocated = checkedBuild('smoke', 'relocated-small-checked-build', {
  fullCompiler: false, sourceText: fixtureSources['existing-const'], projectFile: '/work/smoke/smoke-source/project.json',
  executable: '/work/smoke/relocated toolchain with spaces/bin/psc'
});
const publication = one(phases.smoke.qualification.results, row => row.type === 'relocated-checked-publication',
  'relocated checked publication');
assert.equal(publication.status, 'passed');
assert.equal(publication.buildLabel, relocated.label);
assert.equal(publication.buildReceiptSha256, relocated.buildReceiptSha256);
assert.equal(publication.completionManifestSha256, relocated.completionManifestSha256);
assert.equal(relocated.directory, '/work/smoke/relocated checked output');
checkApplicationObservation('smoke', publication, relocated);
const readOnly = one(phases.smoke.qualification.results, row => row.type === 'publication-read-only-parent',
  'read-only-parent publication refusal');
assert.equal(readOnly.status, 'passed');
assert.equal(readOnly.acceptedBuildReceiptSha256, small.buildReceiptSha256);
assert.equal(readOnly.acceptedPayloadsSha256, sha(JSON.stringify(small.files)));
assert.equal(readOnly.output, '/work/smoke/read-only-output-parent/unpublished');
const permissionRefusal = verifiedProcess('smoke', readOnly.processLog);
assert.notEqual(permissionRefusal.status, 0);
assert.equal(permissionRefusal.executable, '/toolchain/bin/psc');
assert.deepEqual(permissionRefusal.args, ['build', '/work/smoke/smoke-source/project.json', '--out', readOnly.output]);
assert.match(permissionRefusal.stderr, /\b(?:EACCES|EPERM)\b/);
for (const file of ['build.json', 'files.json']) assert.equal(fs.existsSync(path.join(evidencePath('smoke', readOnly.output), file)), false);
const hostRefusals = one(phases.smoke.qualification.results, row => row.type === 'host-refusals', 'host refusals');
assert.equal(hostRefusals.status, 'passed');
assert.equal(hostRefusals.refusedOutputsUnpublished, true);
assert.ok(hostRefusals.cases.includes('read-only-parent'));
const summary = {
  schema: 'psc1-independent-development-evidence/2',
  status: 'qualified-linux-independent-compiler-development',
  testedCommit: process.env.GITHUB_SHA, runId: process.env.GITHUB_RUN_ID,
  platform: bootstrap.platform, environmentId,
  bootstrap, authoritativeSource: original, changedSource: changed.changedSource,
  sourceDifferences: differences, bootstrapAgreement,
  frontendCompilerRegressions: frontendRegressions,
  publication: { relocation: publication, readOnlyParent: readOnly, hostRefusals },
  generations: [B1, B2, C1, C2].map(row => ({
    label: row.label, identities: row.identities,
    compilerElapsedMs: row.execution.elapsedMs,
    compilerMaxRssKiB: row.execution.maxRssKiB,
    sampledPeakRssKiB: row.execution.peakRssKiB,
    checkerElapsedMs: row.checker.elapsedMs,
    completeProcessElapsedMs: row.processElapsedMs,
    checkerExecuted: row.checker.executed,
    buildReceiptSha256: row.buildReceiptSha256,
    completionManifestSha256: row.completionManifestSha256
  })),
  phases: Object.fromEntries(Object.entries(phases).map(([name, item]) => [name, {
    status: item.qualification.status, elapsedMs: item.qualification.elapsedMs,
    checkerExecutions: item.checks, traceSha256: item.isolation.traceSha256,
    environment: { outside: item.input.environment, inside: item.qualification.environment.details },
    systemLibraries: item.input.systemLibraries, shell: item.input.shell,
    namespaceTool: item.input.namespaceTool,
    qualificationSha256: sha(fs.readFileSync(path.join(item.directory, name, 'qualification.json')))
  }])),
  independence: {
    separateLeanLakeRequired: false, separateNodeBunRequired: false,
    separateTypeScriptRustCCppRequired: false, privateNodeRuntimeBundled: true,
    privateRuntimeVersion: '22.23.3', proofChecker: 'precompiled official Lean4.35.0 native kernel provider',
    bootstrapToolsStillRequiredToReassembleDistribution: true
  },
  assurances: {
    fullCurrentPsCompilerRebuild: true, modifiedCompilerRebuild: true,
    modifiedBehaviorObservedAfterSelfRebuild: true, sameSourceFixedPoints: true,
    changedSourceModules: 3, frontendCompilerObservationsPerGeneration: 6,
    independentLogicalAdmissionEveryBuild: true,
    relocatedCheckedPublication: true, readOnlyOutputParentRefused: true,
    formalCompilerPreservation: false, performance240sQualified: false,
    environmentsBeyondThisReceiptQualified: false
  }
};
fs.writeFileSync(path.join(root, 'summary.json'), json(summary));
const delivery = path.join(root, 'delivery');
fs.mkdirSync(delivery);
fs.copyFileSync(path.join(root, 'bootstrap', bootstrap.tarball), path.join(delivery, bootstrap.tarball));
fs.writeFileSync(path.join(delivery, 'summary.json'), json(summary));
fs.writeFileSync(path.join(delivery, 'SHA256SUMS'), bootstrap.sha256 + '  ' + bootstrap.tarball + '\n'
  + sha(Buffer.from(json(summary))) + '  summary.json\n');
console.log('PSC1_INDEPENDENT_DEVELOPMENT_EVIDENCE: ' + JSON.stringify(summary));
